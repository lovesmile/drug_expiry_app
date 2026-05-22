import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/item.dart';
import '../l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final ItemStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ItemStatus.valid => context.tr('drug_status_valid'),
      ItemStatus.warning => context.tr('drug_status_warning'),
      ItemStatus.expired => context.tr('drug_status_expired'),
    };
    final color = switch (status) {
      ItemStatus.valid => AppColors.statusSuccess,
      ItemStatus.warning => AppColors.statusWarning,
      ItemStatus.expired => AppColors.statusError,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
