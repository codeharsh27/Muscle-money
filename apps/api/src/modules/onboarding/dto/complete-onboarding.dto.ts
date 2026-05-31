import { KnowledgeLevel, RiskProfile } from '@prisma/client';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class CompleteOnboardingDto {
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(5)
  @IsString({ each: true })
  financialGoals!: string[];

  @IsEnum(RiskProfile)
  riskProfile!: RiskProfile;

  @IsEnum(KnowledgeLevel)
  knowledgeLevel!: KnowledgeLevel;

  @IsInt()
  @Min(0)
  @Max(100_000_000)
  monthlyIncomeMinor!: number;

  @IsObject()
  spendingHabits!: Record<string, unknown>;

  @IsObject()
  learningPreferences!: Record<string, unknown>;

  @IsOptional()
  @IsString()
  primaryGoalNote?: string;
}
