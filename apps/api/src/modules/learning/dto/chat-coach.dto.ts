import { IsArray, IsBoolean, IsString, ValidateNested } from 'class-validator';

import { Type } from 'class-transformer';

export class ChatMessageDto {
  @IsString()
  text!: string;

  @IsBoolean()
  isCoach!: boolean;
}

export class ChatCoachDto {
  @IsString()
  message!: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChatMessageDto)
  history!: ChatMessageDto[];
}
