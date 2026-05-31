import { Injectable } from '@nestjs/common';
import { Prisma, User, UserStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class UsersRepository {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  updateRefreshTokenHash(userId: string, refreshTokenHash: string | null): Promise<User> {
    return this.prisma.user.update({ where: { id: userId }, data: { refreshTokenHash } });
  }

  markEmailVerified(userId: string): Promise<User> {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        emailVerifiedAt: new Date(),
        status: UserStatus.ACTIVE,
      },
    });
  }

  async getUserProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });
    return user;
  }

  async updateProfile(userId: string, data: any) {
    const { fullName, ...profileData } = data;
    
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(fullName ? { fullName } : {}),
        profile: {
          update: {
            ...profileData
          }
        }
      },
      include: { profile: true }
    });
  }
}
