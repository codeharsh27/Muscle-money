import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { LedgerDirection, Prisma, SimulatorOrderSide, SimulatorOrderStatus } from '@prisma/client';
import { PrismaService } from '../../database/prisma.service';
import { sumLedger } from '../../common/utils/money';
import { PlaceSimulatorOrderDto } from './dto/place-simulator-order.dto';

@Injectable()
export class SimulatorService {
  constructor(private readonly prisma: PrismaService) {}

  async getPortfolio(userId: string) {
    const account = await this.findAccount(userId);
    const [ledger, positions, orders] = await Promise.all([
      this.prisma.simulatorLedger.findMany({ where: { simulatorAccountId: account.id } }),
      this.prisma.simulatorPosition.findMany({
        where: { simulatorAccountId: account.id },
        include: {
          marketAsset: {
            include: { snapshots: { orderBy: { capturedAt: 'desc' }, take: 1 } },
          },
        },
      }),
      this.prisma.simulatorOrder.findMany({
        where: { simulatorAccountId: account.id },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ]);

    const cashBalanceMinor = sumLedger(ledger);
    const holdingsValueMinor = positions.reduce((total, position) => {
      const latestPrice = position.marketAsset.snapshots[0]?.priceMinor ?? position.averagePriceMinor;
      return total + Math.round(Number(position.quantity) * latestPrice);
    }, 0);

    return {
      accountId: account.id,
      currency: account.currency,
      cashBalanceMinor,
      holdingsValueMinor,
      totalEquityMinor: cashBalanceMinor + holdingsValueMinor,
      positions,
      recentOrders: orders,
    };
  }

  async placeOrder(userId: string, dto: PlaceSimulatorOrderDto) {
    const account = await this.findAccount(userId);
    const asset = await this.prisma.marketAsset.findUnique({
      where: { id: dto.assetId },
      include: { snapshots: { orderBy: { capturedAt: 'desc' }, take: 1 } },
    });
    if (!asset) {
      throw new NotFoundException('Market asset not found');
    }
    const latestSnapshot = asset.snapshots[0];
    if (!latestSnapshot) {
      throw new BadRequestException('Cannot trade an asset without a market snapshot');
    }

    return this.prisma.$transaction(async (tx) => {
      const orderValueMinor = Math.round(dto.quantity * latestSnapshot.priceMinor);
      if (orderValueMinor <= 0) {
        throw new BadRequestException('Order value must be positive');
      }

      if (dto.side === SimulatorOrderSide.BUY) {
        await this.ensureSufficientCash(tx, account.id, orderValueMinor);
      } else {
        await this.ensureSufficientQuantity(tx, account.id, dto.assetId, dto.quantity);
      }

      const order = await tx.simulatorOrder.create({
        data: {
          simulatorAccountId: account.id,
          marketAssetId: dto.assetId,
          side: dto.side,
          quantity: new Prisma.Decimal(dto.quantity),
          requestedPriceMinor: latestSnapshot.priceMinor,
          executedPriceMinor: latestSnapshot.priceMinor,
          status: SimulatorOrderStatus.EXECUTED,
          executedAt: new Date(),
        },
      });

      await tx.simulatorLedger.create({
        data: {
          simulatorAccountId: account.id,
          direction: dto.side === SimulatorOrderSide.BUY ? LedgerDirection.DEBIT : LedgerDirection.CREDIT,
          amountMinor: orderValueMinor,
          orderId: order.id,
          idempotencyKey: `simulator-order:${order.id}`,
        },
      });

      await this.applyPosition(tx, account.id, dto.assetId, dto.side, dto.quantity, latestSnapshot.priceMinor);
      return { order, executedPriceMinor: latestSnapshot.priceMinor, orderValueMinor };
    });
  }

  private async findAccount(userId: string) {
    const account = await this.prisma.simulatorAccount.findUnique({ where: { userId } });
    if (!account) {
      throw new NotFoundException('Simulator account not found');
    }
    return account;
  }

  private async ensureSufficientCash(
    tx: Prisma.TransactionClient,
    simulatorAccountId: string,
    orderValueMinor: number,
  ) {
    const ledger = await tx.simulatorLedger.findMany({ where: { simulatorAccountId } });
    if (sumLedger(ledger) < orderValueMinor) {
      throw new BadRequestException('Insufficient simulator cash');
    }
  }

  private async ensureSufficientQuantity(
    tx: Prisma.TransactionClient,
    simulatorAccountId: string,
    marketAssetId: string,
    requestedQuantity: number,
  ) {
    const position = await tx.simulatorPosition.findUnique({
      where: { simulatorAccountId_marketAssetId: { simulatorAccountId, marketAssetId } },
    });
    if (!position || Number(position.quantity) < requestedQuantity) {
      throw new BadRequestException('Insufficient simulator holdings');
    }
  }

  private async applyPosition(
    tx: Prisma.TransactionClient,
    simulatorAccountId: string,
    marketAssetId: string,
    side: SimulatorOrderSide,
    quantity: number,
    priceMinor: number,
  ) {
    const existing = await tx.simulatorPosition.findUnique({
      where: { simulatorAccountId_marketAssetId: { simulatorAccountId, marketAssetId } },
    });
    const currentQuantity = existing ? Number(existing.quantity) : 0;
    const nextQuantity = side === SimulatorOrderSide.BUY ? currentQuantity + quantity : currentQuantity - quantity;

    if (nextQuantity <= 0) {
      if (existing) {
        await tx.simulatorPosition.delete({ where: { id: existing.id } });
      }
      return;
    }

    const averagePriceMinor =
      side === SimulatorOrderSide.BUY && existing
        ? Math.round(
            (currentQuantity * existing.averagePriceMinor + quantity * priceMinor) /
              (currentQuantity + quantity),
          )
        : existing?.averagePriceMinor ?? priceMinor;

    await tx.simulatorPosition.upsert({
      where: { simulatorAccountId_marketAssetId: { simulatorAccountId, marketAssetId } },
      create: {
        simulatorAccountId,
        marketAssetId,
        quantity: new Prisma.Decimal(nextQuantity),
        averagePriceMinor,
      },
      update: {
        quantity: new Prisma.Decimal(nextQuantity),
        averagePriceMinor,
      },
    });
  }

  async getScenarios() {
    return this.prisma.historicalScenario.findMany({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }
}
