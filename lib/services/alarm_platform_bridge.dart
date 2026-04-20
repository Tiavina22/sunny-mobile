import 'package:flutter/services.dart';

import '../models/alarm.dart';

class AlarmPlatformBridge {
  static const MethodChannel _channel = MethodChannel('sunny/alarm');

  Future<void> syncAlarms(List<Alarm> alarms) async {
    final List<Map<String, dynamic>> payload = alarms
        .map((Alarm alarm) => alarm.toJson())
        .toList();

    await _channel.invokeMethod<void>('syncAlarms', payload);
  }
}