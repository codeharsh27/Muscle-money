import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { CompleteOnboardingDto } from './dto/complete-onboarding.dto';

@Injectable()
export class OnboardingService {
  constructor(private readonly prisma: PrismaService) {}

  async getStatus(userId: string) {
    const profile = await this.prisma.profile.findUnique({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    return {
      completed: profile.onboardingCompleted,
      profile,
      missingFields: this.missingFields(profile),
    };
  }

  async complete(userId: string, dto: CompleteOnboardingDto) {
    const uniqueGoals = [...new Set(dto.financialGoals.map((goal) => goal.trim()).filter(Boolean))];
    if (uniqueGoals.length === 0) {
      throw new BadRequestException('At least one financial goal is required');
    }

    const profile = await this.prisma.profile.upsert({
      where: { userId },
      create: {
        userId,
        financialGoals: uniqueGoals,
        riskProfile: dto.riskProfile,
        knowledgeLevel: dto.knowledgeLevel,
        monthlyIncomeMinor: dto.monthlyIncomeMinor,
        spendingHabits: this.toJson(dto.spendingHabits),
        learningPreferences: this.toJson({
          ...dto.learningPreferences,
          primaryGoalNote: dto.primaryGoalNote,
        }),
        onboardingCompleted: true,
      },
      update: {
        financialGoals: uniqueGoals,
        riskProfile: dto.riskProfile,
        knowledgeLevel: dto.knowledgeLevel,
        monthlyIncomeMinor: dto.monthlyIncomeMinor,
        spendingHabits: this.toJson(dto.spendingHabits),
        learningPreferences: this.toJson({
          ...dto.learningPreferences,
          primaryGoalNote: dto.primaryGoalNote,
        }),
        onboardingCompleted: true,
      },
    });

    return {
      completed: true,
      profile,
      recommendedTrack: this.recommendedTrack(dto.knowledgeLevel, dto.riskProfile),
    };
  }

  private missingFields(profile: {
    financialGoals: string[];
    riskProfile: string | null;
    knowledgeLevel: string | null;
    monthlyIncomeMinor: number | null;
    spendingHabits: unknown;
    learningPreferences: unknown;
  }) {
    const missing: string[] = [];
    if (profile.financialGoals.length === 0) missing.push('financialGoals');
    if (!profile.riskProfile) missing.push('riskProfile');
    if (!profile.knowledgeLevel) missing.push('knowledgeLevel');
    if (profile.monthlyIncomeMinor === null) missing.push('monthlyIncomeMinor');
    if (!profile.spendingHabits) missing.push('spendingHabits');
    if (!profile.learningPreferences) missing.push('learningPreferences');
    return missing;
  }

  private recommendedTrack(knowledgeLevel: string, riskProfile: string) {
    if (knowledgeLevel === 'BEGINNER') {
      return 'money-foundations';
    }
    if (riskProfile === 'CONSERVATIVE') {
      return 'safe-investing-basics';
    }
    if (riskProfile === 'AGGRESSIVE') {
      return 'risk-and-return-lab';
    }
    return 'balanced-wealth-builder';
  }

  private toJson(value: Record<string, unknown>): Prisma.InputJsonValue {
    return value as Prisma.InputJsonObject;
  }
}
