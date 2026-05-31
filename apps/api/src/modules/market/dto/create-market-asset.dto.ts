import { MarketAssetType } from '@prisma/client';
import { IsEnum, IsString, Length } from 'class-validator';

export class CreateMarketAssetDto {
  @IsString()
  @Length(1, 16)
  symbol!: string;

  @IsString()
  @Length(2, 120)
  name!: string;

  @IsEnum(MarketAssetType)
  type!: MarketAssetType;
}
