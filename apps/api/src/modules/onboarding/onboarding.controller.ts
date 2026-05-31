import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CompleteOnboardingDto } from './dto/complete-onboarding.dto';
import { OnboardingService } from './onboarding.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'onboarding', version: '1' })
export class OnboardingController {
  constructor(private readonly onboardingService: OnboardingService) {}

  @Get('status')
  status(@CurrentUser() user: AuthenticatedUser) {
    return this.onboardingService.getStatus(user.sub);
  }

  @Put('complete')
  complete(@CurrentUser() user: AuthenticatedUser, @Body() dto: CompleteOnboardingDto) {
    return this.onboardingService.complete(user.sub, dto);
  }
}
