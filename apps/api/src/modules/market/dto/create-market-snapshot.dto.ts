import { IsInt, IsString, Min } from 'class-validator';

export class CreateMarketSnapshotDto {
  @IsString()
  assetId!: string;

  @IsInt()
  @Min(1)
  priceMinor!: number;

  @IsString()
  source!: string;
}
