import 'package:flutter/material.dart';

import '../models/alarm_history_entry.dart';
import '../services/alarm_platform_bridge.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AlarmPlatformBridge _platformBridge = AlarmPlatformBridge();

  bool _isLoading = true;
  List<AlarmHistoryEntry> _entries = <AlarmHistoryEntry>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final List<AlarmHistoryEntry> entries = await _platformBridge.getAlarmHistory();
    if (!mounted) {
      return;
    }

    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await _platformBridge.clearAlarmHistory();
    await _loadHistory();
  }

  String _formatDateTime(DateTime value) {
    final String y = value.year.toString();
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    final String h = value.hour.toString().padLeft(2, '0');
    final String min = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: <Widget>[
          IconButton(
            onPressed: _entries.isEmpty ? null : _clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Vider l historique',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Aucun historique pour le moment.'))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      final AlarmHistoryEntry entry = _entries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            'Defi ${entry.challengeType} - ${entry.statusLabel}',
                          ),
                          subtitle: Text(
                            'Debut: ${_formatDateTime(entry.startedAt)}\n'
                            'Duree: ${entry.durationSeconds}s | '
                            'Action: ${entry.actionTaken ? 'oui' : 'non'} | '
                            'Erreurs: ${entry.wrongAttempts}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}