import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../models/item.dart';
import 'gradient_badge.dart';

/// 现代物品卡片
class ModernItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ModernItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = context.semantic;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.card(theme.brightness),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // 顶部状态色条
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: _getStatusGradient(),
                  ),
                ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIcon(context),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GradientStatusBadge(
                                        status: item.status, compact: true),
                                  ],
                                ),
                                if (item.subtitle != null &&
                                    item.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (item.specification != null &&
                                        item.specification!.isNotEmpty) ...[
                                      _InfoChip(
                                        icon: Icons.straighten_rounded,
                                        label: item.specification!,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    _InfoChip(
                                      icon: item.icon,
                                      label: _getCategoryName(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 底部信息行：有效期 + 保修期 + 删除按钮。
                      // 修溢出 bug：原来用 Row+双 Expanded+按钮会在窄屏溢出 60px。
                      // 改用 Wrap + 每个计数项约束最小宽度，窄屏自动换行。
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.hasDeadline)
                            SizedBox(
                              width: 160,
                              child: _CountdownItem(
                                icon: item.deadlineType ==
                                        ItemDeadlineType.warranty
                                    ? Icons.verified_user_rounded
                                    : Icons.event_rounded,
                                label: _deadlineLabel(),
                                date: item.formattedDeadlineDate,
                                daysLeft: _deadlineDaysText(),
                                isWarning: item.status == ItemStatus.warning ||
                                    item.status == ItemStatus.expired,
                                isWarranty: item.deadlineType ==
                                    ItemDeadlineType.warranty,
                                semantic: semantic,
                                onSurfaceVariant: colors.onSurfaceVariant,
                              ),
                            ),
                          if (onDelete != null)
                            _DeleteButton(
                              onTap: onDelete!,
                              errorColor: colors.error,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final color = _getStatusColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.icon,
        color: color,
        size: 24,
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    switch (item.status) {
      case ItemStatus.valid:
        return AppGradients.valid;
      case ItemStatus.warning:
        return AppGradients.warning;
      case ItemStatus.expired:
        return AppGradients.expired;
      case ItemStatus.none:
        return const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
        );
    }
  }

  Color _getStatusColor() {
    // 状态主体色：跨主题不变，含义优先于"主题跟随"
    return AppPalette.colorOf(item.status);
  }

  String _getCategoryName() {
    switch (item.category) {
      case ItemCategory.drug:
        return '药品';
      case ItemCategory.food:
        return '食品';
      case ItemCategory.cosmetic:
        return '化妆品';
      case ItemCategory.dailyNecessity:
        return '日用品';
      case ItemCategory.electronics:
        return '电子产品';
      case ItemCategory.other:
        return '其他';
    }
  }

  String _deadlineLabel() {
    switch (item.deadlineType) {
      case ItemDeadlineType.expiry:
        return '有效期';
      case ItemDeadlineType.warranty:
        return '保修期';
      case ItemDeadlineType.none:
        return '期限';
    }
  }

  String _deadlineDaysText() {
    final days = item.daysLeft;
    if (days == null) return '-';
    return days < 0 ? '已过期 ${-days} 天' : '剩余 $days 天';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  final String daysLeft;
  final bool isWarning;
  final bool isWarranty;
  final AppSemanticColors semantic;
  final Color onSurfaceVariant;

  const _CountdownItem({
    required this.icon,
    required this.label,
    required this.date,
    required this.daysLeft,
    this.isWarning = false,
    this.isWarranty = false,
    required this.semantic,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    // 状态主体色：跨主题不变；普通文字走 onSurfaceVariant 随主题切换。
    final color = isWarning
        ? (isWarranty ? AppPalette.statusWarning : AppPalette.statusExpired)
        : onSurfaceVariant;
    final containerColor = isWarning
        ? (isWarranty
            ? semantic.statusWarningContainer
            : semantic.statusExpiredContainer)
        : Colors.transparent;
    final onContainerColor = isWarning
        ? (isWarranty
            ? semantic.onStatusWarningContainer
            : semantic.onStatusExpiredContainer)
        : color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: onSurfaceVariant.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            daysLeft,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: onContainerColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color errorColor;

  const _DeleteButton({required this.onTap, required this.errorColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: errorColor.withValues(alpha: isDark ? 0.20 : 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: errorColor,
          ),
        ),
      ),
    );
  }
}
