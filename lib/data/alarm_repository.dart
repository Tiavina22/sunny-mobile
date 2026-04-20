import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';

class AlarmRepository {
  static const String _storageKey = 'alarms_v1';

  Future<List<Alarm>> loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_storageKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<Alarm> alarms = decoded
        .map((dynamic item) => Alarm.fromJson(item as Map<String, dynamic>))
        .toList();

    alarms.sort(_sortByTimeThenId);
    return alarms;
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      alarms.map((Alarm alarm) => alarm.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<Alarm>> addAlarm(Alarm alarm) async {
    final List<Alarm> alarms = await loadAlarms();
    alarms.add(alarm);
    alarms.sort(_sortByTimeThenId);
    await saveAlarms(alarms);
    return alarms;
  }

  Future<List<Alarm>> updateAlarm(Alarm updated) async {
    final List<Alarm> alarms = await loadAlarms();
    final int index = alarms.indexWhere((Alarm item) => item.id == updated.id);
    if (index == -1) {
      return alarms;
    }

    alarms[index] = updated;
    alarms.sort(_sortByTimeThenId);
    await saveAlarms(alarms);
    return alarms;
  }

  Future<List<Alarm>> deleteAlarm(String id) async {
    final List<Alarm> alarms = await loadAlarms();
    alarms.removeWhere((Alarm item) => item.id == id);
    await saveAlarms(alarms);
    return alarms;
  }

  int _sortByTimeThenId(Alarm a, Alarm b) {
    if (a.hour != b.hour) {
      return a.hour.compareTo(b.hour);
    }
    if (a.minute != b.minute) {
      return a.minute.compareTo(b.minute);
    }
    return a.id.compareTo(b.id);
  }
}