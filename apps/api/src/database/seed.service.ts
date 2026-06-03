import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { LessonDifficulty, MarketAssetType, QuizQuestionType } from '@prisma/client';

let prisma: PrismaService;

@Injectable()
export class SeedService implements OnModuleInit {
  private readonly logger = new Logger(SeedService.name);

  constructor(private readonly prismaService: PrismaService) {
    prisma = this.prismaService;
  }

  async onModuleInit() {
    try {
      const count = await prisma.lesson.count();
      if (count === 0) {
        this.logger.log('Database is empty. Running seed scripts...');
        await seedLessons();
        await seedMarketAssets();
        await seedHistoricalScenarios();
        this.logger.log('Seeding completed.');
      }
    } catch (error) {
      this.logger.error('Failed to run seed script on startup:', error);
    }
  }
}

async function seedLessons() {
  const modules = [
    {
      quizId: '11111111-0000-4000-8000-000000000001',
      slug: 'emergency-fund-basics',
      title: 'Emergency Fund Basics',
      summary: 'Build a money shield for medical costs, repairs, and income gaps.',
      difficulty: LessonDifficulty.BEGINNER,
      estimatedMinutes: 6,
      track: 'Foundations',
      icon: 'shield',
      goalTags: ['emergency fund', 'safety', 'saving'],
      priority: 5,
      tool: 'savings_calculator',
      sections: [
        {
          heading: 'Your first money shield',
          body: 'An emergency fund is money kept aside for urgent needs. It protects goals from one bad surprise.',
        },
        {
          heading: 'Start small',
          body: 'A student can begin with a one-month expense target, then slowly build toward three to six months.',
        },
        {
          heading: 'Keep it boring',
          body: 'Emergency money should be easy to access and low risk. It is not for chasing returns.',
        },
      ],
      question: 'What is the main purpose of an emergency fund?',
      options: [
        { id: 'A', text: 'To handle unexpected expenses without panic borrowing' },
        { id: 'B', text: 'To buy risky stocks quickly' },
        { id: 'C', text: 'To spend more every month' },
      ],
      answerKey: ['A'],
    },
    {
      quizId: '11111111-0000-4000-8000-000000000002',
      slug: 'risk-return-tradeoff',
      title: 'Risk and Return Tradeoff',
      summary: 'Understand why higher return expectations come with more uncertainty.',
      difficulty: LessonDifficulty.INTERMEDIATE,
      estimatedMinutes: 8,
      track: 'Investing',
      icon: 'chart',
      goalTags: ['investing', 'wealth', 'risk'],
      priority: 4,
      tool: 'risk_meter',
      sections: [
        {
          heading: 'The tradeoff',
          body: 'Higher expected return usually means a bumpier ride. That ride is called risk.',
        },
        {
          heading: 'Match the timeline',
          body: 'Short-term goals need stability. Long-term goals can usually handle more market movement.',
        },
        {
          heading: 'Know your sleep number',
          body: 'The best portfolio is not the loudest one. It is one you can hold when prices move.',
        },
      ],
      question: 'Which statement best describes risk-return tradeoff?',
      options: [
        { id: 'A', text: 'Higher expected returns often involve higher uncertainty' },
        { id: 'B', text: 'All investments have guaranteed returns' },
        { id: 'C', text: 'Risk can be ignored if an app looks modern' },
      ],
      answerKey: ['A'],
    },
    {
      quizId: '11111111-0000-4000-8000-000000000003',
      slug: 'compound-growth-lab',
      title: 'Compound Growth Lab',
      summary: 'See how small monthly savings can become serious future money.',
      difficulty: LessonDifficulty.BEGINNER,
      estimatedMinutes: 7,
      track: 'Foundations',
      icon: 'rocket',
      goalTags: ['saving', 'future', 'wealth'],
      priority: 6,
      tool: 'savings_calculator',
      sections: [
        {
          heading: 'Compounding rewards time',
          body: 'Compounding means your money can earn returns, and those returns can later earn returns too.',
        },
        {
          heading: 'The habit matters',
          body: 'Monthly saving often beats waiting for a perfect big amount. Consistency gives time something to work with.',
        },
        {
          heading: 'Try the calculator',
          body: 'Change the monthly saving and years below. Notice how time changes the final number.',
        },
      ],
      question: 'What makes compounding powerful?',
      options: [
        { id: 'A', text: 'Returns can start earning more returns over time' },
        { id: 'B', text: 'It guarantees every investment will go up daily' },
        { id: 'C', text: 'It only works if you start with a huge amount' },
      ],
      answerKey: ['A'],
    },
    {
      quizId: '11111111-0000-4000-8000-000000000004',
      slug: 'budget-with-purpose',
      title: 'Budget With Purpose',
      summary: 'Turn income into a plan for spending, saving, and future goals.',
      difficulty: LessonDifficulty.BEGINNER,
      estimatedMinutes: 5,
      track: 'Foundations',
      icon: 'wallet',
      goalTags: ['budgeting', 'saving', 'spending'],
      priority: 3,
      tool: 'budget_split',
      sections: [
        {
          heading: 'A budget is a decision map',
          body: 'It is not punishment. It helps your money follow your priorities before random spending takes over.',
        },
        {
          heading: 'Use buckets',
          body: 'Split money into needs, wants, saving, and learning. The exact ratio can change with your life.',
        },
      ],
      question: 'What is the best purpose of a budget?',
      options: [
        { id: 'A', text: 'To guide money toward priorities before it disappears' },
        { id: 'B', text: 'To stop all fun spending forever' },
        { id: 'C', text: 'To guess expenses without checking habits' },
      ],
      answerKey: ['A'],
    },
    {
      quizId: '11111111-0000-4000-8000-000000000005',
      slug: 'first-etf-simulator',
      title: 'First ETF Simulator',
      summary: 'Learn why diversified funds can be easier than picking one stock.',
      difficulty: LessonDifficulty.INTERMEDIATE,
      estimatedMinutes: 9,
      track: 'Investing',
      icon: 'pie',
      goalTags: ['investing', 'diversification', 'wealth'],
      priority: 4,
      tool: 'simulator_prompt',
      sections: [
        {
          heading: 'One basket, many companies',
          body: 'An ETF can hold many assets. That can reduce the impact of one company performing badly.',
        },
        {
          heading: 'Diversification is not magic',
          body: 'It lowers single-company risk, but market risk still exists. Prices can still move down.',
        },
      ],
      question: 'Why can ETFs be useful for beginners?',
      options: [
        { id: 'A', text: 'They can provide diversified exposure in one instrument' },
        { id: 'B', text: 'They remove every type of investment risk' },
        { id: 'C', text: 'They always beat every individual stock' },
      ],
      answerKey: ['A'],
    },
    {
      quizId: '11111111-0000-4000-8000-000000000006',
      slug: 'debt-danger-zone',
      title: 'Debt Danger Zone',
      summary: 'Spot high-interest debt before it quietly eats future income.',
      difficulty: LessonDifficulty.INTERMEDIATE,
      estimatedMinutes: 7,
      track: 'Money Defense',
      icon: 'warning',
      goalTags: ['debt', 'safety', 'budgeting'],
      priority: 3,
      tool: 'debt_check',
      sections: [
        {
          heading: 'Not all debt is equal',
          body: 'Low-cost education debt and high-interest consumer debt behave very differently.',
        },
        {
          heading: 'Interest works both ways',
          body: 'When you invest, compounding can help you. When you owe at high interest, compounding can work against you.',
        },
      ],
      question: 'Why is high-interest debt dangerous?',
      options: [
        { id: 'A', text: 'Interest can grow quickly and reduce future choices' },
        { id: 'B', text: 'It always improves credit automatically' },
        { id: 'C', text: 'It is harmless if the monthly payment looks small' },
      ],
      answerKey: ['A'],
    },
  ];

  for (const item of modules) {
    const lesson = await prisma.lesson.upsert({
      where: { slug: item.slug },
      create: {
        slug: item.slug,
        title: item.title,
        summary: item.summary,
        difficulty: item.difficulty,
        estimatedMinutes: item.estimatedMinutes,
        content: lessonContent(item),
      },
      update: {
        title: item.title,
        summary: item.summary,
        difficulty: item.difficulty,
        estimatedMinutes: item.estimatedMinutes,
        content: lessonContent(item),
      },
    });

    await prisma.quiz.upsert({
      where: { id: item.quizId },
      create: {
        id: item.quizId,
        lessonId: lesson.id,
        question: item.question,
        type: QuizQuestionType.SINGLE_CHOICE,
        options: item.options,
        answerKey: item.answerKey,
      },
      update: {
        lessonId: lesson.id,
        question: item.question,
        type: QuizQuestionType.SINGLE_CHOICE,
        options: item.options,
        answerKey: item.answerKey,
      },
    });
  }
}

function lessonContent(item: {
  track: string;
  slug: string;
  title: string;
  icon: string;
  goalTags: string[];
  priority: number;
  tool: string;
  difficulty: LessonDifficulty;
  sections: Array<{ heading: string; body: string }>;
}) {
  return {
    metadata: {
      track: item.track,
      icon: item.icon,
      goalTags: item.goalTags,
        priority: item.priority,
        difficulty: item.difficulty,
        tool: item.tool,
        missionName: missionNameFor(item.slug),
        mapZone: mapZoneFor(item.track),
        before: beforeMomentFor(item.tool),
        after: afterMomentFor(item.tool),
        futureSelf: futureSelfFor(item.tool),
        scenario: scenarioFor(item.tool),
        whatIf: whatIfFor(item.tool),
        action: actionFor(item),
      },
    sections: item.sections,
  };
}

function missionNameFor(slug: string) {
  const names: Record<string, string> = {
    'emergency-fund-basics': 'Build Your First Emergency Shield',
    'risk-return-tradeoff': 'Beat the Risk-Return Arena',
    'compound-growth-lab': 'Turn INR 100 Into a Future Habit',
    'budget-with-purpose': 'Design Your Money Control Room',
    'first-etf-simulator': 'Make Your First Virtual Investment',
    'debt-danger-zone': 'Escape the Debt Trap',
  };
  return names[slug] ?? 'Complete a Money Mission';
}

function mapZoneFor(track: string) {
  const zones: Record<string, string> = {
    Foundations: 'Money Basics Island',
    Investing: 'Investing Arena',
    'Money Defense': 'Debt Danger Zone',
  };
  return zones[track] ?? 'Future Freedom City';
}

function beforeMomentFor(tool: string) {
  const moments: Record<string, string> = {
    savings_calculator: 'I do not know how small savings become future money.',
    risk_meter: 'I think high returns are always better.',
    budget_split: 'I do not know where my money goes.',
    simulator_prompt: 'I am nervous about investing because every asset looks the same.',
    debt_check: 'I only look at the monthly payment, not the interest trap.',
  };
  return moments[tool] ?? 'Money decisions feel confusing.';
}

function afterMomentFor(tool: string) {
  const moments: Record<string, string> = {
    savings_calculator: 'I can estimate how today\'s saving habit changes future money.',
    risk_meter: 'I can match risk with my goal timeline.',
    budget_split: 'I can split income into needs, wants, and future.',
    simulator_prompt: 'I can practice before risking real money.',
    debt_check: 'I can spot high-interest debt before it eats future choices.',
  };
  return moments[tool] ?? 'I can take one clear money action.';
}

function futureSelfFor(tool: string) {
  const futures: Record<string, string> = {
    savings_calculator: 'Future You has more choices because you made saving automatic.',
    risk_meter: 'Future You sleeps better because risk matches the goal.',
    budget_split: 'Future You knows where every rupee is supposed to go.',
    simulator_prompt: 'Future You enters markets after practicing first.',
    debt_check: 'Future You keeps income instead of leaking it to interest.',
  };
  return futures[tool] ?? 'Future You benefits from one action today.';
}

function scenarioFor(tool: string) {
  const scenarios: Record<string, string> = {
    savings_calculator: 'You got INR 2,000 extra this month. What protects your future best?',
    risk_meter: 'Your goal is six months away, but a risky asset looks exciting. What matters most?',
    budget_split: 'Your allowance arrives today. Which split keeps freedom and future both alive?',
    simulator_prompt: 'You can buy one ETF-style asset or one single stock in the simulator. What will you compare?',
    debt_check: 'A buy-now-pay-later offer looks cheap monthly. What should you check first?',
  };
  return scenarios[tool] ?? 'Choose the action that protects Future You.';
}

function whatIfFor(tool: string) {
  const prompts: Record<string, string> = {
    savings_calculator: 'What if you save INR 100 daily for one year?',
    risk_meter: 'What if the market drops right before your deadline?',
    budget_split: 'What if you move 10% from wants to savings?',
    simulator_prompt: 'What if your ETF and stock move in opposite directions?',
    debt_check: 'What if interest grows faster than your savings?',
  };
  return prompts[tool] ?? 'What if one small action repeats for a year?';
}

function actionFor(item: { tool: string; slug: string; title: string }) {
  if (item.tool === 'savings_calculator') {
    return {
      key: `${item.slug}:irl-save`,
      type: 'IRL_SAVE',
      title: 'Save in your real UPI or bank app',
      description:
        'Open PhonePe, Google Pay, Paytm, or your trusted bank app separately. Move a small amount to savings, then return and mark it complete.',
      defaultAmountMinor: 10000,
      safetyNote: 'Muscle Money does not transfer money or open UPI. You confirm only after using your own trusted app.',
      buttonLabel: 'I saved money',
    };
  }
  if (item.tool === 'simulator_prompt') {
    return {
      key: `${item.slug}:simulator`,
      type: 'SIMULATOR',
      title: 'Practice before real investing',
      description: 'Open the simulator and compare one diversified asset with one individual stock.',
      defaultAmountMinor: null,
      safetyNote: 'This is virtual practice only, not investment advice.',
      buttonLabel: 'I did the simulator task',
    };
  }
  if (item.tool === 'debt_check') {
    return {
      key: `${item.slug}:debt-check`,
      type: 'DEBT_CHECK',
      title: 'Check one real debt or BNPL offer',
      description: 'Look for interest rate, fees, due date, and total amount payable before saying yes.',
      defaultAmountMinor: null,
      safetyNote: 'Do not share sensitive account details in Muscle Money.',
      buttonLabel: 'I checked it',
    };
  }
  return {
    key: `${item.slug}:plan`,
    type: 'PLAN',
    title: `Apply ${item.title}`,
    description: 'Write one small action you will take this week based on this mission.',
    defaultAmountMinor: null,
    safetyNote: 'This is a habit task, not financial advice.',
    buttonLabel: 'I made my plan',
  };
}

async function seedMarketAssets() {
  const assets = [
    {
      symbol: 'NIFTYBEES',
      name: 'Nippon India ETF Nifty 50 BeES',
      type: MarketAssetType.MUTUAL_FUND,
      priceMinor: 25000,
    },
    {
      symbol: 'DIGIGOLD',
      name: 'Digital Gold Simulator',
      type: MarketAssetType.DIGITAL_GOLD,
      priceMinor: 720000,
    },
    {
      symbol: 'TCS',
      name: 'Tata Consultancy Services Simulator',
      type: MarketAssetType.STOCK,
      priceMinor: 385000,
    },
  ];

  for (const asset of assets) {
    const saved = await prisma.marketAsset.upsert({
      where: { symbol: asset.symbol },
      create: {
        symbol: asset.symbol,
        name: asset.name,
        type: asset.type,
      },
      update: {
        name: asset.name,
        type: asset.type,
      },
    });

    const latest = await prisma.marketSnapshot.findFirst({
      where: { marketAssetId: saved.id, source: 'seed' },
      orderBy: { capturedAt: 'desc' },
    });

    if (!latest || latest.priceMinor !== asset.priceMinor) {
      await prisma.marketSnapshot.create({
        data: {
          marketAssetId: saved.id,
          priceMinor: asset.priceMinor,
          source: 'seed',
        },
      });
    }
  }
}

async function seedHistoricalScenarios() {
  const scenarios = [
    {
      title: '2020 COVID Crash',
      description: 'Experience the extreme volatility of early 2020. Will you panic sell or hold?',
      startDate: new Date('2020-02-15T00:00:00Z'),
      endDate: new Date('2020-05-15T00:00:00Z'),
      startBalance: 10000000, // 1 Lakh INR in minor units (100,000.00)
      assets: {
        NIFTYBEES: [
          { date: '2020-02-15', priceMinor: 1250000 },
          { date: '2020-03-01', priceMinor: 1100000 },
          { date: '2020-03-15', priceMinor: 950000 },
          { date: '2020-03-23', priceMinor: 750000 }, // The bottom
          { date: '2020-04-15', priceMinor: 900000 },
          { date: '2020-05-15', priceMinor: 920000 },
        ],
        DIGIGOLD: [
          { date: '2020-02-15', priceMinor: 400000 },
          { date: '2020-03-01', priceMinor: 410000 },
          { date: '2020-03-15', priceMinor: 430000 }, // Gold goes up during fear
          { date: '2020-03-23', priceMinor: 460000 },
          { date: '2020-04-15', priceMinor: 450000 },
          { date: '2020-05-15', priceMinor: 465000 },
        ]
      }
    },
    {
      title: '2008 Financial Crisis',
      description: 'The global market meltdown. Test your risk management.',
      startDate: new Date('2008-01-01T00:00:00Z'),
      endDate: new Date('2009-03-01T00:00:00Z'),
      startBalance: 10000000,
      assets: {
        NIFTYBEES: [
          { date: '2008-01-01', priceMinor: 600000 },
          { date: '2008-06-01', priceMinor: 400000 },
          { date: '2008-10-01', priceMinor: 300000 },
          { date: '2009-03-01', priceMinor: 250000 }, // The bottom
        ]
      }
    }
  ];

  for (const scenario of scenarios) {
    const existing = await prisma.historicalScenario.findFirst({
      where: { title: scenario.title },
    });

    if (!existing) {
      await prisma.historicalScenario.create({
        data: {
          title: scenario.title,
          description: scenario.description,
          startDate: scenario.startDate,
          endDate: scenario.endDate,
          startBalance: scenario.startBalance,
          assets: scenario.assets,
          isActive: true,
        },
      });
    } else {
      await prisma.historicalScenario.update({
        where: { id: existing.id },
        data: {
          description: scenario.description,
          startDate: scenario.startDate,
          endDate: scenario.endDate,
          startBalance: scenario.startBalance,
          assets: scenario.assets,
        },
      });
    }
  }
}


