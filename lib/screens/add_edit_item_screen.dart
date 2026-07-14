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

  const AddEditItemScreen(
      {super.key, this.item, this.initialName, this.barcodeResult});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _ItemIconOption {
  final IconData icon;
  final String labelKey;

  const _ItemIconOption(this.icon, this.labelKey);
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _batchCtrl;
  late final TextEditingController _manufacturerCtrl;
  DateTime? _expiryDate;
  DateTime? _purchaseDate;
  int? _warrantyMonths;
  late ItemDeadlineType _deadlineType;
  late final TextEditingController _warrantyMonthsCtrl;
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
    _nameCtrl = TextEditingController(
        text: d?.name ?? br?.name ?? widget.initialName ?? '');
    _subtitleCtrl =
        TextEditingController(text: d?.subtitle ?? br?.genericName ?? '');
    _specCtrl = TextEditingController(
        text: d?.specification ?? br?.specification ?? '');
    _batchCtrl = TextEditingController(text: d?.batchNumber ?? '');
    _manufacturerCtrl =
        TextEditingController(text: d?.manufacturer ?? br?.manufacturer ?? '');
    _category = d?.category ?? ItemCategory.drug;
    _deadlineType = d?.deadlineType ??
        (_category == ItemCategory.electronics
            ? ItemDeadlineType.warranty
            : ItemDeadlineType.expiry);
    _expiryDate = d?.expiryDate ??
        (_deadlineType == ItemDeadlineType.expiry
            ? DateTime.now().add(const Duration(days: 365))
            : null);
    _purchaseDate = d?.purchaseDate;
    _warrantyMonths = d?.warrantyMonths;
    _warrantyMonthsCtrl = TextEditingController(
      text: _warrantyMonths?.toString() ?? '',
    );
    _iconCodePoint = d?.iconCodePoint ??
        _categoryIconOptions[_category]!.first.icon.codePoint;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _specCtrl.dispose();
    _batchCtrl.dispose();
    _manufacturerCtrl.dispose();
    _warrantyMonthsCtrl.dispose();
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
            _photoOption(ctx, Icons.camera_alt_outlined,
                context.tr('photo_camera'), () => Navigator.pop(ctx, 'camera')),
            _photoOption(
                ctx,
                Icons.photo_library_outlined,
                context.tr('photo_gallery'),
                () => Navigator.pop(ctx, 'gallery')),
            _photoOption(ctx, Icons.delete_outline, context.tr('photo_delete'),
                () => Navigator.pop(ctx, 'delete')),
          ],
        ),
      ),
    );
    if (source == 'camera') {
      final picker = ImagePicker();
      final photo =
          await picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
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

  Widget _photoOption(
      BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    final colors = Theme.of(ctx).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primaryContainer,
            child: Icon(icon, color: colors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  // Default icon index for each category (maps to _allIcons index)
  static const Map<ItemCategory, List<_ItemIconOption>> _categoryIconOptions = {
    ItemCategory.drug: [
      _ItemIconOption(Icons.medication, 'icon_label_pill'),
      _ItemIconOption(Icons.health_and_safety, 'icon_label_health'),
      _ItemIconOption(Icons.local_pharmacy, 'icon_label_capsule'),
      _ItemIconOption(Icons.opacity, 'icon_label_liquid'),
      _ItemIconOption(Icons.air, 'icon_label_spray'),
      _ItemIconOption(Icons.water_drop, 'icon_label_drops'),
    ],
    ItemCategory.food: [
      _ItemIconOption(Icons.restaurant, 'icon_label_food_restaurant'),
      _ItemIconOption(Icons.local_drink, 'icon_label_food_drinks'),
      _ItemIconOption(Icons.kitchen, 'icon_label_food_kitchen'),
      _ItemIconOption(Icons.cake, 'icon_label_food_bakery'),
      _ItemIconOption(Icons.icecream, 'icon_label_food_icecream'),
      _ItemIconOption(Icons.fastfood, 'icon_label_food_fastfood'),
    ],
    ItemCategory.cosmetic: [
      _ItemIconOption(Icons.face, 'icon_label_cosmetic_face'),
      _ItemIconOption(Icons.spa, 'icon_label_cosmetic_spa'),
      _ItemIconOption(Icons.brush, 'icon_label_cosmetic_brush'),
      _ItemIconOption(Icons.color_lens, 'icon_label_cosmetic_color'),
      _ItemIconOption(Icons.shower, 'icon_label_cosmetic_shower'),
      _ItemIconOption(Icons.auto_awesome, 'icon_label_cosmetic_beauty'),
    ],
    ItemCategory.dailyNecessity: [
      _ItemIconOption(Icons.cleaning_services, 'icon_label_daily_cleaning'),
      _ItemIconOption(Icons.home, 'icon_label_daily_home'),
      _ItemIconOption(Icons.shopping_bag, 'icon_label_daily_shopping'),
      _ItemIconOption(Icons.lightbulb, 'icon_label_daily_lighting'),
      _ItemIconOption(Icons.kitchen, 'icon_label_daily_kitchen'),
      _ItemIconOption(Icons.inventory_2, 'icon_label_daily_storage'),
    ],
    ItemCategory.electronics: [
      _ItemIconOption(Icons.devices, 'icon_label_electronics_devices'),
      _ItemIconOption(Icons.phone_android, 'icon_label_electronics_phone'),
      _ItemIconOption(Icons.laptop, 'icon_label_electronics_laptop'),
      _ItemIconOption(Icons.headphones, 'icon_label_electronics_headphones'),
      _ItemIconOption(Icons.watch, 'icon_label_electronics_watch'),
      _ItemIconOption(Icons.router, 'icon_label_electronics_router'),
    ],
    ItemCategory.other: [
      _ItemIconOption(Icons.category, 'icon_label_other_category'),
      _ItemIconOption(Icons.inventory_2, 'icon_label_other_storage'),
      _ItemIconOption(Icons.work_outline, 'icon_label_other_work'),
      _ItemIconOption(Icons.extension, 'icon_label_other_extension'),
      _ItemIconOption(Icons.more_horiz, 'icon_label_other_more'),
      _ItemIconOption(Icons.local_offer, 'icon_label_other_offer'),
    ],
  };

  List<_ItemIconOption> get _iconOptions {
    final options = _categoryIconOptions[_category] ??
        List.generate(
          _allIcons.length,
          (index) =>
              _ItemIconOption(_allIcons[index], _allIconLabelKeys[index]),
        );
    if (options.any((option) => option.icon.codePoint == _iconCodePoint)) {
      return options;
    }

    return [
      ...options,
      _ItemIconOption(
        IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
        'icon_label_general',
      ),
    ];
  }

  // 14 icons mapped to 14 unique label keys (no duplicates)
  // Labels: 药片, 食品, 酒水饮料, 美妆, 日用, 电子, 通用, 其他, 保健, 胶囊, 液体, 喷雾, 颗粒, 滴剂
  static const _allIcons = [
    Icons.medication, // 0  icon_label_pill        药片
    Icons.restaurant, // 1  icon_label_food        食品
    Icons.local_drink, // 2  icon_label_drinks     酒水饮料
    Icons.face, // 3  icon_label_cosmetics   美妆
    Icons.science, // 4  icon_label_biotech     日用
    Icons.devices, // 5  icon_label_electronics  电子
    Icons.inventory_2, // 6  icon_label_general     通用
    Icons.category, // 7  icon_label_other       其他
    Icons.health_and_safety, // 8  icon_label_health      保健
    Icons.local_pharmacy, // 9  icon_label_capsule     胶囊
    Icons.opacity, // 10 icon_label_liquid      液体
    Icons.spa, // 11 icon_label_spray       喷雾
    Icons.grain, // 12 icon_label_granule     颗粒
    Icons.water_drop, // 13 icon_label_drops       滴剂
  ];

  static const _allIconLabelKeys = [
    'icon_label_pill', // 0
    'icon_label_food', // 1
    'icon_label_drinks', // 2
    'icon_label_cosmetics', // 3
    'icon_label_biotech', // 4
    'icon_label_electronics', // 5
    'icon_label_general', // 6
    'icon_label_other', // 7
    'icon_label_health', // 8
    'icon_label_capsule', // 9
    'icon_label_liquid', // 10
    'icon_label_spray', // 11
    'icon_label_granule', // 12
    'icon_label_drops', // 13
  ];

  Widget _buildIconPicker() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(context.tr('icon_picker_title'),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_iconOptions.length, (idx) {
            final option = _iconOptions[idx];
            final icon = option.icon;
            final selected = _iconCodePoint == icon.codePoint;
            return GestureDetector(
              onTap: () => setState(() => _iconCodePoint = icon.codePoint),
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : colors.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: selected
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                        size: 24),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(option.labelKey),
                      style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? colors.onPrimary
                              : colors.onSurfaceVariant),
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
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<ItemCategory>(
        // ignore: deprecated_member_use
        value: _category,
        decoration: InputDecoration(
          labelText: context.tr('category'),
          filled: true,
          fillColor: colors.surfaceContainerLow,
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
              _iconCodePoint = _categoryIconOptions[v]!.first.icon.codePoint;
            });
          }
        },
      ),
    );
  }

  Widget _buildDeadlineSection() {
    final colors = Theme.of(context).colorScheme;
    return _buildSection(context.tr('deadline_section'), [
      DropdownButtonFormField<ItemDeadlineType>(
        initialValue: _deadlineType,
        decoration: InputDecoration(
          labelText: context.tr('deadline_type'),
          filled: true,
          fillColor: colors.surfaceContainerLow,
        ),
        items: [
          DropdownMenuItem(
            value: ItemDeadlineType.expiry,
            child: Text(context.tr('deadline_type_expiry')),
          ),
          DropdownMenuItem(
            value: ItemDeadlineType.warranty,
            child: Text(context.tr('deadline_type_warranty')),
          ),
          DropdownMenuItem(
            value: ItemDeadlineType.none,
            child: Text(context.tr('deadline_type_none')),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _deadlineType = value;
            if (value == ItemDeadlineType.expiry && _expiryDate == null) {
              _expiryDate = DateTime.now().add(const Duration(days: 365));
            }
            if (value == ItemDeadlineType.warranty && _purchaseDate == null) {
              _purchaseDate = DateTime.now();
            }
          });
        },
      ),
      const SizedBox(height: 12),
      if (_deadlineType == ItemDeadlineType.expiry) _buildExpiryFields(),
      if (_deadlineType == ItemDeadlineType.warranty) _buildWarrantyFields(),
      if (_deadlineType == ItemDeadlineType.none)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          ),
          child: Row(
            children: [
              Icon(Icons.all_inclusive, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(context.tr('deadline_none_hint'))),
            ],
          ),
        ),
    ]);
  }

  Widget _buildExpiryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickDateChip(context.tr('quick_3m'), const Duration(days: 90)),
            _quickDateChip(context.tr('quick_6m'), const Duration(days: 180)),
            _quickDateChip(context.tr('quick_1y'), const Duration(days: 365)),
            _quickDateChip(context.tr('quick_2y'), const Duration(days: 730)),
            _quickDateChip(context.tr('quick_3y'), const Duration(days: 1095)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickExpiryDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '${context.tr('expiry_date')} *',
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(_expiryDate)),
          ),
        ),
      ],
    );
  }

  Widget _buildWarrantyFields() {
    return Column(
      children: [
        InkWell(
          onTap: _pickPurchaseDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '${context.tr('purchase_date')} *',
              prefixIcon: const Icon(Icons.shopping_cart_outlined),
            ),
            child: Text(_formatDate(_purchaseDate)),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _warrantyMonthsCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${context.tr('warranty_months')} *',
            prefixIcon: const Icon(Icons.schedule_outlined),
          ),
          onChanged: (value) {
            setState(() => _warrantyMonths = int.tryParse(value));
          },
          validator: (value) {
            if (_deadlineType != ItemDeadlineType.warranty) return null;
            final months = int.tryParse(value ?? '');
            return months == null || months <= 0
                ? context.tr('warranty_months_required')
                : null;
          },
        ),
        if (_warrantyEndDate != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${context.tr('warranty_end_date')}: ${_formatDate(_warrantyEndDate)}',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  Widget _quickDateChip(String label, Duration duration) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      onPressed: () =>
          setState(() => _expiryDate = DateTime.now().add(duration)),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await _pickDate(_expiryDate ?? DateTime.now());
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await _pickDate(_purchaseDate ?? DateTime.now());
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
      locale: Localizations.localeOf(context),
    );
  }

  DateTime? get _warrantyEndDate {
    if (_purchaseDate == null ||
        _warrantyMonths == null ||
        _warrantyMonths! <= 0) {
      return null;
    }
    final targetMonth = DateTime(
      _purchaseDate!.year,
      _purchaseDate!.month + _warrantyMonths!,
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = _purchaseDate!.day > lastDay ? lastDay : _purchaseDate!.day;
    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.tr('not_set');
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadlineType == ItemDeadlineType.expiry && _expiryDate == null) {
      _showDeadlineValidationMessage('expiry_date_required');
      return;
    }
    if (_deadlineType == ItemDeadlineType.warranty &&
        (_purchaseDate == null ||
            _warrantyMonths == null ||
            _warrantyMonths! <= 0)) {
      _showDeadlineValidationMessage('warranty_months_required');
      return;
    }

    // Premium limit check for new items
    if (!_isEditing) {
      final user = context.read<UserProvider>().user;
      if (user != null &&
          !user.isPremium &&
          user.recordCount >= user.recordLimit) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('premium_limit_reached')),
            content: Text(context
                .tr('premium_limit_body')
                .replaceAll('{limit}', user.recordLimit.toString())),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.tr('cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.tr('premium_btn_upgrade'))),
            ],
          ),
        );
        if (ok == true && mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()));
        }
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final item = Item(
        id: widget.item?.id,
        name: _nameCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty
            ? null
            : _subtitleCtrl.text.trim(),
        specification:
            _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
        batchNumber:
            _batchCtrl.text.trim().isEmpty ? null : _batchCtrl.text.trim(),
        manufacturer: _manufacturerCtrl.text.trim().isEmpty
            ? null
            : _manufacturerCtrl.text.trim(),
        expiryDate:
            _deadlineType == ItemDeadlineType.expiry ? _expiryDate : null,
        deadlineType: _deadlineType,
        photoPath: _photoPath ?? widget.item?.photoPath,
        iconCodePoint: _iconCodePoint,
        category: _category,
        purchaseDate:
            _deadlineType == ItemDeadlineType.warranty ? _purchaseDate : null,
        warrantyMonths:
            _deadlineType == ItemDeadlineType.warranty ? _warrantyMonths : null,
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

  void _showDeadlineValidationMessage(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(key))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
          title: Text(_isEditing
              ? context.tr('edit_drug')
              : context.tr('add_drug_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 +
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildSection(context.tr('basic_info'), [
              _buildCategorySelector(),
              _buildTextField(_nameCtrl, context.tr('drug_name'),
                  context.tr('drug_name_hint')),
              _buildTextField(_subtitleCtrl, context.tr('generic_name'),
                  context.tr('generic_name_hint')),
              _buildTextField(_specCtrl, context.tr('specification'),
                  context.tr('spec_hint')),
            ]),
            const SizedBox(height: 16),
            _buildIconPicker(),
            const SizedBox(height: 16),
            _buildSection(context.tr('production_info'), [
              _buildTextField(_batchCtrl, context.tr('batch_number'),
                  context.tr('batch_hint')),
              _buildTextField(_manufacturerCtrl, context.tr('manufacturer'),
                  context.tr('manufacturer_hint')),
            ]),
            const SizedBox(height: 16),
            _buildDeadlineSection(),
            const SizedBox(height: 16),
            _buildSection(context.tr('photo_section'), [
              InkWell(
                onTap: _pickPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.inputRadius),
                          child: Image.file(
                            File(_photoPath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        )
                      : widget.item?.photoPath != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.inputRadius),
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
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: colors.onSurfaceVariant
                                          .withValues(alpha: 0.65)),
                                  SizedBox(height: 4),
                                  Text(context.tr('upload_photo'),
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant
                                              .withValues(alpha: 0.65))),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius)),
              ),
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: colors.onPrimary))
                  : Text(
                      _isEditing
                          ? context.tr('save_changes')
                          : context.tr('add_drug'),
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, String hint) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: colors.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
            borderSide: BorderSide.none,
          ),
        ),
        validator: label.contains('*')
            ? (v) =>
                (v == null || v.trim().isEmpty) ? context.tr('loading') : null
            : null,
      ),
    );
  }
}
