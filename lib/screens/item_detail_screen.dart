import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/loading_indicator.dart';
import '../design/app_colors.dart';
import '../design/widgets/gradient_badge.dart';
import '../services/share_service.dart';
import '../l10n/app_localizations.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final int itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.tr('drug_detail')),
        actions: [
          Consumer<ItemProvider>(
            builder: (context, provider, _) {
              final item =
                  provider.items.where((d) => d.id == itemId).firstOrNull;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item != null)
                    IconButton(
                      icon: Icon(Icons.share_outlined),
                      onPressed: () => ShareService.shareItem(item),
                    ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined),
                    onPressed: () {
                      if (item != null) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => AddEditItemScreen(item: item)));
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
          if (item == null) {
            return LoadingIndicator(message: context.tr('loading'));
          }

          final diff = item.daysLeft ?? 0;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 +
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            children: [
              _buildHeader(context, item),
              const SizedBox(height: 16),
              if (item.photoPath != null) _buildPhoto(context, item),
              const SizedBox(height: 16),
              _buildInfoCard(context, item),
              const SizedBox(height: 16),
              // Warranty card
              if (item.deadlineType == ItemDeadlineType.warranty &&
                  item.hasWarranty) ...[
                _buildWarrantyCard(context, item),
                const SizedBox(height: 16),
              ],
              if (item.hasDeadline) ...[
                _buildCountdownCard(context, diff, item),
                const SizedBox(height: 16),
              ],
              if (item.usageStatus == UsageStatus.active)
                _buildUsageActions(context, item),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppPalette.statusValidLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  GradientStatusBadge(
                    status: item.status,
                    label: switch (item.status) {
                      ItemStatus.valid => context.tr('drug_status_valid'),
                      ItemStatus.warning => context.tr('drug_status_warning'),
                      ItemStatus.expired => context.tr('drug_status_expired'),
                      ItemStatus.none => context.tr('deadline_type_none'),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.outlineVariant,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: ClipRRect(
        borderRadius: AppRadius.large,
        child: Image.file(File(item.photoPath!),
            height: 200, width: double.infinity, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('detail_info'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _infoRow(context, context.tr('generic_name'), item.subtitle ?? '-'),
            _infoRow(context, context.tr('specification'),
                item.specification ?? '-'),
            _infoRow(
                context, context.tr('batch_number'), item.batchNumber ?? '-'),
            _infoRow(
                context, context.tr('manufacturer'), item.manufacturer ?? '-'),
            if (item.hasDeadline)
              _infoRow(
                context,
                item.deadlineType == ItemDeadlineType.warranty
                    ? context.tr('warranty_end_date')
                    : context.tr('expiry_date'),
                item.formattedDeadlineDate,
              ),
            // Purchase date and warranty info
            if (item.hasWarranty) ...[
              const Divider(height: 24),
              _infoRow(context, context.tr('purchase_date'),
                  item.formattedPurchaseDate ?? '-'),
              _infoRow(
                  context,
                  context.tr('warranty_months'),
                  context.tr('warranty_months_value',
                      {'months': item.warrantyMonths.toString()})),
              _infoRow(context, context.tr('warranty_end_date'),
                  item.formattedWarrantyEndDate ?? '-'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyCard(BuildContext context, Item item) {
    final status = item.warrantyStatus;
    final color = switch (status) {
      WarrantyStatus.valid => AppPalette.statusValid,
      WarrantyStatus.warning => AppPalette.statusWarning,
      WarrantyStatus.expired => AppPalette.statusExpired,
      WarrantyStatus.none => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    final daysLeft = item.warrantyDaysLeft;
    final statusLabel = switch (status) {
      WarrantyStatus.valid => 'warranty_status_valid',
      WarrantyStatus.warning => 'warranty_status_warning',
      WarrantyStatus.expired => 'warranty_status_expired',
      WarrantyStatus.none => 'warranty_status_valid',
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.large,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  context.tr('warranty'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                WarrantyBadge(
                  status: status,
                  label: context.tr(statusLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (daysLeft != null) ...[
              Text(
                daysLeft < 0
                    ? context.tr('warranty_expired_days',
                        {'days': daysLeft.abs().toString()})
                    : context.tr('warranty_days_remaining',
                        {'days': daysLeft.toString()}),
                style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                daysLeft < 0
                    ? context.tr('warranty_expired')
                    : context.tr('days'),
                style: TextStyle(
                    fontSize: 14, color: color.withValues(alpha: 0.8)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _warrantyInfoChip(context, context.tr('purchase_date'),
                    item.formattedPurchaseDate ?? '-'),
                const SizedBox(width: 16),
                _warrantyInfoChip(context, context.tr('warranty_end_date'),
                    item.formattedWarrantyEndDate ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _warrantyInfoChip(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCountdownCard(BuildContext context, int diff, Item item) {
    final color = switch (item.status) {
      ItemStatus.valid => AppPalette.statusValid,
      ItemStatus.warning => AppPalette.statusWarning,
      ItemStatus.expired => AppPalette.statusExpired,
      ItemStatus.none => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final countdownText = diff < 0
        ? context.tr(
            item.deadlineType == ItemDeadlineType.warranty
                ? 'warranty_expired_days'
                : 'days_expired',
            {'days': diff.abs().toString()},
          )
        : diff == 0
            ? context.tr('expires_today')
            : context.tr('days_left', {'days': diff.toString()});

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              item.deadlineType == ItemDeadlineType.warranty
                  ? context.tr('warranty')
                  : context.tr('expiry_section'),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              countdownText,
              style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageActions(BuildContext context, Item item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('usage_status'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.check_circle_outline, size: 18),
                    label: Text(context.tr('mark_used_up')),
                    onPressed: () =>
                        _updateUsage(context, item, UsageStatus.usedUp),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text(context.tr('mark_discarded')),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.statusExpired),
                    onPressed: () =>
                        _updateUsage(context, item, UsageStatus.discarded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUsage(
      BuildContext context, Item item, UsageStatus status) async {
    final updated =
        item.copyWith(usageStatus: status, updatedAt: DateTime.now());
    await context.read<ItemProvider>().updateItem(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(status == UsageStatus.usedUp
                ? context.tr('marked_used_up')
                : context.tr('marked_discarded'))),
      );
    }
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface))),
        ],
      ),
    );
  }
}
