import { Injectable } from '@nestjs/common';
import { AuthSession, EmailVerificationToken, Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class AuthRepository {
  constructor(private readonly prisma: PrismaService) {}

  createSession(data: Prisma.AuthSessionCreateInput): Promise<AuthSession> {
    return this.prisma.authSession.create({ data });
  }

  findSessionById(id: string): Promise<AuthSession | null> {
    return this.prisma.authSession.findUnique({ where: { id } });
  }

  updateSessionRefreshHash(sessionId: string, refreshTokenHash: string, expiresAt: Date) {
    return this.prisma.authSession.update({
      where: { id: sessionId },
      data: { refreshTokenHash, expiresAt },
    });
  }

  revokeSession(sessionId: string): Promise<AuthSession> {
    return this.prisma.authSession.update({
      where: { id: sessionId },
      data: { revokedAt: new Date() },
    });
  }

  revokeUserSessions(userId: string): Promise<Prisma.BatchPayload> {
    return this.prisma.authSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  createEmailVerificationToken(
    data: Prisma.EmailVerificationTokenCreateInput,
  ): Promise<EmailVerificationToken> {
    return this.prisma.emailVerificationToken.create({ data });
  }

  findEmailVerificationTokenByHash(tokenHash: string): Promise<EmailVerificationToken | null> {
    return this.prisma.emailVerificationToken.findUnique({ where: { tokenHash } });
  }

  consumeEmailVerificationToken(tokenId: string): Promise<EmailVerificationToken> {
    return this.prisma.emailVerificationToken.update({
      where: { id: tokenId },
      data: { consumedAt: new Date() },
    });
  }

  writeAuditLog(data: Prisma.AuditLogCreateInput) {
    return this.prisma.auditLog.create({ data });
  }
}
