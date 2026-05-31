import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

final notificationInterceptorProvider = Provider<NotificationInterceptor>((ref) {
  return NotificationInterceptor();
});

class NotificationInterceptor {
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  
  // Callback when a spending notification is detected
  Function(double amount, String merchant, String platform)? onSpendingDetected;

  Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }

  void startListening() {
    _subscription = NotificationListenerService.notificationsStream.listen((event) {
      if (event.packageName == null || event.title == null || event.content == null) return;
      
      final packageName = event.packageName!.toLowerCase();
      final title = event.title!.toLowerCase();
      final content = event.content!.toLowerCase();

      // Check for UPI apps
      bool isUpiApp = packageName.contains('com.phonepe.app') || 
                      packageName.contains('com.google.android.apps.nbu.paisa.user') ||
                      packageName.contains('net.one97.paytm');

      if (!isUpiApp) return;

      // Simple regex to extract amount like "Paid ₹500" or "Rs. 500"
      if (title.contains('paid') || content.contains('paid') || 
          title.contains('sent') || content.contains('sent') ||
          title.contains('successful')) {
          
          final RegExp regExp = RegExp(r'(?:₹|rs\.?|inr)\s*(\d+(?:\.\d+)?)', caseSensitive: false);
          final match = regExp.firstMatch(title) ?? regExp.firstMatch(content);
          
          if (match != null) {
             final amountStr = match.group(1);
             if (amountStr != null) {
                final amount = double.tryParse(amountStr);
                if (amount != null && amount > 0) {
                    String merchant = "Unknown";
                    if (content.contains(" to ")) {
                        final parts = content.split(" to ");
                        if (parts.length > 1) {
                            merchant = parts[1].split(RegExp(r'[^a-zA-Z\s]')).first.trim();
                        }
                    }

                    String platform = "UPI";
                    if (packageName.contains('phonepe')) platform = "PhonePe";
                    else if (packageName.contains('nbu.paisa')) platform = "GPay";
                    else if (packageName.contains('paytm')) platform = "Paytm";

                    onSpendingDetected?.call(amount, merchant, platform);
                }
             }
          }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
