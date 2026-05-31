import { IsArray, IsString, ArrayMinSize } from 'class-validator';

export class SubmitQuizDto {
  @IsArray()
  @ArrayMinSize(1)
  @IsString({ each: true })
  selected!: string[];
}
