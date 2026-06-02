import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { LedgerDirection } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { sumLedger } from '../../common/utils/money';
import { CreateWalletTransactionDto } from './dto/create-wallet-transaction.dto';

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(userId: string) {
    let wallet = await this.prisma.wallet.findUnique({
      where: { userId },
      include: { transactions: { orderBy: { createdAt: 'desc' } } },
    });
    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    // Seed dummy spendings if empty (for demo purposes)
    const spendingCount = await this.prisma.spending.count({ where: { userId } });
    if (spendingCount === 0) {
      const dummyTransactions = [
        { merchant: 'KFC', amount: 45000, desc: 'Dining' },
        { merchant: 'Amazon', amount: 125000, desc: 'Shopping' },
        { merchant: 'Uber', amount: 32000, desc: 'Transport' },
        { merchant: 'Starbucks', amount: 25000, desc: 'Coffee' },
      ];

      for (const [index, dummy] of dummyTransactions.entries()) {
        const date = new Date();
        date.setDate(date.getDate() - index - 1);

        await this.prisma.spending.create({
          data: {
            userId,
            amountMinor: dummy.amount,
            merchant: dummy.merchant,
            category: dummy.desc,
            platform: 'UPI',
            capturedAt: date,
          },
        });
      }
    }

    return {
      walletId: wallet.id,
      currency: wallet.currency,
      balanceMinor: sumLedger(wallet.transactions),
      recentTransactions: wallet.transactions.slice(0, 20),
    };
  }

  async createSavingsTransaction(userId: string, dto: CreateWalletTransactionDto) {
    const wallet = await this.prisma.wallet.findUnique({ where: { userId } });
    if (!wallet) {
      throw new NotFoundException('Wallet not found');
    }

    const existing = await this.prisma.walletTransaction.findUnique({
      where: { idempotencyKey: dto.idempotencyKey },
    });
    if (existing) {
      throw new ConflictException('Wallet transaction already exists for this idempotency key');
    }

    const transaction = await this.prisma.walletTransaction.create({
      data: {
        walletId: wallet.id,
        direction: LedgerDirection.CREDIT,
        type: dto.type,
        amountMinor: dto.amountMinor,
        idempotencyKey: dto.idempotencyKey,
        description: dto.description,
        metadata: dto.metadata,
      },
    });

    const summary = await this.getSummary(userId);
    return { transaction, balanceMinor: summary.balanceMinor };
  }

  async getSavingsGoals(userId: string) {
    return this.prisma.savingsGoal.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createSavingsGoal(userId: string, title: string, targetAmountMinor: number, targetDate?: Date) {
    return this.prisma.savingsGoal.create({
      data: {
        userId,
        title,
        targetAmountMinor,
        targetDate,
      },
    });
  }

  async contributeToGoal(userId: string, goalId: string, amountMinor: number) {
    const goal = await this.prisma.savingsGoal.findUnique({
      where: { id: goalId, userId },
    });
    if (!goal) throw new NotFoundException('Savings goal not found');

    const newAmount = goal.currentAmountMinor + amountMinor;
    const isCompleted = newAmount >= goal.targetAmountMinor;

    return this.prisma.savingsGoal.update({
      where: { id: goalId },
      data: {
        currentAmountMinor: newAmount,
        isCompleted,
      },
    });
  }
  async updateExternalSaving(userId: string, platform: string, amountMinor: number, isAddition: boolean) {
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const existing = await this.prisma.externalSaving.findUnique({
      where: { userId_platform_month: { userId, platform, month: firstDayOfMonth } },
    });

    if (existing) {
      return this.prisma.externalSaving.update({
        where: { id: existing.id },
        data: { amountMinor: isAddition ? existing.amountMinor + amountMinor : amountMinor },
      });
    } else {
      return this.prisma.externalSaving.create({
        data: {
          userId,
          platform,
          amountMinor,
          month: firstDayOfMonth,
        },
      });
    }
  }

  async updateFixedSalary(userId: string, incomeMinor: number) {
    return this.prisma.profile.upsert({
      where: { userId },
      update: { monthlyIncomeMinor: incomeMinor },
      create: { userId, monthlyIncomeMinor: incomeMinor },
    });
  }
  async addSpending(userId: string, dto: { amountMinor: number; merchant?: string; category?: string; platform: string; note?: string }) {
    return this.prisma.spending.create({
      data: {
        userId,
        amountMinor: dto.amountMinor,
        merchant: dto.merchant,
        category: dto.category,
        platform: dto.platform,
        note: dto.note,
      },
    });
  }
}
