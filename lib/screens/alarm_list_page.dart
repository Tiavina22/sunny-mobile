import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/alarm_repository.dart';
import '../models/alarm.dart';
import '../services/alarm_platform_bridge.dart';

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends State<AlarmListPage> {
  final AlarmRepository _repository = AlarmRepository();
  final AlarmPlatformBridge _platformBridge = AlarmPlatformBridge();

  bool _isLoading = true;
  List<Alarm> _alarms = <Alarm>[];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final List<Alarm> alarms = await _repository.loadAlarms();
    await _syncNative(alarms);
    if (!mounted) {
      return;
    }

    setState(() {
      _alarms = alarms;
      _isLoading = false;
    });
  }

  Future<void> _addAlarm() async {
    final _CreateAlarmResult? result = await showDialog<_CreateAlarmResult>(
      context: context,
      builder: (BuildContext context) {
        return const _CreateAlarmDialog();
      },
    );

    if (result == null) {
      return;
    }

    final Alarm alarm = Alarm(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hour: result.time.hour,
      minute: result.time.minute,
      enabled: true,
      challengeType: result.challengeType,
      difficulty: result.difficulty,
    );

    final List<Alarm> alarms = await _repository.addAlarm(alarm);
    await _syncNative(alarms);
    if (!mounted) {
      return;
    }
    setState(() {
      _alarms = alarms;
    });
  }

  Future<void> _toggleAlarm(Alarm alarm, bool enabled) async {
    final List<Alarm> alarms = await _repository.updateAlarm(
      alarm.copyWith(enabled: enabled),
    );
    await _syncNative(alarms);
    if (!mounted) {
      return;
    }
    setState(() {
      _alarms = alarms;
    });
  }

  Future<void> _deleteAlarm(String id) async {
    final List<Alarm> alarms = await _repository.deleteAlarm(id);
    await _syncNative(alarms);
    if (!mounted) {
      return;
    }
    setState(() {
      _alarms = alarms;
    });
  }

  Future<void> _syncNative(List<Alarm> alarms) async {
    try {
      await _platformBridge.syncAlarms(alarms);
    } on PlatformException {
      // Keep local experience working even if native sync fails temporarily.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunny Alarm MVP'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? const Center(
                  child: Text('No alarms yet. Tap + to create one.'),
                )
              : ListView.separated(
                  itemCount: _alarms.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Alarm alarm = _alarms[index];
                    return ListTile(
                      leading: Text(
                        alarm.formattedTime,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      title: Text(alarm.challengeType.label),
                      subtitle: Text('Difficulty: ${alarm.difficulty.label}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Switch(
                            value: alarm.enabled,
                            onChanged: (bool value) {
                              _toggleAlarm(alarm, value);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              _deleteAlarm(alarm.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CreateAlarmDialog extends StatefulWidget {
  const _CreateAlarmDialog();

  @override
  State<_CreateAlarmDialog> createState() => _CreateAlarmDialogState();
}

class _CreateAlarmDialogState extends State<_CreateAlarmDialog> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  ChallengeType _challengeType = ChallengeType.math;
  AlarmDifficulty _difficulty = AlarmDifficulty.easy;

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create alarm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text('Time: ${_selectedTime.format(context)}'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ChallengeType>(
            initialValue: _challengeType,
            decoration: const InputDecoration(labelText: 'Challenge'),
            items: ChallengeType.values
                .map(
                  (ChallengeType value) => DropdownMenuItem<ChallengeType>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (ChallengeType? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _challengeType = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AlarmDifficulty>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Difficulty'),
            items: AlarmDifficulty.values
                .map(
                  (AlarmDifficulty value) => DropdownMenuItem<AlarmDifficulty>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (AlarmDifficulty? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _difficulty = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _CreateAlarmResult(
                time: _selectedTime,
                challengeType: _challengeType,
                difficulty: _difficulty,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _CreateAlarmResult {
  const _CreateAlarmResult({
    required this.time,
    required this.challengeType,
    required this.difficulty,
  });

  final TimeOfDay time;
  final ChallengeType challengeType;
  final AlarmDifficulty difficulty;
}