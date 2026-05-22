import 'package:flutter/material.dart';
import '../constants.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = '',
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textDisabled.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.textDisabled), textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
