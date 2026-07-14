import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ItemStatus { valid, warning, expired, none }

enum ItemDeadlineType { expiry, warranty, none }

enum WarrantyStatus { none, valid, warning, expired }

enum UsageStatus { active, usedUp, discarded }

enum ItemCategory { drug, food, cosmetic, dailyNecessity, electronics, other }

class Item {
  static final DateTime _legacyNoDeadlineDate = DateTime(9999, 12, 31);

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

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  DateTime? get deadlineDate {
    switch (deadlineType) {
      case ItemDeadlineType.expiry:
        return expiryDate;
      case ItemDeadlineType.warranty:
        return warrantyEndDate;
      case ItemDeadlineType.none:
        return null;
    }
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
