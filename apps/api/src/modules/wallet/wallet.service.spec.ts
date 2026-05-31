import { ConflictException } from '@nestjs/common';
import { LedgerDirection, WalletTransactionType } from '@prisma/client';
import { WalletService } from './wallet.service';

describe(WalletService.name, () => {
  const prisma = {
    wallet: {
      findUnique: jest.fn(),
    },
    walletTransaction: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('derives wallet balance from ledger transactions', async () => {
    prisma.wallet.findUnique.mockResolvedValue({
      id: 'wallet-id',
      currency: 'INR',
      transactions: [
        { direction: LedgerDirection.CREDIT, amountMinor: 5000, createdAt: new Date() },
        { direction: LedgerDirection.DEBIT, amountMinor: 1200, createdAt: new Date() },
      ],
    });

    const service = new WalletService(prisma as never);
    const result = await service.getSummary('user-id');

    expect(result.balanceMinor).toBe(3800);
    expect(result.recentTransactions).toHaveLength(2);
  });

  it('rejects duplicate wallet idempotency keys', async () => {
    prisma.wallet.findUnique.mockResolvedValue({ id: 'wallet-id' });
    prisma.walletTransaction.findUnique.mockResolvedValue({ id: 'existing' });

    const service = new WalletService(prisma as never);

    await expect(
      service.createSavingsTransaction('user-id', {
        type: WalletTransactionType.MANUAL_SAVE,
        amountMinor: 1000,
        idempotencyKey: 'duplicate-key',
        description: 'Manual save',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
