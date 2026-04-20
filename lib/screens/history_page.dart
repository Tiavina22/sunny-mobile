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
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: <Widget>[
                    const Text(
                      'Historique',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_entries.isNotEmpty)
                      IconButton(
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        color: const Color(0xFFD7A6FF),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun historique',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _entries.length,
                              itemBuilder: (BuildContext context, int index) {
                                final AlarmHistoryEntry entry = _entries[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3D3551),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Défi ${entry.challengeType} - ${entry.statusLabel}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Début: ${_formatDateTime(entry.startedAt)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                      Text(
                                        'Durée: ${entry.durationSeconds}s | Erreurs: ${entry.wrongAttempts}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
