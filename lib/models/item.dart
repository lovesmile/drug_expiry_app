import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ItemStatus { valid, warning, expired, none }

enum ItemDeadlineType { expiry, warranty, none }

enum WarrantyStatus { none, valid, warning, expired }

enum UsageStatus { active, usedUp, discarded }

enum ItemCategory { drug, food, cosmetic, dailyNecessity, electronics, other }

class Item {
  static final DateTime _legacyNoDeadlineDate = DateTime(9999, 12, 31);

  // 用户在「添加/编辑物品」页可从 14 个固定图标里选，codePoint 落库后
  // 在此用 const 列表反查 IconData。**禁止**直接 `IconData(codePoint, ...)`，
  // 否则 AOT tree-shake-icons 阶段会因非 const 构造报错，并强迫加
  // `--no-tree-shake-icons`，而该 flag 在 NDK 28 上又触发 strip 工具链失败。
  // 见 add_edit_item_screen._allIcons —— 两处枚举保持同步。
  static const List<IconData> _iconLookup = [
    Icons.medication, // 0
    Icons.restaurant, // 1
    Icons.local_drink, // 2
    Icons.face, // 3
    Icons.science, // 4
    Icons.devices, // 5
    Icons.inventory_2, // 6
    Icons.category, // 7
    Icons.health_and_safety, // 8
    Icons.local_pharmacy, // 9
    Icons.opacity, // 10
    Icons.spa, // 11
    Icons.grain, // 12
    Icons.water_drop, // 13
  ];

  IconData resolveIcon(int codePoint) {
    for (final icon in _iconLookup) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.inventory_2;
  }

  final int? id;
  final String name;
  final String? subtitle;
  final String? specification;
  final String? batchNumber;
  final String? manufacturer;
  final DateTime? expiryDate;
  final ItemDeadlineType deadlineType;
  final String? photoPath;
  final int iconCodePoint;
  final UsageStatus usageStatus;
  final ItemCategory category;
  final DateTime? purchaseDate;
  final int? warrantyMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    this.id,
    required this.name,
    this.subtitle,
    this.specification,
    this.batchNumber,
    this.manufacturer,
    this.expiryDate,
    this.deadlineType = ItemDeadlineType.expiry,
    this.photoPath,
    int? iconCodePoint,
    this.usageStatus = UsageStatus.active,
    this.category = ItemCategory.drug,
    this.purchaseDate,
    this.warrantyMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : iconCodePoint = (iconCodePoint != null && iconCodePoint != 0)
            ? iconCodePoint
            : Icons.inventory_2.codePoint,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 改成查 const 映射，让 IconData() 始终在 const 上下文中构造。
  // Flutter AOT 的 tree-shake-icons 阶段禁止运行时动态 IconData() 调用，
  // 否则会保留完整 icons font 并阻断打包；之前用 `IconData(iconCodePoint, ...)`
  // 直接 new 因此构建必须加 --no-tree-shake-icons，但该 flag 又会触发 NDK strip
  // 工具链报错。改成 const Map 后可以走默认构建路径。
  IconData get icon => resolveIcon(iconCodePoint);

  DateTime? get deadlineDate {
    // 电子产品优先保修期：录入时若同时有有效期+保修，按保修追踪更直观。
    if (category == ItemCategory.electronics && warrantyEndDate != null) {
      return warrantyEndDate;
    }
    switch (deadlineType) {
      case ItemDeadlineType.expiry:
        return expiryDate;
      case ItemDeadlineType.warranty:
        return warrantyEndDate;
      case ItemDeadlineType.none:
        return null;
    }
  }

  /// 实际生效的 deadline 类型，受电子产品保修优先规则影响。
  /// UI 用它来选择图标 / 标签，避免与 deadlineDate 不一致。
  ItemDeadlineType get effectiveDeadlineType {
    if (category == ItemCategory.electronics && warrantyEndDate != null) {
      return ItemDeadlineType.warranty;
    }
    return deadlineType;
  }

  bool get hasDeadline => deadlineDate != null;

  ItemStatus get status {
    if (deadlineType == ItemDeadlineType.none) return ItemStatus.none;
    if (deadlineType == ItemDeadlineType.warranty) {
      return switch (warrantyStatus) {
        WarrantyStatus.valid => ItemStatus.valid,
        WarrantyStatus.warning => ItemStatus.warning,
        WarrantyStatus.expired => ItemStatus.expired,
        WarrantyStatus.none => ItemStatus.none,
      };
    }

    final date = expiryDate;
    if (date == null) return ItemStatus.none;
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return ItemStatus.expired;
    if (diff <= 30) return ItemStatus.warning;
    return ItemStatus.valid;
  }

  int? get daysLeft {
    final date = deadlineDate;
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  DateTime? get warrantyEndDate {
    if (purchaseDate == null ||
        warrantyMonths == null ||
        warrantyMonths! <= 0) {
      return null;
    }

    final targetMonth = DateTime(
      purchaseDate!.year,
      purchaseDate!.month + warrantyMonths!,
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = purchaseDate!.day > lastDay ? lastDay : purchaseDate!.day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      day,
      purchaseDate!.hour,
      purchaseDate!.minute,
      purchaseDate!.second,
    );
  }

  WarrantyStatus get warrantyStatus {
    final endDate = warrantyEndDate;
    if (endDate == null) return WarrantyStatus.none;

    final diff = endDate.difference(DateTime.now()).inDays;
    if (diff < 0) return WarrantyStatus.expired;
    if (diff <= 30) return WarrantyStatus.warning;
    return WarrantyStatus.valid;
  }

  int? get warrantyDaysLeft {
    final endDate = warrantyEndDate;
    return endDate?.difference(DateTime.now()).inDays;
  }

  String get formattedExpiryDate => _formatDate(expiryDate);

  String get formattedDeadlineDate => _formatDate(deadlineDate);

  String? get formattedPurchaseDate => _formatNullableDate(purchaseDate);

  String? get formattedWarrantyEndDate => _formatNullableDate(warrantyEndDate);

  bool get hasWarranty => warrantyEndDate != null;

  static String _formatDate(DateTime? date) {
    return _formatNullableDate(date) ?? '-';
  }

  static String? _formatNullableDate(DateTime? date) {
    return date == null ? null : DateFormat('yyyy-MM-dd').format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'generic_name': subtitle,
      'specification': specification,
      'batch_number': batchNumber,
      'manufacturer': manufacturer,
      'expiry_date': DateFormat('yyyy-MM-dd').format(
        expiryDate ?? _legacyNoDeadlineDate,
      ),
      'deadline_type': deadlineType.name,
      'photo_path': photoPath,
      'icon_code_point': iconCodePoint,
      'usage_status': usageStatus.name,
      'category': category.name,
      'purchase_date': purchaseDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(purchaseDate!),
      'warranty_months': warrantyMonths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateFormat('yyyy-MM-dd').parse(value);
      }
      return null;
    }

    final purchaseDate = parseDate(map['purchase_date']);
    final warrantyMonths = map['warranty_months'] as int?;
    final rawDeadlineType = map['deadline_type'] as String?;
    final deadlineType = rawDeadlineType == null
        ? (purchaseDate != null && warrantyMonths != null
            ? ItemDeadlineType.warranty
            : ItemDeadlineType.expiry)
        : ItemDeadlineType.values.firstWhere(
            (type) => type.name == rawDeadlineType,
            orElse: () => ItemDeadlineType.expiry,
          );

    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      subtitle: map['generic_name'] as String?,
      specification: map['specification'] as String?,
      batchNumber: map['batch_number'] as String?,
      manufacturer: map['manufacturer'] as String?,
      expiryDate: deadlineType == ItemDeadlineType.expiry
          ? parseDate(map['expiry_date'])
          : null,
      deadlineType: deadlineType,
      photoPath: map['photo_path'] as String?,
      iconCodePoint: map['icon_code_point'] as int?,
      usageStatus: (map['usage_status'] as String?) == null
          ? UsageStatus.active
          : UsageStatus.values.firstWhere(
              (status) => status.name == map['usage_status'],
              orElse: () => UsageStatus.active,
            ),
      category: (map['category'] as String?) == null
          ? ItemCategory.drug
          : ItemCategory.values.firstWhere(
              (category) => category.name == map['category'],
              orElse: () => ItemCategory.drug,
            ),
      purchaseDate: purchaseDate,
      warrantyMonths: warrantyMonths,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Item copyWith({
    int? id,
    String? name,
    String? subtitle,
    String? specification,
    String? batchNumber,
    String? manufacturer,
    DateTime? expiryDate,
    ItemDeadlineType? deadlineType,
    String? photoPath,
    int? iconCodePoint,
    UsageStatus? usageStatus,
    ItemCategory? category,
    DateTime? purchaseDate,
    int? warrantyMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearExpiryDate = false,
    bool clearPurchaseDate = false,
    bool clearWarrantyMonths = false,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      specification: specification ?? this.specification,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      deadlineType: deadlineType ?? this.deadlineType,
      photoPath: photoPath ?? this.photoPath,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      usageStatus: usageStatus ?? this.usageStatus,
      category: category ?? this.category,
      purchaseDate:
          clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      warrantyMonths:
          clearWarrantyMonths ? null : (warrantyMonths ?? this.warrantyMonths),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
