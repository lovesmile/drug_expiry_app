import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../models/item.dart';
import '../models/family_member.dart';
import 'database_service.dart';

class DiscoveredDevice {
  final String endpointId;
  final String name;
  DiscoveredDevice(this.endpointId, this.name);
}

class NearbyService {
  static final NearbyService _instance = NearbyService._();
  NearbyService._() {
    _nearby = Nearby();
  }
  factory NearbyService() => _instance;

  late final Nearby _nearby;
  final DatabaseService _db = DatabaseService();

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final List<DiscoveredDevice> _discovered = [];

  /// 收到对端数据回调
  void Function(String endpointId, Map<String, dynamic> data)? onDataReceived;

  /// 发现/丢失设备回调
  VoidCallback? onDeviceListChanged;

  /// 状态变化回调
  VoidCallback? onStateChanged;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  List<DiscoveredDevice> get discoveredDevices => List.unmodifiable(_discovered);

  Future<bool> requestPermissions() async {
    // nearby_connections 4.3.0 不内置权限请求,
    // 权限已在 AndroidManifest.xml 声明，运行时由系统弹窗
    return true;
  }

  Future<void> startDiscovery(String deviceName) async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    onStateChanged?.call();

    try {
      await _nearby.startDiscovery(
        deviceName,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          if (!_discovered.any((d) => d.endpointId == endpointId)) {
            _discovered.add(DiscoveredDevice(endpointId, endpointName));
            onDeviceListChanged?.call();
          }
        },
        onEndpointLost: (endpointId) {
          _discovered.removeWhere((d) => d.endpointId == endpointId);
          onDeviceListChanged?.call();
        },
      );
    } catch (e) {
      _isDiscovering = false;
      onStateChanged?.call();
      debugPrint('Nearby startDiscovery error: $e');
    }
  }

  Future<void> startAdvertising(String deviceName) async {
    if (_isAdvertising) return;
    _isAdvertising = true;
    onStateChanged?.call();

    try {
      await _nearby.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          debugPrint('Advert connection result: $endpointId $status');
        },
        onDisconnected: (endpointId) {
          _discovered.removeWhere((d) => d.endpointId == endpointId);
          onDeviceListChanged?.call();
        },
      );
    } catch (e) {
      _isAdvertising = false;
      onStateChanged?.call();
      debugPrint('Nearby startAdvertising error: $e');
    }
  }

  Future<void> requestConnection(String endpointId, String deviceName) async {
    try {
      await _nearby.requestConnection(
        deviceName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          debugPrint('Discover connection result: $endpointId $status');
        },
        onDisconnected: (endpointId) {
          _discovered.removeWhere((d) => d.endpointId == endpointId);
          onDeviceListChanged?.call();
        },
      );
    } catch (e) {
      debugPrint('Nearby requestConnection error: $e');
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _nearby.acceptConnection(
      endpointId,
      onPayLoadRecieved: (String epId, Payload payload) {
        _handlePayload(epId, payload);
      },
    );
  }

  void _handlePayload(String endpointId, Payload payload) {
    if (payload.bytes == null || payload.bytes!.isEmpty) return;
    try {
      final json = utf8.decode(payload.bytes!);
      final data = jsonDecode(json) as Map<String, dynamic>;
      onDataReceived?.call(endpointId, data);
    } catch (e) {
      debugPrint('Payload decode error: $e');
    }
  }

  Future<void> sendData(String endpointId, Map<String, dynamic> data) async {
    try {
      final json = jsonEncode(data);
      final bytes = Uint8List.fromList(json.codeUnits);
      await _nearby.sendBytesPayload(endpointId, bytes);
    } catch (e) {
      debugPrint('Nearby sendData error: $e');
    }
  }

  /// 发起同步：向对端发送本机数据（主动方）
  Future<void> syncTo(String endpointId) async {
    final items = await _db.getAllItems();
    final members = await _db.getAllFamilyMembers();
    await sendData(endpointId, {
      'type': 'full_sync',
      'device_name': '我的设备',
      'items': items.map((i) => i.toMap()).toList(),
      'members': members.map((m) => m.toMap()).toList(),
    });
  }

  /// 回应同步：向对端回传本机数据（被动方）
  Future<void> syncBackTo(String endpointId) async {
    final items = await _db.getAllItems();
    final members = await _db.getAllFamilyMembers();
    await sendData(endpointId, {
      'type': 'sync_back',
      'device_name': '我的设备',
      'items': items.map((i) => i.toMap()).toList(),
      'members': members.map((m) => m.toMap()).toList(),
    });
  }

  /// 将收到的数据合并到本地数据库
  Future<Map<String, int>> mergeReceivedData(Map<String, dynamic> data) async {
    int itemsAdded = 0;
    int membersAdded = 0;

    if (data['items'] is List) {
      for (final d in (data['items'] as List).cast<Map<String, dynamic>>()) {
        try {
          final item = Item.fromMap(d);
          final existing = await _db.searchItems(item.name);
          final dup = existing.any((e) =>
              e.expiryDate == item.expiryDate && e.name == item.name);
          if (!dup) {
            await _db.insertItem(item);
            itemsAdded++;
          }
        } catch (_) {}
      }
    }

    if (data['members'] is List) {
      for (final m in (data['members'] as List).cast<Map<String, dynamic>>()) {
        try {
          final member = FamilyMember.fromMap(m);
          final existing = await _db.getAllFamilyMembers();
          if (!existing.any((e) => e.name == member.name)) {
            await _db.insertFamilyMember(member);
            membersAdded++;
          }
        } catch (_) {}
      }
    }

    return {'items': itemsAdded, 'members': membersAdded};
  }

  void stopAll() {
    try {
      _nearby.stopAdvertising();
    } catch (_) {}
    try {
      _nearby.stopDiscovery();
    } catch (_) {}
    _isAdvertising = false;
    _isDiscovering = false;
    onStateChanged?.call();
  }

  void stopEndpoints() {
    try {
      _nearby.stopAllEndpoints();
    } catch (_) {}
  }

  void disconnect(String endpointId) {
    try {
      _nearby.disconnectFromEndpoint(endpointId);
    } catch (_) {}
    _discovered.removeWhere((d) => d.endpointId == endpointId);
    onDeviceListChanged?.call();
  }
}
