import { IsOptional, IsString, IsNumber, IsEnum, IsArray } from 'class-validator';
import { KnowledgeLevel } from '@prisma/client';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsEnum(KnowledgeLevel)
  knowledgeLevel?: KnowledgeLevel;

  @IsOptional()
  @IsNumber()
  monthlyIncomeMinor?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  financialGoals?: string[];
}
