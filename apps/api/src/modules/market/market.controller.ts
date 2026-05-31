import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateMarketAssetDto } from './dto/create-market-asset.dto';
import { CreateMarketSnapshotDto } from './dto/create-market-snapshot.dto';
import { MarketService } from './market.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'market', version: '1' })
export class MarketController {
  constructor(private readonly marketService: MarketService) {}

  @Get('assets')
  listAssets() {
    return this.marketService.listAssets();
  }

  @Post('assets')
  upsertAsset(@Body() dto: CreateMarketAssetDto) {
    return this.marketService.upsertAsset(dto);
  }

  @Post('snapshots')
  createSnapshot(@Body() dto: CreateMarketSnapshotDto) {
    return this.marketService.createSnapshot(dto);
  }
}
