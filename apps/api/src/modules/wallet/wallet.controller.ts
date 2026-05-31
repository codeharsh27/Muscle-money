import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CreateWalletTransactionDto } from './dto/create-wallet-transaction.dto';
import { WalletService } from './wallet.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'wallet', version: '1' })
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get()
  summary(@CurrentUser() user: AuthenticatedUser) {
    return this.walletService.getSummary(user.sub);
  }

  @Post('transactions')
  createTransaction(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateWalletTransactionDto) {
    return this.walletService.createSavingsTransaction(user.sub, dto);
  }
  @Post('external-savings')
  updateExternalSaving(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: { platform: string; amountMinor: number; isAddition: boolean },
  ) {
    return this.walletService.updateExternalSaving(user.sub, dto.platform, dto.amountMinor, dto.isAddition);
  }

  @Post('fixed-salary')
  updateFixedSalary(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: { incomeMinor: number },
  ) {
    return this.walletService.updateFixedSalary(user.sub, dto.incomeMinor);
  }
  @Post('spendings')
  addSpending(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: { amountMinor: number; merchant?: string; category?: string; platform: string; note?: string },
  ) {
    return this.walletService.addSpending(user.sub, dto);
  }
}
