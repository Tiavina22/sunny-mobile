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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2E283F),
              Color(0xFF3D3551),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFFFFBB5C), Color(0xFFFEAD08)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFFFEAD08).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🌙',
                        style: TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Sleep Time',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Alarms',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFD7A6FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _alarms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3D3551),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.alarm_off,
                                    size: 80,
                                    color: Color(0xFFD7A6FF),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Aucune alarme',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Appuyez sur + pour créer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _alarms.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Alarm alarm = _alarms[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _AlarmCard(
                                  alarm: alarm,
                                  onToggle: (bool value) => _toggleAlarm(alarm, value),
                                  onDelete: () => _deleteAlarm(alarm.id),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: const Color(0xFFD7A6FF),
        child: const Icon(Icons.add, color: Color(0xFF2E283F)),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3551),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alarm.formattedTime,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: alarm.enabled ? Colors.white : const Color(0xFF6E6E6E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alarm.challengeType.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: alarm.enabled,
            onChanged: onToggle,
            activeColor: const Color(0xFFD7A6FF),
            inactiveThumbColor: const Color(0xFF6E6E6E),
            inactiveTrackColor: const Color(0xFF4A4458),
          ),
        ],
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

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF3D3551),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Sleep Time',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFD7A6FF), Color(0xFFB88FE8)],
                  ),
                  borderRadius: BorderRadius.circular(150),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFD7A6FF).withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E283F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<ChallengeType>(
                value: _challengeType,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E283F),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: ChallengeType.values
                    .map(
                      (ChallengeType value) => DropdownMenuItem<ChallengeType>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (ChallengeType? value) {
                  if (value != null) {
                    setState(() => _challengeType = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E283F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<AlarmDifficulty>(
                value: _difficulty,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E283F),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: AlarmDifficulty.values
                    .map(
                      (AlarmDifficulty value) => DropdownMenuItem<AlarmDifficulty>(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (AlarmDifficulty? value) {
                  if (value != null) {
                    setState(() => _difficulty = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E283F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _CreateAlarmResult(
                          time: _selectedTime,
                          challengeType: _challengeType,
                          difficulty: _difficulty,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFD7A6FF),
                      foregroundColor: const Color(0xFF2E283F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
