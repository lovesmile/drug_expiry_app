import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/user_provider.dart';
import '../services/purchase_service.dart';
import '../l10n/app_localizations.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _purchasing = false;
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final isPremium = user?.isPremium ?? false;

    // Auto-pop when premium unlocked during this session
    if (isPremium && (_purchasing || _restoring)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('premium_success'))),
          );
          Navigator.pop(context);
        }
      });
    }

    if (isPremium) {
      return Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(title: Text(context.tr('premium_title'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 80, color: AppColors.brandPrimary),
              const SizedBox(height: 16),
              Text(context.tr('premium_already_owned'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('close')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(title: Text(context.tr('premium_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                Text(context.tr('premium_title'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(context.tr('premium_subtitle'),
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 16),
                Text(context.tr('premium_price'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Feature comparison header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                const Expanded(flex: 1, child: Center(child: Text('Free', style: TextStyle(fontSize: 12, color: AppColors.textDisabled, fontWeight: FontWeight.w600)))),
                const Expanded(flex: 1, child: Center(child: Text('Pro', style: TextStyle(fontSize: 12, color: AppColors.brandPrimary, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          const Divider(height: 1),
          _featureRow(context.tr('premium_unlimited_items'), '20', '∞', true),
          _featureRow(context.tr('premium_unlimited_family'), '1', '∞', true),
          _featureRow(context.tr('premium_advanced_reminders'), '❌', '✅', false),
          _featureRow(context.tr('premium_backup_export'), '❌', '✅', false),
          _featureRow(context.tr('premium_no_ads'), '❌', '✅', false),
          const SizedBox(height: 32),
          // Purchase button
          FilledButton.icon(
            onPressed: _purchasing ? null : _purchase,
            icon: _purchasing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_open),
            label: Text(_purchasing ? context.tr('premium_purchasing') : context.tr('premium_btn_upgrade')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // Restore button
          OutlinedButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: _restoring
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.restore),
            label: Text(_restoring ? context.tr('premium_restoring') : context.tr('premium_btn_restore')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('premium_price'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    // Reset purchasing state after 30s if purchase doesn't complete
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _purchasing = false);
    });
    final service = PurchaseService();
    await service.purchase();
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final service = PurchaseService();
    await service.restore();
    if (mounted) setState(() => _restoring = false);
  }

  Widget _featureRow(String label, String free, String pro, bool isCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
          Expanded(
            flex: 1,
            child: Center(
              child: isCount
                  ? Text(free, style: const TextStyle(fontSize: 16, color: AppColors.textDisabled, fontWeight: FontWeight.w500))
                  : Text(free, style: const TextStyle(fontSize: 16)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isCount
                  ? Text(pro, style: const TextStyle(fontSize: 16, color: AppColors.brandPrimary, fontWeight: FontWeight.bold))
                  : Text(pro, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
