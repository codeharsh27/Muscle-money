import { BadRequestException } from '@nestjs/common';
import { KnowledgeLevel, RiskProfile } from '@prisma/client';
import { OnboardingService } from './onboarding.service';

describe(OnboardingService.name, () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns missing onboarding fields for an incomplete profile', async () => {
    prisma.profile.findUnique.mockResolvedValue({
      financialGoals: [],
      riskProfile: null,
      knowledgeLevel: null,
      monthlyIncomeMinor: null,
      spendingHabits: null,
      learningPreferences: null,
      onboardingCompleted: false,
    });

    const service = new OnboardingService(prisma as never);
    const result = await service.getStatus('user-id');

    expect(result.completed).toBe(false);
    expect(result.missingFields).toEqual([
      'financialGoals',
      'riskProfile',
      'knowledgeLevel',
      'monthlyIncomeMinor',
      'spendingHabits',
      'learningPreferences',
    ]);
  });

  it('completes onboarding and deduplicates goals', async () => {
    prisma.profile.upsert.mockResolvedValue({
      userId: 'user-id',
      onboardingCompleted: true,
      financialGoals: ['Build emergency fund', 'Learn investing'],
    });

    const service = new OnboardingService(prisma as never);
    const result = await service.complete('user-id', {
      financialGoals: ['Build emergency fund', 'Build emergency fund', 'Learn investing'],
      riskProfile: RiskProfile.BALANCED,
      knowledgeLevel: KnowledgeLevel.BEGINNER,
      monthlyIncomeMinor: 250_000,
      spendingHabits: { dining: 'medium' },
      learningPreferences: { pace: 'daily' },
    });

    expect(result.completed).toBe(true);
    expect(result.recommendedTrack).toBe('money-foundations');
    expect(prisma.profile.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        update: expect.objectContaining({
          financialGoals: ['Build emergency fund', 'Learn investing'],
          onboardingCompleted: true,
        }),
      }),
    );
  });

  it('rejects empty financial goals after trimming', async () => {
    const service = new OnboardingService(prisma as never);

    await expect(
      service.complete('user-id', {
        financialGoals: ['   '],
        riskProfile: RiskProfile.CONSERVATIVE,
        knowledgeLevel: KnowledgeLevel.INTERMEDIATE,
        monthlyIncomeMinor: 100_000,
        spendingHabits: {},
        learningPreferences: {},
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
