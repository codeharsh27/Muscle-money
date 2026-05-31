import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';
import { AuthRepository } from './auth.repository';
import { AuthService } from './auth.service';
import { UsersRepository } from '../users/users.repository';

const accessSecret = 'test-access-secret-with-more-than-32-characters';
const refreshSecret = 'test-refresh-secret-with-more-than-32-characters';

describe(AuthService.name, () => {
  let usersRepository: jest.Mocked<UsersRepository>;
  let authRepository: jest.Mocked<AuthRepository>;
  let service: AuthService;

  const baseUser = {
    id: '11111111-1111-1111-1111-111111111111',
    email: 'student@musclemoney.app',
    fullName: 'Student User',
    passwordHash: '',
    refreshTokenHash: null,
    emailVerifiedAt: null,
    role: UserRole.STUDENT,
    status: UserStatus.PENDING_EMAIL_VERIFICATION,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  };

  beforeEach(async () => {
    usersRepository = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
      updateRefreshTokenHash: jest.fn(),
      markEmailVerified: jest.fn(),
    } as unknown as jest.Mocked<UsersRepository>;

    authRepository = {
      createSession: jest.fn(),
      findSessionById: jest.fn(),
      updateSessionRefreshHash: jest.fn(),
      revokeSession: jest.fn(),
      revokeUserSessions: jest.fn(),
      createEmailVerificationToken: jest.fn(),
      findEmailVerificationTokenByHash: jest.fn(),
      consumeEmailVerificationToken: jest.fn(),
      writeAuditLog: jest.fn(),
    } as unknown as jest.Mocked<AuthRepository>;

    const config = {
      get: jest.fn((key: string) => (key === 'NODE_ENV' ? 'test' : undefined)),
      getOrThrow: jest.fn((key: string) => {
        const values: Record<string, string | number> = {
          JWT_ACCESS_SECRET: accessSecret,
          JWT_REFRESH_SECRET: refreshSecret,
          JWT_ACCESS_TTL: '15m',
          JWT_REFRESH_TTL: '30d',
          EMAIL_VERIFICATION_TTL_MINUTES: 60,
        };
        return values[key];
      }),
    };

    service = new AuthService(
      usersRepository,
      authRepository,
      new JwtService(),
      config as never,
    );
  });

  it('registers a user, creates a verification token, starts a session, and audits the event', async () => {
    usersRepository.findByEmail.mockResolvedValue(null);
    usersRepository.create.mockResolvedValue({ ...baseUser, passwordHash: await argon2.hash('Password123') });
    authRepository.createSession.mockResolvedValue({
      id: '22222222-2222-2222-2222-222222222222',
      userId: baseUser.id,
      refreshTokenHash: 'initial-hash',
      userAgent: 'jest',
      ipAddress: '127.0.0.1',
      revokedAt: null,
      expiresAt: new Date(Date.now() + 1000),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    authRepository.updateSessionRefreshHash.mockResolvedValue({} as never);
    authRepository.createEmailVerificationToken.mockResolvedValue({} as never);
    authRepository.writeAuditLog.mockResolvedValue({} as never);

    const result = await service.register(
      {
        email: 'Student@MuscleMoney.app',
        fullName: 'Student User',
        password: 'Password123',
      },
      { userAgent: 'jest', ipAddress: '127.0.0.1' },
    );

    expect(usersRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({ email: 'student@musclemoney.app' }),
    );
    expect(authRepository.createEmailVerificationToken).toHaveBeenCalledWith(
      expect.objectContaining({ user: { connect: { id: baseUser.id } } }),
    );
    expect(authRepository.updateSessionRefreshHash).toHaveBeenCalledWith(
      '22222222-2222-2222-2222-222222222222',
      expect.any(String),
      expect.any(Date),
    );
    expect(result.tokens.accessToken).toEqual(expect.any(String));
    expect(result.tokens.refreshToken).toEqual(expect.any(String));
    expect(result.emailVerification.token).toEqual(expect.any(String));
    expect(authRepository.writeAuditLog).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'auth.registered' }),
    );
  });

  it('rotates a valid refresh token and replaces the stored hash', async () => {
    const user = { ...baseUser, status: UserStatus.ACTIVE };
    const refreshToken = new JwtService().sign(
      { sub: user.id, email: user.email, role: user.role, typ: 'refresh', sid: 'session-id' },
      { secret: refreshSecret, expiresIn: '30d' },
    );
    const refreshHash = await argon2.hash(refreshToken);

    authRepository.findSessionById.mockResolvedValue({
      id: 'session-id',
      userId: user.id,
      refreshTokenHash: refreshHash,
      userAgent: null,
      ipAddress: null,
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    usersRepository.findById.mockResolvedValue(user);
    authRepository.updateSessionRefreshHash.mockResolvedValue({} as never);
    authRepository.writeAuditLog.mockResolvedValue({} as never);

    const result = await service.rotateRefreshToken(refreshToken);

    expect(result.tokens.refreshToken).not.toBe(refreshToken);
    expect(authRepository.updateSessionRefreshHash).toHaveBeenCalledWith(
      'session-id',
      expect.any(String),
      expect.any(Date),
    );
    expect(authRepository.writeAuditLog).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'auth.refresh_rotated' }),
    );
  });

  it('revokes a session when refresh token reuse is detected', async () => {
    const user = { ...baseUser, status: UserStatus.ACTIVE };
    const refreshToken = new JwtService().sign(
      { sub: user.id, email: user.email, role: user.role, typ: 'refresh', sid: 'session-id' },
      { secret: refreshSecret, expiresIn: '30d' },
    );

    authRepository.findSessionById.mockResolvedValue({
      id: 'session-id',
      userId: user.id,
      refreshTokenHash: await argon2.hash('different-token'),
      userAgent: null,
      ipAddress: null,
      revokedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    usersRepository.findById.mockResolvedValue(user);
    authRepository.revokeSession.mockResolvedValue({} as never);
    authRepository.writeAuditLog.mockResolvedValue({} as never);

    await expect(service.rotateRefreshToken(refreshToken)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(authRepository.revokeSession).toHaveBeenCalledWith('session-id');
    expect(authRepository.writeAuditLog).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'auth.refresh_reuse_detected' }),
    );
  });

  it('verifies email with a valid single-use token', async () => {
    const token = 'valid-email-token-with-more-than-32-characters';
    authRepository.findEmailVerificationTokenByHash.mockResolvedValue({
      id: 'token-id',
      userId: baseUser.id,
      tokenHash: 'hash',
      expiresAt: new Date(Date.now() + 60_000),
      consumedAt: null,
      createdAt: new Date(),
    });
    usersRepository.markEmailVerified.mockResolvedValue({
      ...baseUser,
      status: UserStatus.ACTIVE,
      emailVerifiedAt: new Date(),
    });
    authRepository.consumeEmailVerificationToken.mockResolvedValue({} as never);
    authRepository.writeAuditLog.mockResolvedValue({} as never);

    const result = await service.verifyEmail(token);

    expect(usersRepository.markEmailVerified).toHaveBeenCalledWith(baseUser.id);
    expect(authRepository.consumeEmailVerificationToken).toHaveBeenCalledWith('token-id');
    expect(result.user.status).toBe(UserStatus.ACTIVE);
  });
});
