import 'package:flutter/material.dart';
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/purchase_service.dart';
import '../l10n/app_localizations.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  bool _purchasing = false;
  bool _restoring = false;
  ProductDetails? _product;
  Timer? _operationTimeout;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _operationTimeout?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    await _purchaseService.init();
    final product = await _purchaseService.getPremiumProduct();
    if (mounted) setState(() => _product = product);
  }

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: Text(context.tr('premium_title'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(context.tr('premium_already_owned'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                const Icon(Icons.workspace_premium,
                    size: 56, color: Colors.white),
                const SizedBox(height: 12),
                Text(context.tr('premium_title'),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(context.tr('premium_subtitle'),
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 16),
                Text(_product?.price ?? context.tr('premium_price'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text('Free',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                                fontWeight: FontWeight.w600)))),
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Text('Pro',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
          const Divider(height: 1),
          _featureRow(context.tr('premium_unlimited_items'), '20', '∞', true),
          _featureRow(context.tr('premium_unlimited_family'), '1', '∞', true),
          _featureRow(
              context.tr('premium_advanced_reminders'), '❌', '✅', false),
          _featureRow(context.tr('premium_backup_export'), '❌', '✅', false),
          _featureRow(context.tr('premium_no_ads'), '❌', '✅', false),
          const SizedBox(height: 32),
          // Purchase button
          FilledButton.icon(
            onPressed: _purchasing || _restoring ? null : _purchase,
            icon: _purchasing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.lock_open),
            label: Text(_purchasing
                ? context.tr('premium_purchasing')
                : context.tr('premium_btn_upgrade')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // Restore button
          OutlinedButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: _restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.restore),
            label: Text(_restoring
                ? context.tr('premium_restoring')
                : context.tr('premium_btn_restore')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _product?.price ?? context.tr('premium_price'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    _startOperationTimeout();

    final result = await _purchaseService.purchase();
    if (!mounted || result == PurchaseResult.started) return;

    _stopOperation();
    _showResultMessage(result);
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    _startOperationTimeout();

    final result = await _purchaseService.restore();
    if (!mounted || result == PurchaseResult.started) return;

    _stopOperation();
    _showResultMessage(result);
  }

  void _startOperationTimeout() {
    _operationTimeout?.cancel();
    _operationTimeout = Timer(const Duration(seconds: 45), () {
      if (!mounted) return;
      _stopOperation();
      _showResultMessage(PurchaseResult.failed);
    });
  }

  void _stopOperation() {
    _operationTimeout?.cancel();
    _operationTimeout = null;
    if (mounted) {
      setState(() {
        _purchasing = false;
        _restoring = false;
      });
    }
  }

  void _showResultMessage(PurchaseResult result) {
    final key = switch (result) {
      PurchaseResult.unavailable => 'premium_unavailable',
      PurchaseResult.productNotFound => 'premium_product_not_found',
      PurchaseResult.failed => 'premium_error',
      PurchaseResult.started => 'premium_success',
    };
    final message = result == PurchaseResult.failed
        ? context.tr(key, {'error': context.tr('premium_try_again')})
        : context.tr(key);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _featureRow(String label, String free, String pro, bool isCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface))),
          Expanded(
            flex: 1,
            child: Center(
              child: isCount
                  ? Text(free,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w500))
                  : Text(free, style: const TextStyle(fontSize: 16)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isCount
                  ? Text(pro,
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold))
                  : Text(pro, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
