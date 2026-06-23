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
    _iconCodePoint = d?.iconCodePoint ?? _allIcons[_defaultIconIndex[_category] ?? 0].codePoint;
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

  // 14 icons in fixed order, matching _iconLabelKeys indices 0-13
  static const _allIcons = [
    Icons.inventory_2,           // 0  通用
    Icons.medication,             // 1  药片
    Icons.restaurant,             // 2  食品
    Icons.face,                  // 3  美妆
    Icons.cleaning_services,      // 4  清洁
    Icons.science,                // 5  日用
    Icons.health_and_safety,      // 6  保健
    Icons.kitchen,                // 7  箱包
    Icons.bolt,                   // 8  电子
    Icons.medical_information,    // 9  日用
    Icons.local_pharmacy,         // 10 药片
    Icons.healing,                // 11 保健
    Icons.opacity,                // 12 液体
    Icons.masks,                  // 13 保健
  ];

  // Per-category icon index lists (indices into _allIcons)
  static const Map<ItemCategory, List<int>> _categoryIconIndices = {
    ItemCategory.drug: [0, 1, 5, 6, 9, 10, 11, 12, 13],
    ItemCategory.food: [0, 2, 7],
    ItemCategory.cosmetic: [0, 3, 12],
    ItemCategory.dailyNecessity: [0, 4, 7],
    ItemCategory.electronics: [0, 8],
    ItemCategory.other: [0, 3, 4, 8],
  };

  // Default icon index for each category
  static const Map<ItemCategory, int> _defaultIconIndex = {
    ItemCategory.drug: 1,
    ItemCategory.food: 2,
    ItemCategory.cosmetic: 3,
    ItemCategory.dailyNecessity: 4,
    ItemCategory.electronics: 8,
    ItemCategory.other: 0,
  };

  Widget _buildIconPicker() {
    final indices = _categoryIconIndices[_category] ?? [0];
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
          children: indices.map((idx) {
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
                      context.tr(_iconLabelKeyForIndex(idx)),
                      style: TextStyle(fontSize: 10, color: selected ? Colors.white : AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _iconLabelKeyForIndex(int idx) {
    // Match the original label key order: 0=general,1=pill,2=food,3=cosmetics,4=cleaning,5=biotech,6=health,7=kit,8=electronics
    switch (idx) {
      case 0: return 'icon_label_general';
      case 1: return 'icon_label_pill';
      case 2: return 'icon_label_food';
      case 3: return 'icon_label_cosmetics';
      case 4: return 'icon_label_cleaning';
      case 5: return 'icon_label_biotech';
      case 6: return 'icon_label_health';
      case 7: return 'icon_label_kit';
      case 8: return 'icon_label_electronics';
      case 9: return 'icon_label_biotech';  // medical_information
      case 10: return 'icon_label_pill';    // local_pharmacy
      case 11: return 'icon_label_health';   // healing
      case 12: return 'icon_label_liquid';  // opacity
      case 13: return 'icon_label_health';  // masks
      default: return 'icon_label_general';
    }
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
            final newCategory = v;
            final indices = _categoryIconIndices[newCategory] ?? [0];
            final currentIconInPool = indices.any((idx) => _allIcons[idx].codePoint == _iconCodePoint);
            setState(() {
              _category = newCategory;
              if (!currentIconInPool) {
                final defaultIdx = _defaultIconIndex[newCategory] ?? 0;
                _iconCodePoint = _allIcons[defaultIdx].codePoint;
              }
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
                  decoration: InputDecoration(labelText: '${context.tr('expiry_date')} *', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(
                    '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
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
