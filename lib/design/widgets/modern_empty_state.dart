import 'package:flutter/material.dart';
import '../../design/app_colors.dart';

/// 现代空状态组件
///
/// 修溢出 bug：原来用 `IntrinsicHeight + MainAxisSize.max + center` 模式，
/// 在底部可滚容器里会算错高度，导致 children 互相推到底部溢出 31px。
/// 改成 `SingleChildScrollView + ConstrainedBox(minHeight) + Column(min, center)`：
/// 留有内边距时 Column 高度 < 容器高度也能垂直居中，
/// 超出时通过 SingleChildScrollView 滚出可见区。
class ModernEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateType type;

  const ModernEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.type = EmptyStateType.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIllustration(context),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 24),
                    _ModernButton(
                      label: actionLabel!,
                      onTap: onAction!,
                      icon: Icons.add_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimAlpha = isDark ? 0.20 : 0.10;
    final midAlpha = isDark ? 0.32 : 0.20;
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.brandGreen.withValues(alpha: dimAlpha),
          ),
        ),
        // 内圈
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.brandGreen.withValues(alpha: midAlpha),
          ),
        ),
        // 图标
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.brandGreen,
            boxShadow: [
              BoxShadow(
                color: AppPalette.brandGreen.withValues(alpha: isDark ? 0.40 : 0.30),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            type.icon,
            size: 32,
            color: Colors.white,
          ),
        ),
        // 装饰点
        Positioned(
          top: 0,
          right: 20,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.statusWarning.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.brandBlue.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// 空状态类型
enum EmptyStateType {
  items(Icons.inventory_2_outlined),
  search(Icons.search_off_rounded),
  family(Icons.people_outline_rounded),
  warning(Icons.warning_amber_rounded);

  final IconData icon;
  const EmptyStateType(this.icon);
}

/// 现代按钮
class _ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const _ModernButton({
    required this.label,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.button,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.brandGreen,
            borderRadius: AppRadius.button,
            boxShadow: [
              BoxShadow(
                color: AppPalette.brandGreen.withValues(alpha: isDark ? 0.40 : 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 现代统计卡片
class ModernStatsCard extends StatelessWidget {
  final int total;
  final int valid;
  final int warning;
  final int expired;

  const ModernStatsCard({
    super.key,
    required this.total,
    required this.valid,
    required this.warning,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic = context.semantic;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.surfaceFor(theme.brightness),
        borderRadius: AppRadius.large,
        boxShadow: AppShadows.card(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppGradients.brandGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '物品概览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: '总数',
                  value: total.toString(),
                  color: colors.onSurface,
                  bgColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: '有效',
                  value: valid.toString(),
                  color: AppPalette.statusValid,
                  bgColor: semantic.statusValidContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: '预警',
                  value: warning.toString(),
                  color: AppPalette.statusWarning,
                  bgColor: semantic.statusWarningContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatItem(
                  label: '过期',
                  value: expired.toString(),
                  color: AppPalette.statusExpired,
                  bgColor: semantic.statusExpiredContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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
