import 'package:share_plus/share_plus.dart';
import '../models/item.dart';

class ShareService {
  static Future<void> shareItem(Item item) async {
    final buffer = StringBuffer();
    buffer.writeln('【物品信息】${item.name}');
    if (item.hasDeadline) {
      final deadlineLabel =
          item.deadlineType == ItemDeadlineType.warranty ? '保修截止' : '有效期至';
      buffer.writeln('$deadlineLabel：${item.formattedDeadlineDate}');
    } else {
      buffer.writeln('期限：无');
    }
    buffer.writeln('状态：${switch (item.status) {
      ItemStatus.expired => 'Expired',
      ItemStatus.warning => 'Expiring Soon',
      ItemStatus.valid => 'Valid',
      ItemStatus.none => 'No Deadline',
    }}');
    if (item.specification != null) buffer.writeln('规格：${item.specification}');
    if (item.batchNumber != null) buffer.writeln('批号：${item.batchNumber}');
    if (item.manufacturer != null) buffer.writeln('厂商：${item.manufacturer}');
    buffer.writeln('');
    buffer.writeln('— 来自到期管家');

    await Share.share(buffer.toString(), subject: '物品信息 - ${item.name}');
  }
}
