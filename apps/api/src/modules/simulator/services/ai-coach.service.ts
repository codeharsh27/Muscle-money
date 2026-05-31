import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../database/prisma.service';

@Injectable()
export class AiCoachService {
  private readonly logger = new Logger(AiCoachService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generates feedback for a user's recent trades.
   * In a real implementation, this would call an LLM (e.g., via the ai-service)
   * with the user's trading history to get personalized advice.
   */
  async generateFeedback(userId: string, simulatorAccountId: string, scenarioId?: string) {
    this.logger.log(`Generating AI feedback for user ${userId}`);

    // Fetch recent orders
    const recentOrders = await this.prisma.simulatorOrder.findMany({
      where: { simulatorAccountId },
      orderBy: { createdAt: 'desc' },
      take: 5,
      include: { marketAsset: true },
    });

    if (recentOrders.length === 0) {
      return null; // No trades to analyze
    }

    // Example hardcoded AI logic for prototype
    let feedbackText = "Great job staying active! Remember that consistency is key.";
    
    // Check for panic selling (selling immediately after a drop)
    // This is pseudo-logic for the prototype.
    const sells = recentOrders.filter(o => o.side === 'SELL');
    if (sells.length > 2) {
      feedbackText = "I noticed multiple sells recently. Are you locking in profits, or panic selling during a dip? Stick to your long-term plan!";
    }

    const feedback = await this.prisma.aiCoachFeedback.create({
      data: {
        userId,
        simulatorAccountId,
        scenarioId,
        feedbackText,
        context: { orderCount: recentOrders.length },
      },
    });

    return feedback;
  }
}
