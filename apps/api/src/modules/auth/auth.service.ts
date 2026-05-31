import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, JwtSignOptions } from '@nestjs/jwt';
import { User, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { UsersRepository } from '../users/users.repository';
import { AuthRepository } from './auth.repository';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly authRepository: AuthRepository,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto, context: RequestContext = {}) {
    const existing = await this.usersRepository.findByEmail(dto.email.toLowerCase());
    if (existing) {
      throw new ConflictException('Email is already registered');
    }

    const passwordHash = await argon2.hash(dto.password);
    const user = await this.usersRepository.create({
      email: dto.email.toLowerCase(),
      fullName: dto.fullName,
      passwordHash,
      profile: { create: {} },
      wallet: { create: { currency: 'INR' } },
      simulatorAccount: {
        create: {
          currency: 'INR',
          ledger: {
            create: {
              direction: 'CREDIT',
              amountMinor: 10_000_000,
              idempotencyKey: `simulator-initial-cash:${dto.email.toLowerCase()}`,
            },
          },
        },
      },
    });
    const emailVerification = await this.createEmailVerificationToken(user.id);
    const tokens = await this.createSessionAndIssueTokens(user, context);
    await this.audit(user.id, 'auth.registered', 'User', user.id);

    return {
      user: this.toAuthUser(user),
      tokens,
      emailVerification: {
        expiresAt: emailVerification.expiresAt,
        token: this.includeSensitiveDevToken(emailVerification.token),
      },
    };
  }

  async login(dto: LoginDto, context: RequestContext = {}) {
    const user = await this.usersRepository.findByEmail(dto.email.toLowerCase());
    if (!user || !(await argon2.verify(user.passwordHash, dto.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.status === UserStatus.SUSPENDED) {
      throw new ForbiddenException('Account is suspended');
    }

    const tokens = await this.createSessionAndIssueTokens(user, context);
    await this.audit(user.id, 'auth.login', 'AuthSession', tokens.sessionId);
    return {
      user: this.toAuthUser(user),
      tokens,
    };
  }

  async rotateRefreshToken(refreshToken: string) {
    const payload = await this.verifyRefreshPayload(refreshToken);
    const session = await this.authRepository.findSessionById(payload.sid);
    const user = await this.usersRepository.findById(payload.sub);
    const now = new Date();

    if (
      !session ||
      !user ||
      session.userId !== user.id ||
      session.revokedAt ||
      session.expiresAt <= now
    ) {
      throw new UnauthorizedException('Session is no longer valid');
    }
    if (!(await argon2.verify(session.refreshTokenHash, refreshToken))) {
      await this.authRepository.revokeSession(session.id);
      await this.audit(user.id, 'auth.refresh_reuse_detected', 'AuthSession', session.id);
      throw new UnauthorizedException('Session is no longer valid');
    }

    const tokens = await this.issueTokenPair(user.id, user.email, user.role, session.id);
    await this.authRepository.updateSessionRefreshHash(
      session.id,
      await argon2.hash(tokens.refreshToken),
      this.refreshExpiryDate(),
    );
    await this.audit(user.id, 'auth.refresh_rotated', 'AuthSession', session.id);
    return { tokens };
  }

  async logout(userId: string, sessionId: string | undefined, allSessions = false) {
    if (allSessions) {
      await this.authRepository.revokeUserSessions(userId);
      await this.audit(userId, 'auth.logout_all', 'User', userId);
      return { loggedOut: true };
    }
    if (!sessionId) {
      throw new UnauthorizedException('Session is no longer valid');
    }
    await this.authRepository.revokeSession(sessionId);
    await this.audit(userId, 'auth.logout', 'AuthSession', sessionId);
    return { loggedOut: true };
  }

  async verifyEmail(token: string) {
    const tokenHash = this.sha256(token);
    const record = await this.authRepository.findEmailVerificationTokenByHash(tokenHash);
    if (!record || record.consumedAt || record.expiresAt <= new Date()) {
      throw new UnauthorizedException('Email verification token is invalid or expired');
    }

    const user = await this.usersRepository.markEmailVerified(record.userId);
    await this.authRepository.consumeEmailVerificationToken(record.id);
    await this.audit(user.id, 'auth.email_verified', 'User', user.id);
    return { user: this.toAuthUser(user) };
  }

  async resendEmailVerification(userId: string) {
    const user = await this.usersRepository.findById(userId);
    if (!user) {
      throw new UnauthorizedException('Session is no longer valid');
    }
    if (user.emailVerifiedAt) {
      return { alreadyVerified: true };
    }
    const emailVerification = await this.createEmailVerificationToken(user.id);
    await this.audit(user.id, 'auth.email_verification_requested', 'User', user.id);
    return {
      alreadyVerified: false,
      expiresAt: emailVerification.expiresAt,
      token: this.includeSensitiveDevToken(emailVerification.token),
    };
  }

  async getMe(userId: string) {
    const user = await this.usersRepository.findById(userId);
    if (!user) {
      throw new UnauthorizedException('Session is no longer valid');
    }
    return { user: this.toAuthUser(user) };
  }

  async startDemoSession(context: RequestContext = {}) {
    if (this.config.get<string>('NODE_ENV') === 'production') {
      throw new ForbiddenException('Demo sessions are disabled in production');
    }

    const email = 'demo@musclemoney.app';
    let user = await this.usersRepository.findByEmail(email);
    if (!user) {
      user = await this.usersRepository.create({
        email,
        fullName: 'Demo Student',
        passwordHash: await argon2.hash(randomBytes(24).toString('hex')),
        emailVerifiedAt: new Date(),
        status: UserStatus.ACTIVE,
        profile: {
          create: {
            financialGoals: ['Build emergency fund', 'Learn investing'],
            riskProfile: 'BALANCED',
            knowledgeLevel: 'BEGINNER',
            monthlyIncomeMinor: 250_000,
            spendingHabits: { pattern: 'moderate' },
            learningPreferences: { pace: 'daily' },
            onboardingCompleted: true,
          },
        },
        wallet: { create: { currency: 'INR' } },
        simulatorAccount: {
          create: {
            currency: 'INR',
            ledger: {
              create: {
                direction: 'CREDIT',
                amountMinor: 10_000_000,
                idempotencyKey: 'simulator-initial-cash:demo@musclemoney.app',
              },
            },
          },
        },
      });
    }

    const tokens = await this.createSessionAndIssueTokens(user, context);
    await this.audit(user.id, 'auth.demo_session_started', 'User', user.id);
    return { user: this.toAuthUser(user), tokens };
  }

  private async createSessionAndIssueTokens(user: User, context: RequestContext): Promise<TokenPair> {
    const session = await this.authRepository.createSession({
      user: { connect: { id: user.id } },
      refreshTokenHash: await argon2.hash(randomBytes(32).toString('hex')),
      userAgent: context.userAgent,
      ipAddress: context.ipAddress,
      expiresAt: this.refreshExpiryDate(),
    });
    const tokens = await this.issueTokenPair(user.id, user.email, user.role, session.id);
    await this.authRepository.updateSessionRefreshHash(
      session.id,
      await argon2.hash(tokens.refreshToken),
      this.refreshExpiryDate(),
    );
    return tokens;
  }

  private async issueTokenPair(
    userId: string,
    email: string,
    role: string,
    sessionId: string,
  ): Promise<TokenPair> {
    const accessExpiresIn = this.config.getOrThrow<string>(
      'JWT_ACCESS_TTL',
    ) as JwtSignOptions['expiresIn'];
    const refreshExpiresIn = this.config.getOrThrow<string>(
      'JWT_REFRESH_TTL',
    ) as JwtSignOptions['expiresIn'];
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(
        { sub: userId, email, role, typ: 'access', sid: sessionId, jti: randomUUID() },
        {
          secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
          expiresIn: accessExpiresIn,
        },
      ),
      this.jwtService.signAsync(
        { sub: userId, email, role, typ: 'refresh', sid: sessionId, jti: randomUUID() },
        {
          secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
          expiresIn: refreshExpiresIn,
        },
      ),
    ]);
    return { accessToken, refreshToken, sessionId };
  }

  private async verifyRefreshPayload(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        email: string;
        role: string;
        typ: string;
        sid: string;
      }>(refreshToken, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
      if (payload.typ !== 'refresh' || !payload.sid) {
        throw new UnauthorizedException('Session is no longer valid');
      }
      return payload;
    } catch {
      throw new UnauthorizedException('Session is no longer valid');
    }
  }

  private async createEmailVerificationToken(userId: string) {
    const token = randomBytes(32).toString('base64url');
    const expiresAt = new Date(
      Date.now() + this.config.getOrThrow<number>('EMAIL_VERIFICATION_TTL_MINUTES') * 60_000,
    );
    await this.authRepository.createEmailVerificationToken({
      user: { connect: { id: userId } },
      tokenHash: this.sha256(token),
      expiresAt,
    });
    return { token, expiresAt };
  }

  private refreshExpiryDate() {
    return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  }

  private toAuthUser(user: User) {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      status: user.status,
      emailVerifiedAt: user.emailVerifiedAt,
    };
  }

  private includeSensitiveDevToken(token: string) {
    return this.config.get<string>('NODE_ENV') === 'production' ? undefined : token;
  }

  private sha256(value: string) {
    return createHash('sha256').update(value).digest('hex');
  }

  private async audit(userId: string, action: string, entityType: string, entityId: string) {
    await this.authRepository.writeAuditLog({
      user: { connect: { id: userId } },
      action,
      entityType,
      entityId,
    });
  }
}

type TokenPair = {
  accessToken: string;
  refreshToken: string;
  sessionId: string;
};

type RequestContext = {
  userAgent?: string;
  ipAddress?: string;
};
