import { IsIn, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CompleteActionDto {
  @IsString()
  actionKey!: string;

  @IsIn(['IRL_SAVE', 'SIMULATOR', 'BUDGET', 'DEBT_CHECK', 'PLAN'])
  actionType!: 'IRL_SAVE' | 'SIMULATOR' | 'BUDGET' | 'DEBT_CHECK' | 'PLAN';

  @IsOptional()
  @IsInt()
  @Min(1)
  amountMinor?: number;

  @IsOptional()
  @IsString()
  note?: string;
}
