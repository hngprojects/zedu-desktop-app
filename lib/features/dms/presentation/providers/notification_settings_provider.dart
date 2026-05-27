import 'package:zedu/core/core.dart';

class NotificationSettings {
  final DateTime? dndUntil;
  final Set<String> mutedParticipantIds;
  final Set<String> mutedChannelIds;

  const NotificationSettings({
    this.dndUntil,
    this.mutedParticipantIds = const {},
    this.mutedChannelIds = const {},
  });

  bool get isDndActive => dndUntil != null && dndUntil!.isAfter(DateTime.now());
  bool isMuted(String participantId) =>
      mutedParticipantIds.contains(participantId);
  bool isChannelMuted(String channelId) =>
      mutedChannelIds.contains(channelId);

  NotificationSettings copyWith({
    DateTime? dndUntil,
    Set<String>? mutedParticipantIds,
    Set<String>? mutedChannelIds,
  }) {
    return NotificationSettings(
      dndUntil: dndUntil ?? this.dndUntil,
      mutedParticipantIds: mutedParticipantIds ?? this.mutedParticipantIds,
      mutedChannelIds: mutedChannelIds ?? this.mutedChannelIds,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return const NotificationSettings();
  }

  void setDndMode(Duration duration) {
    state = state.copyWith(dndUntil: DateTime.now().add(duration));
  }

  void clearDndMode() {
    state = NotificationSettings(
      dndUntil: null,
      mutedParticipantIds: state.mutedParticipantIds,
      mutedChannelIds: state.mutedChannelIds,
    );
  }

  void muteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..add(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
  }

  void unmuteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..remove(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
  }

  bool isMuted(String participantId) {
    return state.mutedParticipantIds.contains(participantId);
  }

  void muteChannel(String channelId) {
    final newMuted = Set<String>.from(state.mutedChannelIds)
      ..add(channelId);
    state = state.copyWith(mutedChannelIds: newMuted);
  }

  void unmuteChannel(String channelId) {
    final newMuted = Set<String>.from(state.mutedChannelIds)
      ..remove(channelId);
    state = state.copyWith(mutedChannelIds: newMuted);
  }

  bool isChannelMuted(String channelId) {
    return state.mutedChannelIds.contains(channelId);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
