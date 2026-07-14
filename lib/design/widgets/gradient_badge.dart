import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../models/item.dart';

/// 现代渐变状态标签
class GradientStatusBadge extends StatelessWidget {
  final ItemStatus status;
  final bool compact;
  final String? label;

  const GradientStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _getConfig();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: isDark ? 0.40 : 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 12 : 14,
            color: Colors.white,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case ItemStatus.valid:
        return _BadgeConfig(
          label: label ?? '有效',
          color: AppPalette.statusValid,
          gradient: AppGradients.valid,
          icon: Icons.check_circle_rounded,
        );
      case ItemStatus.warning:
        return _BadgeConfig(
          label: label ?? '即将过期',
          color: AppPalette.statusWarning,
          gradient: AppGradients.warning,
          icon: Icons.warning_rounded,
        );
      case ItemStatus.expired:
        return _BadgeConfig(
          label: label ?? '已过期',
          color: AppPalette.statusExpired,
          gradient: AppGradients.expired,
          icon: Icons.error_rounded,
        );
      case ItemStatus.none:
        return _BadgeConfig(
          label: label ?? '无期限',
          color: const Color(0xFF64748B),
          gradient: const LinearGradient(
            colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
          ),
          icon: Icons.all_inclusive,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final LinearGradient gradient;
  final IconData icon;

  _BadgeConfig({
    required this.label,
    required this.color,
    required this.gradient,
    required this.icon,
  });
}

/// 保修期状态标签
class WarrantyBadge extends StatelessWidget {
  final WarrantyStatus status;
  final bool compact;
  final String? label;

  const WarrantyBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final config = _getConfig(context, colors, semantic);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? 10 : 12,
            color: config.color,
          ),
          SizedBox(width: compact ? 3 : 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _WarrantyConfig _getConfig(
      BuildContext context, ColorScheme colors, AppSemanticColors semantic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimAlpha = isDark ? 0.40 : 0.30;
    switch (status) {
      case WarrantyStatus.none:
        return _WarrantyConfig(
          label: label ?? '无保修',
          color: colors.onSurfaceVariant,
          bgColor: colors.surfaceContainerHighest,
          borderColor: colors.outlineVariant,
          icon: Icons.shield_outlined,
        );
      case WarrantyStatus.valid:
        return _WarrantyConfig(
          label: label ?? '保修中',
          color: AppPalette.statusValid,
          bgColor: semantic.statusValidContainer,
          borderColor: AppPalette.statusValid.withValues(alpha: dimAlpha),
          icon: Icons.verified_user_rounded,
        );
      case WarrantyStatus.warning:
        return _WarrantyConfig(
          label: label ?? '即将过保',
          color: AppPalette.statusWarning,
          bgColor: semantic.statusWarningContainer,
          borderColor: AppPalette.statusWarning.withValues(alpha: dimAlpha),
          icon: Icons.access_time_rounded,
        );
      case WarrantyStatus.expired:
        return _WarrantyConfig(
          label: label ?? '已过保',
          color: AppPalette.statusExpired,
          bgColor: semantic.statusExpiredContainer,
          borderColor: AppPalette.statusExpired.withValues(alpha: dimAlpha),
          icon: Icons.shield_outlined,
        );
    }
  }
}

class _WarrantyConfig {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;

  _WarrantyConfig({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
  });
}
