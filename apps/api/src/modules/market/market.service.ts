import { Injectable, Inject } from '@nestjs/common';
import Redis from 'ioredis';
import { PrismaService } from '../../database/prisma.service';
import { CreateMarketAssetDto } from './dto/create-market-asset.dto';
import { CreateMarketSnapshotDto } from './dto/create-market-snapshot.dto';

@Injectable()
export class MarketService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject('REDIS_CLIENT') private readonly redis: Redis,
  ) {}

  async listAssets() {
    const assets = await this.prisma.marketAsset.findMany({
      orderBy: { symbol: 'asc' },
    });
    
    // For each asset, fetch the latest price which will trigger Yahoo Finance if needed
    for (const asset of assets) {
      await this.getLatestPrice(asset.symbol);
    }
    
    // Return with the freshly updated snapshots
    return this.prisma.marketAsset.findMany({
      orderBy: { symbol: 'asc' },
      include: {
        snapshots: {
          orderBy: { capturedAt: 'desc' },
          take: 1,
        },
      },
    });
  }

  upsertAsset(dto: CreateMarketAssetDto) {
    return this.prisma.marketAsset.upsert({
      where: { symbol: dto.symbol.toUpperCase() },
      create: {
        symbol: dto.symbol.toUpperCase(),
        name: dto.name,
        type: dto.type,
      },
      update: {
        name: dto.name,
        type: dto.type,
      },
    });
  }

  createSnapshot(dto: CreateMarketSnapshotDto) {
    return this.prisma.marketSnapshot.create({
      data: {
        marketAssetId: dto.assetId,
        priceMinor: dto.priceMinor,
        source: dto.source,
      },
    });
  }

  async getLatestPrice(symbol: string): Promise<number | null> {
    const cacheKey = `market:price:${symbol.toUpperCase()}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return parseInt(cached, 10);
    }
    
    // Attempt to fetch real data from Yahoo Finance
    try {
      // Use dynamic import since yahoo-finance2 is cjs/esm mixed sometimes or just require
      const yahooFinance = require('yahoo-finance2').default;
      const quote = await yahooFinance.quote(symbol.toUpperCase());
      if (quote && quote.regularMarketPrice) {
        // Convert to minor units (e.g. $150.50 -> 15050)
        const priceMinor = Math.round(quote.regularMarketPrice * 100);
        
        // Cache for 1 minute
        await this.redis.setex(cacheKey, 60, priceMinor.toString());
        
        // Find asset to attach snapshot to
        const asset = await this.prisma.marketAsset.findUnique({
          where: { symbol: symbol.toUpperCase() }
        });
        
        if (asset) {
          await this.prisma.marketSnapshot.create({
            data: {
              marketAssetId: asset.id,
              priceMinor,
              source: 'YAHOO_FINANCE'
            }
          });
        }
        
        return priceMinor;
      }
    } catch (e) {
      console.error(`Failed to fetch Yahoo Finance price for ${symbol}`, e);
    }

    // Fallback to DB
    const asset = await this.prisma.marketAsset.findUnique({
      where: { symbol: symbol.toUpperCase() },
      include: { snapshots: { orderBy: { capturedAt: 'desc' }, take: 1 } },
    });
    const price = asset?.snapshots[0]?.priceMinor;
    if (price) {
      await this.redis.setex(cacheKey, 60, price.toString());
      return price;
    }
    return null;
  }
}
