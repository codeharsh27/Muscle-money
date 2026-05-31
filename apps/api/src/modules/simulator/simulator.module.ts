import { Module } from '@nestjs/common';
import { SimulatorController } from './simulator.controller';
import { SimulatorService } from './simulator.service';
import { LeagueService } from './services/league.service';
import { AiCoachService } from './services/ai-coach.service';

@Module({
  controllers: [SimulatorController],
  providers: [SimulatorService, LeagueService, AiCoachService],
})
export class SimulatorModule {}
