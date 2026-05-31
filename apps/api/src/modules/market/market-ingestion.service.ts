import { Injectable, Logger, Inject } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import yahooFinance from 'yahoo-finance2';
import Redis from 'ioredis';
import { PrismaService } from '../../database/prisma.service';

type MarketQuote = {
  regularMarketPrice?: number;
};

@Injectable()
export class MarketIngestionService {
  private readonly logger = new Logger(MarketIngestionService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async handleMarketIngestion() {
    this.logger.log('Starting scheduled market ingestion via Yahoo Finance...');
    
    try {
      const assets = await this.prisma.marketAsset.findMany();
      if (!assets.length) {
        this.logger.log('No assets found to ingest.');
        return;
      }

      for (const asset of assets) {
        try {
          // Add .NS suffix for Indian stocks if needed or handle symbol mapping
          // For now assuming the symbol in DB is compatible with Yahoo Finance (e.g. AAPL, TCS.NS)
          const quote = (await yahooFinance.quote(asset.symbol)) as MarketQuote | null;
          
          if (quote && typeof quote.regularMarketPrice === 'number') {
            // Store price in minor units (e.g., paise or cents)
            const priceMinor = Math.round(quote.regularMarketPrice * 100);
            
            await this.prisma.marketSnapshot.create({
              data: {
                marketAssetId: asset.id,
                priceMinor,
                source: 'YAHOO_FINANCE',
              },
            });
            await this.redis.set(`market:price:${asset.symbol}`, priceMinor.toString());
            this.logger.debug(`Ingested snapshot for ${asset.symbol}: ${priceMinor}`);
          }
        } catch (error: unknown) {
          this.logger.error(`Failed to ingest data for asset ${asset.symbol}: ${this.errorMessage(error)}`);
        }
      }
      this.logger.log('Market ingestion completed.');
    } catch (error: unknown) {
      this.logger.error(`Failed to run market ingestion job: ${this.errorMessage(error)}`);
    }
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
