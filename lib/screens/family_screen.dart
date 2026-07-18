import 'package:flutter/material.dart';
import 'dart:async';
import '../design/app_colors.dart';
import '../services/nearby_service.dart';
import '../l10n/app_localizations.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final NearbyService _nearby = NearbyService();
  bool _scanning = false;
  bool _syncing = false;
  String _statusText = '';
  String _statusDetail = '';
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _statusText = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _statusText = context.tr('discovery_start'));
    });
    _nearby.onDeviceListChanged = () {
      if (mounted) setState(_updateStatusAfterDiscovery);
    };
    _nearby.onStateChanged = () {
      if (mounted) setState(() {});
    };
    _nearby.onDataReceived = (endpointId, data) {
      _handleReceivedData(endpointId, data);
    };
  }

  @override
  void dispose() {
    // 先清空回调，避免 stopAll() 内部触发的回调对 defunct element 调 setState
    // 报错：'_lifecycleState != _ElementLifecycle.defunct': is not true
    _nearby.onDeviceListChanged = null;
    _nearby.onStateChanged = null;
    _nearby.onDataReceived = null;
    _nearby.stopAll();
    _scanTimer?.cancel();
    super.dispose();
  }

  void _updateStatusAfterDiscovery() {
    final count = _nearby.discoveredDevices.length;
    if (count > 0) {
      _statusText = context.tr('discovery_found', {'count': count.toString()});
      _statusDetail = context.tr('discovery_connect_detail');
    } else {
      _statusText = context.tr('discovery_no_device');
      _statusDetail = context.tr('discovery_detail');
    }
  }

  Future<void> _toggleScan() async {
    if (_scanning) {
      _nearby.stopAll();
      _scanTimer?.cancel();
      setState(() {
        _scanning = false;
        _statusText = context.tr('discovery_start');
        _statusDetail = '';
      });
      return;
    }

    setState(() {
      _statusText = context.tr('loading');
      _statusDetail = context.tr('loading');
    });

    const deviceName = '鍒版湡绠″';
    await _nearby.startAdvertising(deviceName);
    await _nearby.startDiscovery(deviceName);
    setState(() {
      _scanning = true;
      _statusText = context.tr('discovery_no_device');
      _statusDetail = context.tr('discovery_detail');
    });

    // Auto-stop after 30 seconds
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_scanning) return;
      _nearby.stopAll();
      setState(() {
        _scanning = false;
        _statusText = context.tr('discovery_timeout');
        _statusDetail = '';
      });
    });
  }

  Future<void> _connectAndSync(DiscoveredDevice device) async {
    final deviceName = device.name;
    setState(() {
      _syncing = true;
      _statusText = context.tr('connecting', {'device': deviceName});
      _statusDetail = context.tr('loading');
    });

    await _nearby.requestConnection(device.endpointId, '鍒版湡绠″');

    setState(() {
      _statusText = context.tr('sending', {'device': deviceName});
      _statusDetail = context.tr('waiting_reply');
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await _nearby.syncTo(device.endpointId);
  }

  Future<void> _handleReceivedData(
      String endpointId, Map<String, dynamic> data) async {
    if (data['type'] != 'full_sync' && data['type'] != 'sync_back') return;

    final isFirstContact = data['type'] == 'full_sync';
    final fromDevice = data['device_name'] as String? ?? '瀵规柟';

    setState(() {
      _statusText = isFirstContact
          ? context.tr('receiving_from', {'device': fromDevice})
          : context.tr('sent_to', {'device': fromDevice});
      _statusDetail = context.tr('merging');
    });

    if (isFirstContact) {
      await _nearby.syncBackTo(endpointId);
    }

    final result = await _nearby.mergeReceivedData(data);

    if (isFirstContact) {
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      final drugCount = result['items'] ?? 0;

      setState(() {
        _syncing = false;
        _statusText = context.tr('sync_complete');
        _statusDetail = context.tr('share_sync_result', {'count': drugCount.toString()});
        _scanning = false;
      });
      _nearby.stopAll();
      _nearby.disconnect(endpointId);
    }
  }

  void _showHotspotTips() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_tethering, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(context.tr('connection_tips_title'), style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipItem(icon: Icons.wifi, text: context.tr('connection_tips_wifi')),
            const SizedBox(height: 12),
            _TipItem(icon: Icons.wifi_tethering, text: context.tr('connection_tips_hotspot')),
            const SizedBox(height: 12),
            _TipItem(icon: Icons.warning_amber_outlined, text: context.tr('connection_tips_note')),
            const SizedBox(height: 12),
            _TipItem(icon: Icons.info_outline, text: context.tr('connection_tips_info')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('got_it'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.tr('share_title')),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(_scanning ? Icons.wifi_find : Icons.wifi_tethering),
                color: _scanning ? Theme.of(context).colorScheme.primary : null,
                onPressed: _toggleScan,
                tooltip: _scanning ? context.tr('stop_search') : context.tr('discover_devices'),
              ),
              if (_syncing)
                const Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_scanning && _statusText.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_tethering, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(context.tr('share_empty_title'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(context.tr('share_empty_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: Icon(Icons.search),
                label: Text(context.tr('discover_devices')),
                onPressed: _toggleScan,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        if (_scanning) _buildNearbyDevices(),
        if (_statusText.isNotEmpty) const SizedBox(height: 8),
        if (_statusText.isNotEmpty) _buildStatusCard(),
      ],
    );
  }

  Widget _buildNearbyDevices() {
    final devices = _nearby.discoveredDevices;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Icon(Icons.wifi_find, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  context.tr('nearby_devices', {'count': devices.length.toString()}),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showHotspotTips,
                  child: Icon(Icons.help_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          if (devices.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Text(context.tr('discovery_no_device'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            ...devices.map((d) => ListTile(
                  dense: true,
                  leading: Icon(Icons.phone_android, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  title: Text(d.name, style: TextStyle(fontSize: 14)),
                  trailing: _syncing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : FilledButton.icon(
                          icon: Icon(Icons.sync, size: 16),
                          label: Text(context.tr('sync'), style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _connectAndSync(d),
                        ),
                  onTap: () => _connectAndSync(d),
                )),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final semantic = context.semantic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: semantic.statusValidContainer,
        borderRadius: AppRadius.small,
      ),
      child: Row(
        children: [
          _syncing
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: semantic.onStatusValidContainer))
              : Icon(Icons.info_outline, size: 16, color: semantic.onStatusValidContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_statusText,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: semantic.onStatusValidContainer)),
                if (_statusDetail.isNotEmpty)
                  Text(_statusDetail, style: TextStyle(fontSize: 11, color: semantic.onStatusValidContainer.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4)),
        ),
      ],
    );
  }
}
