import { BadRequestException } from '@nestjs/common';
import { LedgerDirection, MarketAssetType, Prisma, SimulatorOrderSide } from '@prisma/client';
import { SimulatorService } from './simulator.service';

describe(SimulatorService.name, () => {
  const account = { id: 'account-id', userId: 'user-id', currency: 'INR' };
  const asset = {
    id: 'asset-id',
    symbol: 'MMY',
    name: 'Muscle Money Test Asset',
    type: MarketAssetType.STOCK,
    currency: 'INR',
    createdAt: new Date(),
    updatedAt: new Date(),
    snapshots: [{ id: 'snapshot-id', priceMinor: 10000, capturedAt: new Date() }],
  };

  const tx = {
    simulatorLedger: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
    simulatorOrder: {
      create: jest.fn(),
    },
    simulatorPosition: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      delete: jest.fn(),
    },
  };

  const prisma = {
    simulatorAccount: {
      findUnique: jest.fn(),
    },
    marketAsset: {
      findUnique: jest.fn(),
    },
    simulatorLedger: {
      findMany: jest.fn(),
    },
    simulatorPosition: {
      findMany: jest.fn(),
    },
    simulatorOrder: {
      findMany: jest.fn(),
    },
    $transaction: jest.fn((callback: (client: typeof tx) => unknown) => callback(tx)),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.simulatorAccount.findUnique.mockResolvedValue(account);
    prisma.marketAsset.findUnique.mockResolvedValue(asset);
    tx.simulatorOrder.create.mockResolvedValue({ id: 'order-id' });
    tx.simulatorLedger.create.mockResolvedValue({});
    tx.simulatorPosition.findUnique.mockResolvedValue(null);
    tx.simulatorPosition.upsert.mockResolvedValue({});
  });

  it('executes a buy order against the latest stored market snapshot', async () => {
    tx.simulatorLedger.findMany.mockResolvedValue([
      { direction: LedgerDirection.CREDIT, amountMinor: 1_000_000 },
    ]);

    const service = new SimulatorService(prisma as never);
    const result = await service.placeOrder('user-id', {
      assetId: 'asset-id',
      side: SimulatorOrderSide.BUY,
      quantity: 2,
    });

    expect(result.orderValueMinor).toBe(20_000);
    expect(tx.simulatorLedger.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          direction: LedgerDirection.DEBIT,
          amountMinor: 20_000,
        }),
      }),
    );
    expect(tx.simulatorPosition.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          quantity: new Prisma.Decimal(2),
          averagePriceMinor: 10_000,
        }),
      }),
    );
  });

  it('fails buy orders when simulator cash is insufficient', async () => {
    tx.simulatorLedger.findMany.mockResolvedValue([
      { direction: LedgerDirection.CREDIT, amountMinor: 500 },
    ]);

    const service = new SimulatorService(prisma as never);

    await expect(
      service.placeOrder('user-id', {
        assetId: 'asset-id',
        side: SimulatorOrderSide.BUY,
        quantity: 2,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
