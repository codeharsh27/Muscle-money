import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../../features/wallet/data/wallet_repository.dart';

final notificationInterceptorProvider = Provider<NotificationInterceptor>((ref) {
  return NotificationInterceptor(ref);
});

class NotificationInterceptor {
  final Ref ref;
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  
  // Optional callback for UI updates
  Function(double amount, String merchant, String platform)? onSpendingDetected;

  NotificationInterceptor(this.ref);

  Future<bool> isPermissionGranted() async {
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await NotificationListenerService.requestPermission();
    } catch (e) {
      // Ignore
    }
  }

  void startListening() {
    if (_subscription != null) return; // already listening

    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      if (event.packageName == null) return;
      
      final packageName = event.packageName!.toLowerCase();
      final title = (event.title ?? '').toLowerCase();
      final content = (event.content ?? '').toLowerCase();
      final fullText = '$title $content';

      // Check for UPI apps
      bool isPhonePe = packageName.contains('com.phonepe.app');
      bool isGPay = packageName.contains('com.google.android.apps.nbu.paisa.user');
      bool isPaytm = packageName.contains('net.one97.paytm');

      if (!isPhonePe && !isGPay && !isPaytm) return;

      // Ensure it's a payment outgoing notification
      if (!fullText.contains('paid') && !fullText.contains('sent') && !fullText.contains('debited')) return;
      if (fullText.contains('received') || fullText.contains('requested') || fullText.contains('failed')) return;

      // Extract Amount
      final RegExp amountRegExp = RegExp(r'(?:₹|rs\.?|inr)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
      final match = amountRegExp.firstMatch(fullText);
      
      if (match != null) {
         final amountStr = match.group(1);
         if (amountStr != null) {
            final amount = double.tryParse(amountStr);
            if (amount != null && amount > 0) {
                // Extract Merchant
                String merchant = "Unknown";
                
                if (isPhonePe && title.contains('paid to')) {
                    merchant = title.replaceAll('paid to', '').trim();
                } else if (isGPay && fullText.contains('paid ')) {
                    final split = fullText.split('to ');
                    if (split.length > 1) {
                        merchant = split[1].split('₹').first.trim();
                    }
                } else if (isPaytm && title.contains('paid ₹')) {
                     final split = title.split('to ');
                     if (split.length > 1) merchant = split[1].trim();
                }

                // Clean up merchant name
                merchant = merchant.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
                if (merchant.isEmpty) merchant = "Merchant";

                String platform = isPhonePe ? "PhonePe" : isGPay ? "GPay" : "Paytm";

                // Auto-log to backend
                final amountMinor = (amount * 100).toInt();
                ref.read(walletRepositoryProvider).addSpending(
                   amountMinor,
                   platform,
                   merchant: merchant,
                   category: 'Auto-Tracked',
                ).catchError((_) {}); // Fire and forget

                onSpendingDetected?.call(amount, merchant, platform);
            }
         }
      }
    });
  }

  void stopListening() {
    // Keep listening in background, do not cancel unless forced.
    // _subscription?.cancel();
    // _subscription = null;
  }
}
