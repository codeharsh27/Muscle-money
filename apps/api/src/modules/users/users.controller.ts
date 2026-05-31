import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { UsersRepository } from './users.repository';
import { UpdateProfileDto } from './dto/update-profile.dto';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'users', version: '1' })
export class UsersController {
  constructor(private readonly usersRepository: UsersRepository) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: AuthenticatedUser) {
    const userData = await this.usersRepository.getUserProfile(user.sub);
    return userData;
  }

  @Put('profile')
  async updateProfile(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpdateProfileDto) {
    return this.usersRepository.updateProfile(user.sub, dto);
  }
}
