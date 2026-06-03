import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_format.dart';
import '../../../core/services/notification_interceptor.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/wallet_repository.dart';
import 'package:permission_handler/permission_handler.dart';

final walletDashboardProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).load();
});

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _initNotificationInterceptor();
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final interceptor = ref.read(notificationInterceptorProvider);
    final notifGranted = await interceptor.isPermissionGranted();
    final smsGranted = await Permission.sms.isGranted;
    if (mounted) {
      setState(() {
        _notificationPermissionGranted = notifGranted;
        _smsPermissionGranted = smsGranted;
      });
    }
  }

  Future<void> _initNotificationInterceptor() async {
    final interceptor = ref.read(notificationInterceptorProvider);
    final granted = await interceptor.isPermissionGranted();
    if (granted) {
      _startListening(interceptor);
    }
  }

  void _startListening(NotificationInterceptor interceptor) {
    interceptor.onSpendingDetected = (amount, merchant, platform) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Auto-tracked ₹$amount spent on $platform ($merchant)')),
        );
        _refresh(); // Automatically refresh the wallet to show the new spending
      }
    };
    interceptor.startListening();
  }

  Future<void> _requestNotificationPermission() async {
    final interceptor = ref.read(notificationInterceptorProvider);
    await interceptor.requestPermission();
    final granted = await interceptor.isPermissionGranted();
    if (granted) {
      _startListening(interceptor);
      if (mounted) {
        setState(() => _notificationPermissionGranted = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification Auto-tracking enabled!')));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied. Cannot track spending.')));
    }
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      if (mounted) {
        setState(() => _smsPermissionGranted = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS Auto-tracking enabled!')));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS permission denied.')));
    }
  }

  @override
  void dispose() {
    ref.read(notificationInterceptorProvider).stopListening();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(walletDashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(walletDashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Wallet',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: dashboardAsync.when(
        data: (dashboard) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildScoreSection(context, dashboard, colorScheme),
              const SizedBox(height: 24),
              _buildNovaInsight(context, dashboard, colorScheme),
              const SizedBox(height: 32),
              _buildPlatformsSection(context, dashboard, colorScheme),
              const SizedBox(height: 32),
              _buildSpendingsSection(context, dashboard, colorScheme),
            ],
          ),
        ),
        error: (err, _) => Center(child: Text('Unable to load wallet: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildScoreSection(BuildContext context, DashboardSummary dashboard, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Score', style: TextStyle(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${dashboard.financialScore}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colorScheme.primary)),
                      Text('/100', style: TextStyle(fontSize: 18, color: colorScheme.primary.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.show_chart, color: colorScheme.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Savings', style: TextStyle(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(formatMinorMoney(dashboard.monthlySavingsMinor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: InkWell(
                    onTap: () => _showEditSalarySheet(context, dashboard.monthlyIncomeMinor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Fixed Salary', style: TextStyle(color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7), fontSize: 12)),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 12, color: colorScheme.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dashboard.monthlyIncomeMinor != null ? formatMinorMoney(dashboard.monthlyIncomeMinor!) : 'Tap to set',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dashboard.monthlyIncomeMinor == null ? colorScheme.primary : null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNovaInsight(BuildContext context, DashboardSummary dashboard, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.auto_awesome, color: colorScheme.onPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nova Insight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(dashboard.novaInsight, style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformsSection(BuildContext context, DashboardSummary dashboard, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('External Savings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            TextButton.icon(
              onPressed: () => _showPlatformSheet(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Platform'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (dashboard.externalSavings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No external savings added yet. Track your PhonePe, Groww, or bank savings here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...dashboard.externalSavings.map((saving) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        saving.platform[0].toUpperCase(),
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(saving.platform, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Saved this month', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMinorMoney(saving.amountMinor), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showPlatformSheet(context, saving.platform),
                        child: Text('Add / Edit', style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showEditSalarySheet(BuildContext context, int? currentIncome) {
    final controller = TextEditingController(text: currentIncome != null ? (currentIncome / 100).toStringAsFixed(0) : '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fixed Salary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter your monthly fixed income to calculate your financial score.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Monthly Income',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : () async {
                    if (controller.text.isEmpty) return;
                    setState(() => saving = true);
                    try {
                      final amountMinor = (double.parse(controller.text) * 100).toInt();
                      await ref.read(walletRepositoryProvider).updateFixedSalary(amountMinor);
                      if (context.mounted) Navigator.pop(context);
                      _refresh();
                    } catch (_) {
                      setState(() => saving = false);
                    }
                  },
                  child: saving ? const CircularProgressIndicator() : const Text('Save Salary'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlatformSheet(BuildContext context, String? platformName) {
    final platformController = TextEditingController(text: platformName ?? '');
    final amountController = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platformName == null ? 'Add Platform Saving' : 'Update $platformName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (platformName == null) ...[
                TextField(
                  controller: platformController,
                  decoration: InputDecoration(
                    labelText: 'Platform Name (e.g. PhonePe)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : () async {
                        if (platformController.text.isEmpty || amountController.text.isEmpty) return;
                        setState(() => saving = true);
                        try {
                          final amountMinor = (double.parse(amountController.text) * 100).toInt();
                          await ref.read(walletRepositoryProvider).updateExternalSaving(platformController.text, amountMinor, false);
                          if (context.mounted) Navigator.pop(context);
                          _refresh();
                        } catch (_) {
                          setState(() => saving = false);
                        }
                      },
                      child: const Text('Overwrite Total'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : () async {
                        if (platformController.text.isEmpty || amountController.text.isEmpty) return;
                        setState(() => saving = true);
                        try {
                          final amountMinor = (double.parse(amountController.text) * 100).toInt();
                          await ref.read(walletRepositoryProvider).updateExternalSaving(platformController.text, amountMinor, true);
                          if (context.mounted) Navigator.pop(context);
                          _refresh();
                        } catch (_) {
                          setState(() => saving = false);
                        }
                      },
                      child: const Text('Add Funds (+)', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingsSection(BuildContext context, DashboardSummary dashboard, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Spending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            TextButton.icon(
              onPressed: _requestNotificationPermission,
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Auto-Track'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Total this month: ${formatMinorMoney(dashboard.monthlySpendingsMinor)}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (dashboard.recentSpendings.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Setup Auto-Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'To automatically log your UPI payments and build your Muscle Money dashboard without manual entry, grant the following permissions:',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _notificationPermissionGranted ? Colors.green.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.notifications, color: _notificationPermissionGranted ? Colors.green : colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Read Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Detect UPI payment alerts', style: TextStyle(fontSize: 12)),
                  trailing: _notificationPermissionGranted 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(onPressed: _requestNotificationPermission, child: const Text('Enable')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _smsPermissionGranted ? Colors.green.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.sms, color: _smsPermissionGranted ? Colors.green : colorScheme.onSurfaceVariant),
                  ),
                  title: const Text('Read SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Detect bank transaction texts', style: TextStyle(fontSize: 12)),
                  trailing: _smsPermissionGranted 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(onPressed: _requestSmsPermission, child: const Text('Enable')),
                ),
              ],
            ),
          )
        else
          ...dashboard.recentSpendings.map((spending) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        spending.merchant?.isNotEmpty == true ? spending.merchant![0].toUpperCase() : 'S',
                        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spending.merchant ?? 'Unknown Merchant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${spending.platform} • ${spending.category ?? 'Uncategorized'}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(formatMinorMoney(spending.amountMinor), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showSpendingDialog(BuildContext context, double amount, String merchant, String platform) {
    final categoryController = TextEditingController();
    bool saving = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Spending Detected!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You just spent ₹$amount on $platform.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'What was this for? (e.g. Food, Rent)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saving ? null : () async {
                    if (categoryController.text.isEmpty) return;
                    setState(() => saving = true);
                    try {
                      final amountMinor = (amount * 100).toInt();
                      await ref.read(walletRepositoryProvider).addSpending(
                        amountMinor,
                        platform,
                        merchant: merchant,
                        category: categoryController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                      _refresh();
                    } catch (_) {
                      setState(() => saving = false);
                    }
                  },
                  child: saving ? const CircularProgressIndicator() : const Text('Log Spending'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
