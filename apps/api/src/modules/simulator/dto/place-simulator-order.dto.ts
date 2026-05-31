import { SimulatorOrderSide } from '@prisma/client';
import { IsEnum, IsNumber, IsString, Min } from 'class-validator';

export class PlaceSimulatorOrderDto {
  @IsString()
  assetId!: string;

  @IsEnum(SimulatorOrderSide)
  side!: SimulatorOrderSide;

  @IsNumber()
  @Min(0.000001)
  quantity!: number;
}
