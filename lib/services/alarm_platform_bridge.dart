import 'package:flutter/services.dart';

import '../models/alarm.dart';
import '../models/alarm_history_entry.dart';

class AlarmPlatformBridge {
  static const MethodChannel _channel = MethodChannel('sunny/alarm');

  Future<void> syncAlarms(List<Alarm> alarms) async {
    final List<Map<String, dynamic>> payload = alarms
        .map((Alarm alarm) => alarm.toJson())
        .toList();

    await _channel.invokeMethod<void>('syncAlarms', payload);
  }

  Future<List<AlarmHistoryEntry>> getAlarmHistory() async {
    final List<dynamic> raw =
        await _channel.invokeMethod<List<dynamic>>('getAlarmHistory') ??
            <dynamic>[];

    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(AlarmHistoryEntry.fromMap)
        .toList();
  }

  Future<void> clearAlarmHistory() async {
    await _channel.invokeMethod<void>('clearAlarmHistory');
  }
}