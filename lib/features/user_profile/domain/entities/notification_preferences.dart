enum NotificationMode { allMessages, mentionsOnly, none }

class NotificationPreferences {
  const NotificationPreferences({
    required this.mode,
    required this.fromTime,
    required this.toTime,
    required this.useDesktopSettings,
    required this.emailNotifications,
  });

  final NotificationMode mode;
  final String fromTime;
  final String toTime;
  final bool useDesktopSettings;
  final bool emailNotifications;

  NotificationPreferences copyWith({
    NotificationMode? mode,
    String? fromTime,
    String? toTime,
    bool? useDesktopSettings,
    bool? emailNotifications,
  }) {
    return NotificationPreferences(
      mode: mode ?? this.mode,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      useDesktopSettings: useDesktopSettings ?? this.useDesktopSettings,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }
}
