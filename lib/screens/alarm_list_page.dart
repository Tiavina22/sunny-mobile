import 'dart:async';

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
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _startClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  bool get _isDayTime => _now.hour >= 6 && _now.hour < 18;

  String get _liveTime {
    final String h = _now.hour.toString().padLeft(2, '0');
    final String m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _periodLabel => _isDayTime ? 'Day Mode' : 'Night Mode';

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

  Future<void> _confirmDeleteAlarm(Alarm alarm) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer cette alarme ?'),
          content: Text('L alarme ${alarm.formattedTime} sera supprimee.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteAlarm(alarm.id);
    }
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
                child: _LiveDayNightCard(
                  isDayTime: _isDayTime,
                  liveTime: _liveTime,
                  periodLabel: _periodLabel,
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
                                  onDelete: () => _confirmDeleteAlarm(alarm),
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
            activeThumbColor: const Color(0xFFD7A6FF),
            inactiveThumbColor: const Color(0xFF6E6E6E),
            inactiveTrackColor: const Color(0xFF4A4458),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFFD7A6FF),
            tooltip: 'Supprimer l alarme',
          ),
        ],
      ),
    );
  }
}

class _LiveDayNightCard extends StatelessWidget {
  const _LiveDayNightCard({
    required this.isDayTime,
    required this.liveTime,
    required this.periodLabel,
  });

  final bool isDayTime;
  final String liveTime;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = isDayTime
        ? <Color>[const Color(0xFFFFBB5C), const Color(0xFFFF8A5B)]
        : <Color>[const Color(0xFF5F5B8B), const Color(0xFF2A2343)];

    final IconData icon = isDayTime ? Icons.wb_sunny_rounded : Icons.nightlight_round;

    final String subtitle = isDayTime
        ? 'Le mode jour est actif maintenant'
        : 'Le mode nuit est actif maintenant';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  periodLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'Live',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                liveTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isCompact = screenSize.height < 780;
    final double outerPadding = isCompact ? 20 : 32;
    final double spacingLarge = isCompact ? 20 : 32;
    final double timeBubblePadding = isCompact ? 26 : 40;
    final double timeFontSize = isCompact ? 40 : 48;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      backgroundColor: const Color(0xFF3D3551),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.82),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(outerPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Sleep Time',
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: spacingLarge),
                GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: EdgeInsets.all(timeBubblePadding),
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
                          style: TextStyle(
                            fontSize: timeFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isCompact ? 6 : 8),
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: isCompact ? 28 : 32,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacingLarge),
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
                SizedBox(height: spacingLarge),
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
