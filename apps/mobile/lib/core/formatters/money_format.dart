String formatMinorMoney(int minor, {String currency = 'INR'}) {
  return '$currency ${(minor / 100).toStringAsFixed(2)}';
}
