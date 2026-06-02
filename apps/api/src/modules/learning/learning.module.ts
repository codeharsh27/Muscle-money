import { Module, forwardRef } from '@nestjs/common';
import { GamificationModule } from '../gamification/gamification.module';
import { WalletModule } from '../wallet/wallet.module';
import { AnalyticsModule } from '../analytics/analytics.module';
import { LearningController } from './learning.controller';
import { LearningService } from './learning.service';

@Module({
  imports: [GamificationModule, WalletModule, forwardRef(() => AnalyticsModule)],
  controllers: [LearningController],
  providers: [LearningService],
})
export class LearningModule {}
