import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { PlaceSimulatorOrderDto } from './dto/place-simulator-order.dto';
import { SimulatorService } from './simulator.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'simulator', version: '1' })
export class SimulatorController {
  constructor(private readonly simulatorService: SimulatorService) {}

  @Get('portfolio')
  portfolio(@CurrentUser() user: AuthenticatedUser) {
    return this.simulatorService.getPortfolio(user.sub);
  }

  @Post('orders')
  placeOrder(@CurrentUser() user: AuthenticatedUser, @Body() dto: PlaceSimulatorOrderDto) {
    return this.simulatorService.placeOrder(user.sub, dto);
  }

  @Get('scenarios')
  async getScenarios() {
    return this.simulatorService.getScenarios();
  }

  @Get('league')
  async getLeague() {
    return [
      { rank: 1, name: 'Alex M.', score: 98, isCurrentUser: false },
      { rank: 2, name: 'Sarah J.', score: 94, isCurrentUser: false },
      { rank: 3, name: 'You', score: 85, isCurrentUser: true },
      { rank: 4, name: 'Rahul D.', score: 72, isCurrentUser: false }
    ];
  }
}
