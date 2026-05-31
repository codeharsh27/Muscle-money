import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class GamificationService {
  constructor(private readonly prisma: PrismaService) {}

  async awardLearningActivity(userId: string, xpAwarded: number) {
    const existingStreak = await this.prisma.streak.findUnique({ where: { userId } });
    const now = new Date();
    
    if (!existingStreak) {
      await this.prisma.streak.create({
        data: {
          userId,
          currentCount: 1,
          longestCount: 1,
          lastActivityAt: now,
        },
      });
    } else if (!existingStreak.lastActivityAt) {
      await this.prisma.streak.update({
        where: { userId },
        data: {
          currentCount: 1,
          longestCount: Math.max(existingStreak.longestCount, 1),
          lastActivityAt: now,
        },
      });
    } else {
      const lastActivity = existingStreak.lastActivityAt;
      const msPerDay = 1000 * 60 * 60 * 24;
      const diffDays = Math.floor(now.getTime() / msPerDay) - Math.floor(lastActivity.getTime() / msPerDay);
      
      if (diffDays == 1) {
        // Activity yesterday -> increment streak
        await this.prisma.streak.update({
          where: { userId },
          data: {
            currentCount: { increment: 1 },
            longestCount: Math.max(existingStreak.longestCount, existingStreak.currentCount + 1),
            lastActivityAt: now,
          },
        });
      } else if (diffDays > 1) {
        // Activity was older than yesterday -> reset streak
        await this.prisma.streak.update({
          where: { userId },
          data: {
            currentCount: 1,
            lastActivityAt: now,
          },
        });
      }
      // If diffDays == 0, already completed an activity today, so do nothing to the streak count
    }
    
    const finalStreak = await this.prisma.streak.findUnique({ where: { userId } });

    return {
      xpAwarded,
      streak: {
        currentCount: finalStreak!.currentCount,
        longestCount: finalStreak!.longestCount,
      },
    };
  }

  async getSummary(userId: string) {
    const [attempts, streak, badges] = await Promise.all([
      this.prisma.quizAttempt.findMany({ where: { userId } }),
      this.prisma.streak.findUnique({ where: { userId } }),
      this.prisma.userBadge.findMany({
        where: { userId },
        include: { badge: true },
        orderBy: { awardedAt: 'desc' },
      }),
    ]);

    const totalXp = attempts.reduce((total, attempt) => total + attempt.xpAwarded, 0);
    return {
      totalXp,
      level: Math.floor(totalXp / 250) + 1,
      streak: streak ?? { currentCount: 0, longestCount: 0, lastActivityAt: null },
      badges: badges.map((entry) => entry.badge),
    };
  }
}
