import { Module } from '@nestjs/common';
import { MarketController } from './market.controller';
import { MarketService } from './market.service';
import { MarketIngestionService } from './market-ingestion.service';

@Module({
  controllers: [MarketController],
  providers: [MarketService, MarketIngestionService],
  exports: [MarketService],
})
export class MarketModule {}
