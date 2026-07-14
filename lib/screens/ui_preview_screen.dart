import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/widgets/gradient_badge.dart';
import '../design/widgets/modern_item_card.dart';
import '../design/widgets/modern_empty_state.dart';
import '../models/item.dart';

/// UI 设计预览页面
class UIPreviewScreen extends StatefulWidget {
  const UIPreviewScreen({super.key});

  @override
  State<UIPreviewScreen> createState() => _UIPreviewScreenState();
}

class _UIPreviewScreenState extends State<UIPreviewScreen> {
  int _selectedTab = 0;

  // 示例数据
  final List<Item> _sampleItems = [
    Item(
      id: 1,
      name: '维生素C咀嚼片',
      subtitle: '100片装',
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      category: ItemCategory.drug,
      iconCodePoint: Icons.medication.codePoint,
    ),
    Item(
      id: 2,
      name: '小米手机',
      subtitle: '12GB+256GB',
      expiryDate: DateTime.now().add(const Duration(days: 365)),
      category: ItemCategory.electronics,
      purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      warrantyMonths: 24,
      iconCodePoint: Icons.phone_android.codePoint,
    ),
    Item(
      id: 3,
      name: '感冒灵颗粒',
      subtitle: '10gx9袋',
      expiryDate: DateTime.now().add(const Duration(days: 27)),
      category: ItemCategory.drug,
      iconCodePoint: Icons.medication_liquid.codePoint,
    ),
    Item(
      id: 4,
      name: 'SK-II精华露',
      subtitle: '230ml',
      expiryDate: DateTime.now().subtract(const Duration(days: 30)),
      category: ItemCategory.cosmetic,
      iconCodePoint: Icons.spa.codePoint,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsV2.bgMain,
      appBar: AppBar(
        backgroundColor: AppColorsV2.bgSurface,
        elevation: 0,
        title: const Text(
          '新 UI 设计预览',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColorsV2.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_rounded, color: AppColorsV2.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // ========== 1. 统计卡片预览 ==========
            _SectionTitle(title: '1. 统计卡片'),
            ModernStatsCard(
              total: 12,
              valid: 8,
              warning: 3,
              expired: 1,
            ),

            const SizedBox(height: 24),

            // ========== 2. 状态标签预览 ==========
            _SectionTitle(title: '2. 状态标签'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  GradientStatusBadge(status: ItemStatus.valid),
                  GradientStatusBadge(status: ItemStatus.warning),
                  GradientStatusBadge(status: ItemStatus.expired),
                  const SizedBox(height: 8),
                  WarrantyBadge(status: WarrantyStatus.valid),
                  WarrantyBadge(status: WarrantyStatus.warning),
                  WarrantyBadge(status: WarrantyStatus.expired),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ========== 3. 物品卡片预览 ==========
            _SectionTitle(title: '3. 物品卡片'),
            ..._sampleItems.map((item) => ModernItemCard(
              item: item,
              onTap: () {},
              onDelete: () {},
            )),

            const SizedBox(height: 24),

            // ========== 4. 空状态预览 ==========
            _SectionTitle(title: '4. 空状态'),
            SizedBox(
              height: 400,
              child: ModernEmptyState(
                title: '还没有任何物品',
                subtitle: '点击下方按钮添加你的第一个物品',
                actionLabel: '添加物品',
                onAction: () {},
              ),
            ),

            const SizedBox(height: 24),

            // ========== 5. 标签筛选预览 ==========
            _SectionTitle(title: '5. 标签筛选'),
            _buildTabBar(),

            const SizedBox(height: 24),

            // ========== 6. 按钮样式预览 ==========
            _SectionTitle(title: '6. 按钮样式'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ButtonRow(
                    label: '主按钮',
                    child: _ModernPrimaryButton(label: '添加物品', onTap: () {}),
                  ),
                  const SizedBox(height: 12),
                  _ButtonRow(
                    label: '次要按钮',
                    child: _ModernSecondaryButton(label: '取消', onTap: () {}),
                  ),
                  const SizedBox(height: 12),
                  _ButtonRow(
                    label: '图标按钮',
                    child: _ModernIconButton(icon: Icons.qr_code_scanner, onTap: () {}),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ========== 7. 输入框预览 ==========
            _SectionTitle(title: '7. 输入框'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ModernTextField(
                    label: '物品名称',
                    hint: '请输入物品名称',
                    icon: Icons.edit_rounded,
                  ),
                  const SizedBox(height: 12),
                  _ModernTextField(
                    label: '有效期',
                    hint: '请选择日期',
                    icon: Icons.calendar_today_rounded,
                    suffix: '2025-06-18',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ========== 8. 保修期卡片预览 ==========
            _SectionTitle(title: '8. 保修期卡片'),
            _buildWarrantyCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['全部', '有效', '预警', '过期', '归档'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColorsV2.bgElevated,
        borderRadius: AppRadius.largeRadius,
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColorsV2.bgSurface : Colors.transparent,
                  borderRadius: AppRadius.mediumRadius,
                  boxShadow: selected ? AppShadowsV2.card() : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppPalette.brandGreen : AppColorsV2.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWarrantyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.statusValid.withValues(alpha: 0.1),
            AppPalette.statusValid.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: AppPalette.statusValid.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.statusValid.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppPalette.statusValid,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保修期',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColorsV2.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '剩余 695 天',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.statusValid,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.statusValid,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: const Text(
                  '保修中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: AppColorsV2.borderLight,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WarrantyInfo(label: '购买日期', value: '2024-06-18'),
              _WarrantyInfo(label: '保修时长', value: '24 个月'),
              _WarrantyInfo(label: '截止日期', value: '2026-06-18'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColorsV2.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _ButtonRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColorsV2.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ModernPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ModernPrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.brandGreen,
            borderRadius: AppRadius.buttonRadius,
            boxShadow: [
              BoxShadow(
                color: AppPalette.brandGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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

class _ModernSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ModernSecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColorsV2.bgElevated,
            borderRadius: AppRadius.buttonRadius,
            border: Border.all(color: AppColorsV2.borderLight),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColorsV2.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ModernIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColorsV2.bgElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColorsV2.textSecondary),
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? suffix;

  const _ModernTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsV2.bgSurface,
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(color: AppColorsV2.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColorsV2.textTertiary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColorsV2.textSecondary,
                ),
              ),
              const Spacer(),
              if (suffix != null)
                Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColorsV2.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(
              fontSize: 15,
              color: AppColorsV2.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyInfo extends StatelessWidget {
  final String label;
  final String value;

  const _WarrantyInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColorsV2.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColorsV2.textPrimary,
          ),
        ),
      ],
    );
  }
}
