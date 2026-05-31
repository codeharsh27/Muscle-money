import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  if (AppConfig.skipAuth) {
    return MockWalletRepository();
  }
  return WalletRepository(ref.watch(dioProvider));
});

class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  Future<WalletSummary> summary() async {
    final response = await _dio.get<Map<String, dynamic>>('/wallet');
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return WalletSummary.fromJson(data);
  }

  Future<void> addManualSave(int amountMinor) async {
    await _dio.post<Map<String, dynamic>>(
      '/wallet/transactions',
      data: {
        'type': 'MANUAL_SAVE',
        'amountMinor': amountMinor,
        'idempotencyKey': 'mobile-manual-save-${DateTime.now().microsecondsSinceEpoch}',
        'description': 'Manual mobile save',
      },
    );
  }

  Future<void> updateExternalSaving(String platform, int amountMinor, bool isAddition) async {
    await _dio.post(
      '/wallet/external-savings',
      data: {
        'platform': platform,
        'amountMinor': amountMinor,
        'isAddition': isAddition,
      },
    );
  }

  Future<void> updateFixedSalary(int incomeMinor) async {
    await _dio.post(
      '/wallet/fixed-salary',
      data: {
        'incomeMinor': incomeMinor,
      },
    );
  }

  Future<void> addSpending(int amountMinor, String platform, {String? merchant, String? category}) async {
    await _dio.post(
      '/wallet/spendings',
      data: {
        'amountMinor': amountMinor,
        'platform': platform,
        if (merchant != null) 'merchant': merchant,
        if (category != null) 'category': category,
      },
    );
  }
}

class WalletSummary {
  const WalletSummary({
    required this.balanceMinor,
    required this.currency,
    required this.recentTransactions,
  });

  final int balanceMinor;
  final String currency;
  final List<WalletTransaction> recentTransactions;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balanceMinor: json['balanceMinor'] as int,
      currency: json['currency'] as String,
      recentTransactions: (json['recentTransactions'] as List<dynamic>)
          .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({required this.amountMinor, required this.type, required this.description});

  final int amountMinor;
  final String type;
  final String description;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      amountMinor: json['amountMinor'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
    );
  }
}

class MockWalletRepository implements WalletRepository {
  @override
  Dio get _dio => throw UnimplementedError();

  @override
  Future<WalletSummary> summary() async {
    await Future.delayed(const Duration(seconds: 1));
    return const WalletSummary(
      balanceMinor: 245000,
      currency: 'USD',
      recentTransactions: [
        WalletTransaction(amountMinor: 5000, type: 'MANUAL_SAVE', description: 'Saved from allowance'),
        WalletTransaction(amountMinor: 1500, type: 'EARNED', description: 'Completed chores'),
      ],
    );
  }

  @override
  Future<void> addManualSave(int amountMinor) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> updateExternalSaving(String platform, int amountMinor, bool isAddition) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> updateFixedSalary(int incomeMinor) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> addSpending(int amountMinor, String platform, {String? merchant, String? category}) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
