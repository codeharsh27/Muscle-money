import { Prisma, WalletTransactionType } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateWalletTransactionDto {
  @IsEnum(WalletTransactionType)
  type!: WalletTransactionType;

  @IsInt()
  @Min(1)
  amountMinor!: number;

  @IsString()
  idempotencyKey!: string;

  @IsString()
  description!: string;

  @IsOptional()
  metadata?: Prisma.InputJsonValue;
}
