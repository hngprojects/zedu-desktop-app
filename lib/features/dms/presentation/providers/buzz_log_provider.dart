import 'package:zedu/core/core.dart';

class BuzzLogEntry {
  final String id;
  final String callerName;
  final DateTime timestamp;
  final bool isMissed;
  final bool isIncoming;

  BuzzLogEntry({
    required this.id,
    required this.callerName,
    required this.timestamp,
    required this.isMissed,
    required this.isIncoming,
  });
}

class BuzzLogState {
  final List<BuzzLogEntry> logs;
  final int missedCount;

  const BuzzLogState({this.logs = const [], this.missedCount = 0});

  BuzzLogState copyWith({List<BuzzLogEntry>? logs, int? missedCount}) {
    return BuzzLogState(
      logs: logs ?? this.logs,
      missedCount: missedCount ?? this.missedCount,
    );
  }
}

class BuzzLogNotifier extends Notifier<BuzzLogState> {
  @override
  BuzzLogState build() {
    return const BuzzLogState();
  }

  void addLog(BuzzLogEntry entry) {
    final updatedLogs = [entry, ...state.logs];
    final updatedMissed = state.missedCount + (entry.isMissed ? 1 : 0);
    state = state.copyWith(logs: updatedLogs, missedCount: updatedMissed);
  }

  void clearMissedBadge() {
    state = state.copyWith(missedCount: 0);
  }
}

final buzzLogProvider = NotifierProvider<BuzzLogNotifier, BuzzLogState>(
  BuzzLogNotifier.new,
);
