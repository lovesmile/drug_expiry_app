import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/status_badge.dart';
import '../services/share_service.dart';
import '../l10n/app_localizations.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final int itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text(context.tr('drug_detail')),
        actions: [
          Consumer<ItemProvider>(
            builder: (context, provider, _) {
              final item = provider.items.where((d) => d.id == itemId).firstOrNull;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => ShareService.shareItem(item),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      if (item != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditItemScreen(item: item)));
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ItemProvider>(
        builder: (context, provider, _) {
          final item = provider.items.where((d) => d.id == itemId).firstOrNull;
          if (item == null) return LoadingIndicator(message: context.tr('loading'));

          final now = DateTime.now();
          final diff = item.expiryDate.difference(now).inDays;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16, 16, 16,
              16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildHeader(context, item),
              const SizedBox(height: 16),
              if (item.photoPath != null) _buildPhoto(item),
              const SizedBox(height: 16),
              _buildInfoCard(context, item),
              const SizedBox(height: 16),
              _buildCountdownCard(context, diff, item),
              const SizedBox(height: 16),
              if (item.usageStatus == UsageStatus.active) _buildUsageActions(context, item),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  StatusBadge(status: item.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(Item item) {
    return Card(
      elevation: 0,
      color: AppColors.borderLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Image.file(File(item.photoPath!), height: 200, width: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('detail_info'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _infoRow(context, context.tr('generic_name'), item.subtitle ?? '-'),
            _infoRow(context, context.tr('specification'), item.specification ?? '-'),
            _infoRow(context, context.tr('batch_number'), item.batchNumber ?? '-'),
            _infoRow(context, context.tr('manufacturer'), item.manufacturer ?? '-'),
            _infoRow(context, context.tr('expiry_date'), item.formattedExpiryDate),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, int diff, Item item) {
    final labelKey = switch (item.status) {
      ItemStatus.valid => 'drug_status_label_valid',
      ItemStatus.warning => 'drug_status_label_warning',
      ItemStatus.expired => 'drug_status_label_expired',
    };
    final color = switch (item.status) {
      ItemStatus.valid => AppColors.statusSuccess,
      ItemStatus.warning => AppColors.statusWarning,
      ItemStatus.expired => AppColors.statusError,
    };
    final countdownText = diff < 0
        ? context.tr('days_expired', {'days': diff.abs().toString()})
        : diff == 0
            ? context.tr('expires_today')
            : context.tr('days_left', {'days': diff.toString()});

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(context.tr(labelKey), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 12),
            Text(
              countdownText,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageActions(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('usage_status'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(context.tr('mark_used_up')),
                    onPressed: () => _updateUsage(context, item, UsageStatus.usedUp),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(context.tr('mark_discarded')),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusError),
                    onPressed: () => _updateUsage(context, item, UsageStatus.discarded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUsage(BuildContext context, Item item, UsageStatus status) async {
    final updated = item.copyWith(usageStatus: status, updatedAt: DateTime.now());
    await context.read<ItemProvider>().updateItem(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == UsageStatus.usedUp ? context.tr('marked_used_up') : context.tr('marked_discarded'))),
      );
    }
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
