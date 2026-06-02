import { ConflictException, Injectable, Logger, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { WalletTransactionType } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma.service';
import { GamificationService } from '../gamification/gamification.service';
import { WalletService } from '../wallet/wallet.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { CompleteActionDto } from './dto/complete-action.dto';
import { ChatCoachDto } from './dto/chat-coach.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';

@Injectable()
export class LearningService {
  private readonly logger = new Logger(LearningService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gamificationService: GamificationService,
    private readonly walletService: WalletService,
    @Inject(forwardRef(() => AnalyticsService))
    private readonly analyticsService: AnalyticsService,
    private readonly config: ConfigService,
  ) {}

  async listLessons(userId: string) {
    const [lessons, profile] = await Promise.all([
      this.prisma.lesson.findMany({
      orderBy: [{ difficulty: 'asc' }, { createdAt: 'asc' }],
      include: {
        progress: {
          where: { userId },
          select: { completionPercent: true, completedAt: true },
        },
        actionCompletions: {
          where: { userId },
          select: { actionKey: true, actionType: true, amountMinor: true, completedAt: true },
        },
      },
      }),
      this.prisma.profile.findUnique({ where: { userId } }),
    ]);

    const goals = new Set(profile?.financialGoals.map((goal) => goal.toLowerCase()) ?? []);
    const knowledgeLevel = profile?.knowledgeLevel ?? 'BEGINNER';

    return lessons
      .map((lesson) => ({
        ...lesson,
        recommendation: this.recommendationFor(lesson.content, goals, knowledgeLevel),
      }))
      .sort((a, b) => b.recommendation.score - a.recommendation.score);
  }

  async getLesson(slug: string, userId: string) {
    const lesson = await this.prisma.lesson.findUnique({
      where: { slug },
      include: {
        quizzes: true,
        progress: {
          where: { userId },
          select: { completionPercent: true, completedAt: true },
        },
        actionCompletions: {
          where: { userId },
          select: { actionKey: true, actionType: true, amountMinor: true, completedAt: true },
        },
      },
    });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }
    return lesson;
  }

  async submitQuiz(userId: string, quizId: string, dto: SubmitQuizDto) {
    const quiz = await this.prisma.quiz.findUnique({ where: { id: quizId }, include: { lesson: true } });
    if (!quiz) {
      throw new NotFoundException('Quiz not found');
    }

    const answerKey = this.normalizeAnswerKey(quiz.answerKey);
    const selected = [...dto.selected].sort();
    const isCorrect = JSON.stringify(selected) === JSON.stringify(answerKey);
    const xpAwarded = isCorrect ? this.xpForDifficulty(quiz.lesson.difficulty) : 0;

    const attempt = await this.prisma.quizAttempt.create({
      data: {
        userId,
        quizId,
        selected,
        isCorrect,
        xpAwarded,
      },
    });

    await this.prisma.learningProgress.upsert({
      where: { userId_lessonId: { userId, lessonId: quiz.lessonId } },
      create: {
        userId,
        lessonId: quiz.lessonId,
        completionPercent: isCorrect ? 100 : 25,
        completedAt: isCorrect ? new Date() : null,
      },
      update: {
        completionPercent: isCorrect ? 100 : 50,
        completedAt: isCorrect ? new Date() : undefined,
        lastInteractionAt: new Date(),
      },
    });

    const gamification = await this.gamificationService.awardLearningActivity(userId, xpAwarded);
    return { attempt, correctAnswer: answerKey, gamification };
  }

  async completeAction(userId: string, slug: string, dto: CompleteActionDto) {
    const lesson = await this.prisma.lesson.findUnique({ where: { slug } });
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    const existing = await this.prisma.learningActionCompletion.findUnique({
      where: { userId_lessonId_actionKey: { userId, lessonId: lesson.id, actionKey: dto.actionKey } },
    });
    if (existing) {
      throw new ConflictException('Learning action already completed');
    }

    let walletResult: { balanceMinor: number } | null = null;
    if (dto.actionType === 'IRL_SAVE' && dto.amountMinor) {
      walletResult = await this.walletService.createSavingsTransaction(userId, {
        type: WalletTransactionType.MANUAL_SAVE,
        amountMinor: dto.amountMinor,
        idempotencyKey: `learning-action:${userId}:${lesson.id}:${dto.actionKey}`,
        description: `Self-reported save from ${lesson.title}`,
        metadata: {
          source: 'LEARNING_ACTION',
          lessonSlug: slug,
          actionKey: dto.actionKey,
          safetyNote: 'User confirmed saving in their own trusted UPI or banking app.',
        },
      });
    }

    const completion = await this.prisma.learningActionCompletion.create({
      data: {
        userId,
        lessonId: lesson.id,
        actionKey: dto.actionKey,
        actionType: dto.actionType,
        amountMinor: dto.amountMinor,
        note: dto.note,
        metadata: {
          source: 'MONEY_MISSION',
          lessonSlug: slug,
        },
      },
    });

    const currentProgress = await this.prisma.learningProgress.findUnique({
      where: { userId_lessonId: { userId, lessonId: lesson.id } },
    });
    await this.prisma.learningProgress.upsert({
      where: { userId_lessonId: { userId, lessonId: lesson.id } },
      create: {
        userId,
        lessonId: lesson.id,
        completionPercent: 75,
      },
      update: {
        completionPercent: Math.min(100, (currentProgress?.completionPercent ?? 0) + 25),
        lastInteractionAt: new Date(),
      },
    });

    const gamification = await this.gamificationService.awardLearningActivity(userId, 15);
    return { completion, wallet: walletResult, gamification };
  }

  async chatCoach(userId: string, dto: ChatCoachDto) {
    const aiServiceUrl = this.config.getOrThrow<string>('AI_SERVICE_URL');

    // Enrich with user context for personalized responses
    const [profile, dashboard] = await Promise.all([
      this.prisma.profile.findUnique({ where: { userId }, include: { user: true } }),
      this.analyticsService.getDashboard(userId),
    ]);

    const name = profile?.user?.fullName || 'Champ';
    const knowledgeLevel = profile?.knowledgeLevel ?? 'BEGINNER';
    const firstGoal = profile?.financialGoals[0] ?? 'financial freedom';
    
    const recentTransactions = await this.prisma.spending.findMany({
      where: { userId },
      orderBy: { capturedAt: 'desc' },
      take: 5,
    });
    const txList = recentTransactions.map(tx => `${tx.merchant || tx.note || 'Unknown'} (₹${tx.amountMinor / 100})`).join(', ') || 'None';

    const contextStr = `[APP CONTEXT FOR NOVA:
- User Name: ${name}
- Knowledge Level: ${knowledgeLevel}
- Financial Goal: ${firstGoal}
- Real Wallet Monthly Savings: ₹${(dashboard.wallet.monthlySavingsMinor / 100).toFixed(2)}
- Real Wallet Monthly Spendings: ₹${((dashboard.wallet as any).monthlySpendingsMinor / 100).toFixed(2)}
- Recent Transactions: ${txList}
- Simulator Cash: ₹${(dashboard.simulator.cashMinor / 100).toFixed(2)}
- Simulator Holdings: ₹${(dashboard.simulator.holdingsValueMinor / 100).toFixed(2)}
- Learning Progress: Level ${dashboard.learning.level}, ${dashboard.learning.totalXp} XP, ${dashboard.learning.streakCount} day streak
- Action Progress: ${dashboard.learning.actionsCompleted} real-world missions completed
- Financial Score: ${dashboard.wallet.financialScore}/100
]`;

    // Prepend context to the user message so Nova knows who she's talking to
    const enrichedMessage = `${contextStr}\n\nUser Message: ${dto.message}`;

    try {
      const response = await fetch(`${aiServiceUrl}/api/v1/learning/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: enrichedMessage,
          history: dto.history,
        }),
        signal: AbortSignal.timeout(15_000), // 15s timeout
      });

      if (!response.ok) {
        this.logger.error(`AI service returned ${response.status}`);
        return { reply: "Nova is having a moment. Try again shortly! 🤖" };
      }

      const data = await response.json() as { reply: string };
      return { reply: data.reply };
    } catch (error: unknown) {
      this.logger.error(`AI service unreachable: ${error instanceof Error ? error.message : String(error)}`);
      return {
        reply: "Looks like Nova is taking a short break. Make sure the AI service is running and your Gemini API key is set in apps/ai-service/.env 🔧",
      };
    }
  }

  private normalizeAnswerKey(answerKey: unknown) {
    if (!Array.isArray(answerKey) || !answerKey.every((value) => typeof value === 'string')) {
      throw new NotFoundException('Quiz answer key is invalid');
    }
    return [...answerKey].sort();
  }

  private xpForDifficulty(difficulty: string) {
    const xp: Record<string, number> = {
      BEGINNER: 20,
      INTERMEDIATE: 35,
      ADVANCED: 50,
    };
    return xp[difficulty] ?? 10;
  }

  private recommendationFor(content: unknown, goals: Set<string>, knowledgeLevel: string) {
    const metadata = this.metadataFrom(content);
    const goalTags = metadata.goalTags;
    const difficulty = metadata.difficulty ?? 'BEGINNER';
    const matchesGoal = goalTags.some((tag) => goals.has(tag.toLowerCase()));
    const matchesLevel = difficulty === knowledgeLevel;

    return {
      score: (matchesGoal ? 10 : 0) + (matchesLevel ? 4 : 0) + (metadata.priority ?? 0),
      reason: matchesGoal
        ? `Matched to your ${goalTags[0]} goal`
        : matchesLevel
          ? `Good fit for your ${knowledgeLevel.toLowerCase()} level`
          : 'Useful for your finance foundation',
    };
  }

  private metadataFrom(content: unknown) {
    if (!content || typeof content !== 'object' || !('metadata' in content)) {
      return { goalTags: [] as string[], priority: 0, difficulty: undefined as string | undefined };
    }

    const metadata = (content as { metadata?: unknown }).metadata;
    if (!metadata || typeof metadata !== 'object') {
      return { goalTags: [] as string[], priority: 0, difficulty: undefined as string | undefined };
    }

    const typed = metadata as { goalTags?: unknown; priority?: unknown; difficulty?: unknown };
    return {
      goalTags: Array.isArray(typed.goalTags)
        ? typed.goalTags.filter((tag): tag is string => typeof tag === 'string')
        : [],
      priority: typeof typed.priority === 'number' ? typed.priority : 0,
      difficulty: typeof typed.difficulty === 'string' ? typed.difficulty : undefined,
    };
  }
}
