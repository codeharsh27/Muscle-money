import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../../database/prisma.service';

@Injectable()
export class LeagueService {
  private readonly logger = new Logger(LeagueService.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_WEEK)
  async calculateConsistencyScores() {
    this.logger.log('Starting weekly League Consistency Score calculation...');
    
    // In a real scenario, this would evaluate the Sharpe Ratio or a custom
    // risk-adjusted return metric. 
    // High returns with 100% in one asset = High Penalty.
    // Moderate returns with 3+ assets = High Score.
    
    try {
      const accounts = await this.prisma.simulatorAccount.findMany({
        include: { positions: true }
      });

      for (const account of accounts) {
        let score = 50; // Base score
        
        // Diversity bonus
        if (account.positions.length >= 3) {
          score += 20;
        } else if (account.positions.length === 1) {
          score -= 10;
        }

        // Ideally, we calculate PnL over the last 7 days and adjust for volatility.
        // For prototype, we randomly assign a score modifier.
        score += Math.floor(Math.random() * 30);
        
        // Save the score in redis or a new League table.
        // Example: await this.redis.zadd('league:global', score, account.userId);
        
        this.logger.debug(`Calculated score for user ${account.userId}: ${score}`);
      }

      this.logger.log('League Consistency Score calculation completed.');
    } catch (error: unknown) {
      this.logger.error('Failed to calculate League scores', error);
    }
  }
}
