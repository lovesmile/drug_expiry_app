import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'database_service.dart';

class BarcodeResult {
  final String? name;
  final String? genericName;
  final String? manufacturer;
  final String? specification;
  final String? approvalNumber;
  final bool fromCache;

  BarcodeResult({
    this.name,
    this.genericName,
    this.manufacturer,
    this.specification,
    this.approvalNumber,
    this.fromCache = false,
  });

  bool get isSuccess => name != null && name!.isNotEmpty;

  Map<String, String?> toMap() => {
        'name': name,
        'generic_name': genericName,
        'manufacturer': manufacturer,
        'specification': specification,
        'approval_number': approvalNumber,
      };
}

/// 条码查询服务
///
/// 策略：本地缓存 → API轮询 → 用户手动录入
/// 缓存永久有效，每个条码只需查一次API。
///
/// API 源（自动轮询）：
/// 1. 阿里云市场（5000次/天免费，国内药品）：申请 https://market.aliyun.com/apimarket/detail/cmapi011032
/// 2. Open Food Facts（完全免费，无需Key）：https://world.openfoodfacts.org/
///
class BarcodeService {
  static final DatabaseService _db = DatabaseService();

  /// 阿里云市场 AppCode（5000次/天免费）
  /// 申请地址：https://market.aliyun.com/apimarket/detail/cmapi011032
  /// 订阅后进入"我的->API凭证"查看 AppCode
  static const String _aliyunAppCode = '8b992c8c7c7d4bdf89c2d0bdabcdd5f0';

  /// 查询条码：本地缓存 → API(多源轮询) → 返回结果
  static Future<BarcodeResult> lookup(String barcode) async {
    // 1. 查本地缓存
    final cached = await _db.getCachedBarcode(barcode);
    if (cached != null && cached['name'] != null) {
      return BarcodeResult(
        name: cached['name'],
        genericName: cached['generic_name'],
        manufacturer: cached['manufacturer'],
        specification: cached['specification'],
        fromCache: true,
      );
    }

    // 2. API 轮询
    BarcodeResult? result;

    // 阿里云市场（5000次/天）
    if (_aliyunAppCode != '8b992c8c7c7d4bdf89c2d0bdabcdd5f0') {
      result = await _lookupAliyun(barcode);
    }

    // Open Food Facts（完全免费，无需Key，作为备选）
    if (result == null || !result.isSuccess) {
      result = await _lookupOpenFoodFacts(barcode);
    }

    if (result.isSuccess) {
      await _db.cacheBarcode(barcode, result.toMap());
    }

    return result;
  }

  /// 阿里云市场（5000次/天免费，国内商品/药品）
  static Future<BarcodeResult> _lookupAliyun(String barcode) async {
    try {
      final r = await http.get(
        Uri.parse('https://barcode14.market.alicloudapi.com/barcode?code=$barcode'),
        headers: {'Authorization': 'APPCODE $_aliyunAppCode'},
      ).timeout(const Duration(seconds: 8));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == '0' && data['result'] != null) {
          final d = data['result'] as Map<String, dynamic>;
          return BarcodeResult(
            name: d['name'] as String? ?? d['goodsname'] as String?,
            manufacturer: d['enterprise'] as String?,
            specification: d['spec'] as String?,
          );
        }
      }
    } catch (_) {}
    return BarcodeResult();
  }

  /// Open Food Facts（完全免费，无需注册，国际条码+部分国内数据）
  static Future<BarcodeResult> _lookupOpenFoodFacts(String barcode) async {
    try {
      final r = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
        headers: {'User-Agent': 'ExpiryTracker/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] != null) {
          final p = data['product'] as Map<String, dynamic>;
          final name = (p['product_name_zh'] ?? p['product_name']) as String?;
          return BarcodeResult(
            name: name,
            manufacturer: p['brands'] as String?,
            specification: p['quantity'] as String?,
          );
        }
      }
    } catch (_) {}
    return BarcodeResult();
  }

  /// 手动保存条码信息到缓存（用户贡献数据）
  static Future<void> saveManual({
    required String barcode,
    required String name,
    String? genericName,
    String? manufacturer,
    String? specification,
  }) async {
    await _db.cacheBarcode(barcode, {
      'name': name,
      'generic_name': genericName,
      'manufacturer': manufacturer,
      'specification': specification,
    });
  }

  /// 构建缓存 JSON 字符串（由调用方通过 SAF 保存到用户可见位置）
  static Future<String> buildCacheJson() async {
    final db = await DatabaseService.database;
    final rows = await db.query(AppStrings.barcodeCacheTable);
    return jsonEncode(rows);
  }

  /// 从 JSON 文件导入缓存（接收家人分享）：用 INSERT OR IGNORE 区分新增与跳过。
  /// 返回 {'added': 新插入条数, 'skipped': 已存在条数}。
  static Future<Map<String, int>> importCache(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return {'added': 0, 'skipped': 0};
    final data = jsonDecode(await file.readAsString()) as List;
    int added = 0;
    int skipped = 0;
    for (final row in data) {
      final barcode = row['barcode'] as String?;
      if (barcode == null) continue;
      final id = await _db.insertCacheIfMissing(barcode, {
        'name': row['name'] as String?,
        'generic_name': row['generic_name'] as String?,
        'manufacturer': row['manufacturer'] as String?,
        'specification': row['specification'] as String?,
      });
      if (id > 0) {
        added++;
      } else {
        skipped++;
      }
    }
    return {'added': added, 'skipped': skipped};
  }

  static Future<void> clearCache() => _db.clearBarcodeCache();
  static Future<int> getCacheCount() => _db.getBarcodeCacheCount();
}
