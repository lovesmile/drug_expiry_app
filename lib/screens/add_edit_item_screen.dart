import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../constants.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../providers/user_provider.dart';
import '../services/barcode_service.dart';
import '../l10n/app_localizations.dart';
import 'premium_screen.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item;
  final String? initialName;
  final BarcodeResult? barcodeResult;

  const AddEditItemScreen({super.key, this.item, this.initialName, this.barcodeResult});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _batchCtrl;
  late final TextEditingController _manufacturerCtrl;
  late DateTime _expiryDate;
  late int _iconCodePoint;
  late ItemCategory _category;
  String? _photoPath;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final d = widget.item;
    final br = widget.barcodeResult;
    _nameCtrl = TextEditingController(text: d?.name ?? br?.name ?? widget.initialName ?? '');
    _subtitleCtrl = TextEditingController(text: d?.subtitle ?? br?.genericName ?? '');
    _specCtrl = TextEditingController(text: d?.specification ?? br?.specification ?? '');
    _batchCtrl = TextEditingController(text: d?.batchNumber ?? '');
    _manufacturerCtrl = TextEditingController(text: d?.manufacturer ?? br?.manufacturer ?? '');
    _expiryDate = d?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
    _category = d?.category ?? ItemCategory.drug;
    _iconCodePoint = d?.iconCodePoint ?? _allIcons[_categoryDefaultIdx[_category] ?? 0].codePoint;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _specCtrl.dispose();
    _batchCtrl.dispose();
    _manufacturerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _photoOption(ctx, Icons.camera_alt_outlined, context.tr('photo_camera'), () => Navigator.pop(ctx, 'camera')),
            _photoOption(ctx, Icons.photo_library_outlined, context.tr('photo_gallery'), () => Navigator.pop(ctx, 'gallery')),
            _photoOption(ctx, Icons.delete_outline, context.tr('photo_delete'), () => Navigator.pop(ctx, 'delete')),
          ],
        ),
      ),
    );
    if (source == 'camera') {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
      if (photo != null) setState(() => _photoPath = photo.path);
    } else if (source == 'gallery') {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() => _photoPath = result.files.single.path);
      }
    } else if (source == 'delete') {
      setState(() => _photoPath = null);
    }
  }

  Widget _photoOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.brandSecondary,
            child: Icon(icon, color: Theme.of(ctx).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // Default icon index for each category (maps to _allIcons index)
  static const Map<ItemCategory, int> _categoryDefaultIdx = {
    ItemCategory.drug: 0,
    ItemCategory.food: 1,
    ItemCategory.cosmetic: 2,
    ItemCategory.dailyNecessity: 3,
    ItemCategory.electronics: 7,
    ItemCategory.other: 8,
  };

  // 14 icons mapped to 14 unique label keys (no duplicates)
  // Labels: 药片, 食品, 酒水饮料, 美妆, 日用, 电子, 通用, 其他, 保健, 胶囊, 液体, 喷雾, 颗粒, 滴剂
  static const _allIcons = [
    Icons.medication,             // 0  icon_label_pill        药片
    Icons.restaurant,             // 1  icon_label_food        食品
    Icons.local_drink,             // 2  icon_label_drinks     酒水饮料
    Icons.face,                   // 3  icon_label_cosmetics   美妆
    Icons.science,                // 4  icon_label_biotech     日用
    Icons.devices,                // 5  icon_label_electronics  电子
    Icons.inventory_2,            // 6  icon_label_general     通用
    Icons.category,               // 7  icon_label_other       其他
    Icons.health_and_safety,      // 8  icon_label_health      保健
    Icons.local_pharmacy,         // 9  icon_label_capsule     胶囊
    Icons.opacity,               // 10 icon_label_liquid      液体
    Icons.spa,                   // 11 icon_label_spray       喷雾
    Icons.grain,                 // 12 icon_label_granule     颗粒
    Icons.water_drop,            // 13 icon_label_drops       滴剂
  ];

  static const _allIconLabelKeys = [
    'icon_label_pill',         // 0
    'icon_label_food',         // 1
    'icon_label_drinks',       // 2
    'icon_label_cosmetics',    // 3
    'icon_label_biotech',      // 4
    'icon_label_electronics',  // 5
    'icon_label_general',      // 6
    'icon_label_other',        // 7
    'icon_label_health',       // 8
    'icon_label_capsule',      // 9
    'icon_label_liquid',       // 10
    'icon_label_spray',        // 11
    'icon_label_granule',      // 12
    'icon_label_drops',        // 13
  ];

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(context.tr('icon_picker_title'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_allIcons.length, (idx) {
            final icon = _allIcons[idx];
            final selected = _iconCodePoint == icon.codePoint;
            return GestureDetector(
              onTap: () => setState(() => _iconCodePoint = icon.codePoint),
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : AppColors.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(_allIconLabelKeys[idx]),
                      style: TextStyle(fontSize: 10, color: selected ? Colors.white : AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<ItemCategory>(
        // ignore: deprecated_member_use
        value: _category,
        decoration: InputDecoration(
          labelText: context.tr('category'),
          filled: true,
          fillColor: AppColors.bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            borderSide: BorderSide.none,
          ),
        ),
        items: ItemCategory.values.map((c) {
          final key = switch (c) {
            ItemCategory.drug => 'category_drug',
            ItemCategory.food => 'category_food',
            ItemCategory.cosmetic => 'category_cosmetic',
            ItemCategory.dailyNecessity => 'category_daily_necessity',
            ItemCategory.electronics => 'category_electronics',
            ItemCategory.other => 'category_other',
          };
          return DropdownMenuItem(value: c, child: Text(context.tr(key)));
        }).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _category = v;
              // Reset icon to category default when switching category
              _iconCodePoint = _allIcons[_categoryDefaultIdx[v] ?? 0].codePoint;
            });
          }
        },
      ),
    );
  }

  Widget _quickDateChip(String label, Duration duration) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.brandSecondary,
      onPressed: () => setState(() => _expiryDate = DateTime.now().add(duration)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Premium limit check for new items
    if (!_isEditing) {
      final user = context.read<UserProvider>().user;
      if (user != null && !user.isPremium && user.recordCount >= user.recordLimit) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('premium_limit_reached')),
            content: Text(context.tr('premium_limit_body').replaceAll('{limit}', user.recordLimit.toString())),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('premium_btn_upgrade'))),
            ],
          ),
        );
        if (ok == true && mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
        }
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final item = Item(
        id: widget.item?.id,
        name: _nameCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty ? null : _subtitleCtrl.text.trim(),
        specification: _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
        batchNumber: _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty ? null : _manufacturerCtrl.text.trim(),
        expiryDate: _expiryDate,
        photoPath: _photoPath ?? widget.item?.photoPath,
        iconCodePoint: _iconCodePoint,
        category: _category,
        createdAt: widget.item?.createdAt,
        updatedAt: widget.item?.updatedAt,
      );

      final provider = context.read<ItemProvider>();
      if (_isEditing) {
        await provider.updateItem(item);
      } else {
        await provider.addItem(item);
        if (mounted) context.read<UserProvider>().incrementRecordCount();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('save_failed')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(title: Text(_isEditing ? context.tr('edit_drug') : context.tr('add_drug_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16,
            16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildSection(context.tr('basic_info'), [
              _buildCategorySelector(),
              _buildTextField(_nameCtrl, context.tr('drug_name'), context.tr('drug_name_hint')),
              _buildTextField(_subtitleCtrl, context.tr('generic_name'), context.tr('generic_name_hint')),
              _buildTextField(_specCtrl, context.tr('specification'), context.tr('spec_hint')),
            ]),
            const SizedBox(height: 16),
            _buildIconPicker(),
            const SizedBox(height: 16),
            _buildSection(context.tr('production_info'), [
              _buildTextField(_batchCtrl, context.tr('batch_number'), context.tr('batch_hint')),
              _buildTextField(_manufacturerCtrl, context.tr('manufacturer'), context.tr('manufacturer_hint')),
            ]),
            const SizedBox(height: 16),
            _buildSection(context.tr('expiry_section'), [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickDateChip(context.tr('quick_3m'), Duration(days: 90)),
                  _quickDateChip(context.tr('quick_6m'), Duration(days: 180)),
                  _quickDateChip(context.tr('quick_1y'), Duration(days: 365)),
                  _quickDateChip(context.tr('quick_2y'), Duration(days: 730)),
                  _quickDateChip(context.tr('quick_3y'), Duration(days: 1095)),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '${_category == ItemCategory.electronics ? '保修截止日期' : context.tr('expiry_date')} *',
                    prefixIcon: Icon(_category == ItemCategory.electronics ? Icons.verified_user_outlined : Icons.calendar_today),
                  ),
                  child: Text(
                    '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              if (_category == ItemCategory.electronics) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('electronics_warranty_hint'),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            _buildSection(context.tr('photo_section'), [
              InkWell(
                onTap: _pickPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                          child: Image.file(
                            File(_photoPath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        )
                      : widget.item?.photoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                              child: Image.file(
                                File(widget.item!.photoPath!),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textDisabled),
                                  SizedBox(height: 4),
                                  Text(context.tr('upload_photo'), style: TextStyle(color: AppColors.textDisabled)),
                                ],
                              ),
                            ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? context.tr('save_changes') : context.tr('add_drug'), style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: AppColors.bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            borderSide: BorderSide.none,
          ),
        ),
        validator: label.contains('*') ? (v) => (v == null || v.trim().isEmpty) ? context.tr('loading') : null : null,
      ),
    );
  }
}
