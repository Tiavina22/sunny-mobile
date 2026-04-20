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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Text(
          '☀️ Sunny Alarm',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.alarm_off,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune alarme',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour créer une alarme',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _alarms.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Alarm alarm = _alarms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlarmCard(
                        alarm: alarm,
                        onToggle: (bool value) => _toggleAlarm(alarm, value),
                        onDelete: () => _deleteAlarm(alarm.id),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle alarme'),
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

  IconData _getChallengeIcon() {
    switch (alarm.challengeType) {
      case ChallengeType.math:
        return Icons.calculate;
      case ChallengeType.photo:
        return Icons.camera_alt;
      case ChallengeType.quote:
        return Icons.format_quote;
    }
  }

  Color _getDifficultyColor(BuildContext context) {
    switch (alarm.difficulty) {
      case AlarmDifficulty.easy:
        return Colors.green;
      case AlarmDifficulty.medium:
        return Colors.orange;
      case AlarmDifficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: alarm.enabled
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getChallengeIcon(),
                color: alarm.enabled
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alarm.formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: alarm.enabled
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Text(
                        alarm.challengeType.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(context).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          alarm.difficulty.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getDifficultyColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Switch(
              value: alarm.enabled,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Créer une alarme',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ChallengeType>(
              value: _challengeType,
              decoration: InputDecoration(
                labelText: 'Type de défi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<AlarmDifficulty>(
              value: _difficulty,
              decoration: InputDecoration(
                labelText: 'Difficulté',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
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
                  child: const Text('Créer'),
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