import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/item.dart';
import '../l10n/app_localizations.dart';

class CountdownDisplay extends StatelessWidget {
  final DateTime date;
  final ItemStatus status;

  const CountdownDisplay({super.key, required this.date, required this.status});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    final color = switch (status) {
      ItemStatus.valid => AppColors.textSecondary,
      ItemStatus.warning => AppColors.statusWarning,
      ItemStatus.expired => AppColors.statusError,
    };

    String countdown;
    if (diff < 0) {
      countdown = context.tr('days_expired', {'days': diff.abs().toString()});
    } else if (diff == 0) {
      countdown = context.tr('expires_today');
    } else {
      countdown = context.tr('days_left', {'days': diff.toString()});
    }

    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final text = '${context.tr('expiry_date')} $dateStr  $countdown';

    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
