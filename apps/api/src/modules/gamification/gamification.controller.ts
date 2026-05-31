import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GamificationService } from './gamification.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'gamification', version: '1' })
export class GamificationController {
  constructor(private readonly gamificationService: GamificationService) {}

  @Get('summary')
  summary(@CurrentUser() user: AuthenticatedUser) {
    return this.gamificationService.getSummary(user.sub);
  }
}
