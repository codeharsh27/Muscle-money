import { LedgerDirection } from '@prisma/client';

export function applyLedgerDirection(direction: LedgerDirection, amountMinor: number) {
  return direction === LedgerDirection.CREDIT ? amountMinor : -amountMinor;
}

export function sumLedger<T extends { direction: LedgerDirection; amountMinor: number }>(rows: T[]) {
  return rows.reduce((total, row) => total + applyLedgerDirection(row.direction, row.amountMinor), 0);
}
