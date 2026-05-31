import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class AnalyticsService {
  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(userId: string) {
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [
      profile,
      externalSavings,
      simulatorAccount,
      quizAttempts,
      progress,
      streak,
      actionCompletions,
      savingsGoals,
      spendings,
    ] = await Promise.all([
      this.prisma.profile.findUnique({ where: { userId } }),
      this.prisma.externalSaving.findMany({
        where: { userId, month: { gte: firstDayOfMonth } },
      }),
      this.prisma.simulatorAccount.findUnique({
        where: { userId },
        include: {
          ledger: true,
          positions: {
            include: {
              marketAsset: {
                include: { snapshots: { orderBy: { capturedAt: 'desc' }, take: 1 } },
              },
            },
          },
        },
      }),
      this.prisma.quizAttempt.findMany({ where: { userId } }),
      this.prisma.learningProgress.findMany({ where: { userId } }),
      this.prisma.streak.findUnique({ where: { userId } }),
      this.prisma.learningActionCompletion.findMany({ where: { userId } }),
      this.prisma.savingsGoal.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } }),
      this.prisma.spending.findMany({
        where: { userId, capturedAt: { gte: firstDayOfMonth } },
        orderBy: { capturedAt: 'desc' },
      }),
    ]);

    // Calculate external savings and spendings
    const monthlySavingsMinor = externalSavings.reduce((sum, es) => sum + es.amountMinor, 0);
    const monthlySpendingsMinor = spendings.reduce((sum, s) => sum + s.amountMinor, 0);
    const monthlyIncomeMinor = profile?.monthlyIncomeMinor || 0;

    // Financial Score Calculation
    let score = 50; // Base score
    
    // Savings Ratio (up to 30 points)
    if (monthlyIncomeMinor > 0) {
      const ratio = monthlySavingsMinor / monthlyIncomeMinor;
      if (ratio >= 0.20) score += 30;
      else if (ratio >= 0.10) score += 20;
      else if (ratio > 0) score += 10;
    } else if (monthlySavingsMinor > 0) {
      score += 15; // Flat bonus if they saved something but no income set
    }

    // Investment Experience / Savings Habit (up to 20 points)
    if (profile?.investmentExperience === 'INTERMEDIATE' || profile?.investmentExperience === 'ADVANCED') score += 10;
    if (profile?.savingsHabit === 'REGULAR') score += 10;

    score = Math.min(100, Math.max(0, score));

    // Nova AI Insight
    let novaInsight = "Let's set your Fixed Salary so I can give you personalized savings advice.";
    if (monthlyIncomeMinor > 0) {
      if (score >= 80) {
        novaInsight = 'Incredible job! Your savings rate is excellent. Consider investing some of these savings in the Simulator.';
      } else if (score >= 60) {
        novaInsight = 'You are on the right track! Try pushing your savings to 20% of your salary for maximum growth.';
      } else {
        novaInsight = 'Your savings could use a boost. Try finding small expenses to cut this week and save them on PhonePe or Groww.';
      }
    }

    // Simulator metrics
    const simulatorCashMinor = simulatorAccount?.ledger.reduce((total, entry) => total + (entry.direction === 'CREDIT' ? entry.amountMinor : -entry.amountMinor), 0) ?? 0;
    const simulatorHoldingsMinor = simulatorAccount?.positions.reduce((total, position) => {
        const latestPrice = position.marketAsset.snapshots[0]?.priceMinor ?? position.averagePriceMinor;
        return total + Math.round(Number(position.quantity) * latestPrice);
    }, 0) ?? 0;

    const totalXp = quizAttempts.reduce((total, attempt) => total + attempt.xpAwarded, 0);
    const correctAttempts = quizAttempts.filter((attempt) => attempt.isCorrect).length;

    // Generate dynamic 7-point progress history
    const baseProgress = Math.min(100, (totalXp / 100) + (monthlySavingsMinor / 100000) + score);
    const progressHistory = [
      Math.max(0, baseProgress - 30),
      Math.max(0, baseProgress - 25),
      Math.max(0, baseProgress - 15),
      Math.max(0, baseProgress - 10),
      Math.max(0, baseProgress - 5),
      Math.max(0, baseProgress - 2),
      baseProgress,
    ].map(v => Math.round(v));

    return {
      wallet: {
        monthlySavingsMinor,
        financialScore: score,
        novaInsight,
        monthlyIncomeMinor: profile?.monthlyIncomeMinor || null,
        externalSavings: externalSavings.map(es => ({
          platform: es.platform,
          amountMinor: es.amountMinor,
        })),
        monthlySpendingsMinor,
        recentSpendings: spendings.slice(0, 5).map(s => ({
          amountMinor: s.amountMinor,
          merchant: s.merchant,
          category: s.category,
          platform: s.platform,
        })),
      },
      simulator: {
        cashMinor: simulatorCashMinor,
        holdingsValueMinor: simulatorHoldingsMinor,
        totalEquityMinor: simulatorCashMinor + simulatorHoldingsMinor,
        openPositions: simulatorAccount?.positions.length ?? 0,
      },
      learning: {
        totalXp,
        level: Math.floor(totalXp / 250) + 1,
        streakCount: streak?.currentCount ?? 0,
        lessonsStarted: progress.length,
        lessonsCompleted: progress.filter((item) => item.completedAt).length,
        quizAccuracyPercent: quizAttempts.length === 0 ? 0 : Math.round((correctAttempts / quizAttempts.length) * 100),
        actionsCompleted: actionCompletions.length,
        progressHistory,
      },
      goals: savingsGoals.map(g => ({
        id: g.id,
        title: g.title,
        targetAmountMinor: g.targetAmountMinor,
        currentAmountMinor: g.currentAmountMinor,
        isCompleted: g.isCompleted,
      })),
      smartAction: this.computeSmartAction(savingsGoals, monthlySavingsMinor, simulatorHoldingsMinor),
    };
  }

  private computeSmartAction(goals: any[], monthlySavingsMinor: number, investMinor: number) {
    const hasEmergencyFund = goals.some(g => g.title.toLowerCase().includes('emergency'));
    if (!hasEmergencyFund && monthlySavingsMinor < 500000) {
      return {
        title: 'Build Your Emergency Fund',
        description: 'Unexpected expenses can force you into debt.',
        actionText: 'Create Emergency Fund Goal',
        actionType: 'CREATE_GOAL',
      };
    }

    if (investMinor === 0) {
      return {
        title: 'Start Investing',
        description: 'Your money is sitting idle. Put it to work in the market.',
        actionText: 'Explore Simulator',
        actionType: 'NAV_SIMULATOR',
      };
    }

    return {
      title: 'Review Spending',
      description: 'Check your budget to see if you can save more this month.',
      actionText: 'Review Budget',
      actionType: 'REVIEW_BUDGET',
    };
  }
}
