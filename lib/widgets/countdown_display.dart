import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../models/item.dart';
import '../l10n/app_localizations.dart';

class CountdownDisplay extends StatelessWidget {
  final DateTime date;
  final ItemStatus status;
  final ItemDeadlineType deadlineType;

  const CountdownDisplay({
    super.key,
    required this.date,
    required this.status,
    this.deadlineType = ItemDeadlineType.expiry,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    final color = switch (status) {
      ItemStatus.valid => Theme.of(context).colorScheme.onSurfaceVariant,
      ItemStatus.warning => AppPalette.statusWarning,
      ItemStatus.expired => AppPalette.statusExpired,
      ItemStatus.none => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    String countdown;
    if (diff < 0) {
      countdown = context.tr('days_expired', {'days': diff.abs().toString()});
    } else if (diff == 0) {
      countdown = context.tr('expires_today');
    } else {
      countdown = context.tr('days_left', {'days': diff.toString()});
    }

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final deadlineLabel = deadlineType == ItemDeadlineType.warranty
        ? context.tr('warranty_end_date')
        : context.tr('expiry_date');
    final text = '$deadlineLabel $dateStr  $countdown';

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
