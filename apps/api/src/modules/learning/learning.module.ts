import { Module, forwardRef } from '@nestjs/common';
import { GamificationModule } from '../gamification/gamification.module';
import { WalletModule } from '../wallet/wallet.module';
import { AnalyticsModule } from '../analytics/analytics.module';
import { AiModule } from '../ai/ai.module';
import { LearningController } from './learning.controller';
import { LearningService } from './learning.service';

@Module({
  imports: [GamificationModule, WalletModule, forwardRef(() => AnalyticsModule), AiModule],
  controllers: [LearningController],
  providers: [LearningService],
  exports: [LearningService],
})
export class LearningModule {}
