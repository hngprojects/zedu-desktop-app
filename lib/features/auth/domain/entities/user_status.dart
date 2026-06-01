class UserStatus {
  const UserStatus({
    this.emoji,
    this.text,
    this.expiresAt,
    this.pauseNotifications = false,
    this.online = true,
  });

  final String? emoji;
  final String? text;
  final DateTime? expiresAt;
  final bool pauseNotifications;

  final bool online;

  bool get hasCustomStatus =>
      emoji != null || (text != null && text!.isNotEmpty);

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  UserStatus copyWith({
    String? emoji,
    String? text,
    DateTime? expiresAt,
    bool clearExpiry = false,
    bool? pauseNotifications,
    bool? online,
  }) {
    return UserStatus(
      emoji: emoji ?? this.emoji,
      text: text ?? this.text,
      expiresAt: clearExpiry ? null : (expiresAt ?? this.expiresAt),
      pauseNotifications: pauseNotifications ?? this.pauseNotifications,
      online: online ?? this.online,
    );
  }

  UserStatus cleared() => UserStatus(online: online);

  static const empty = UserStatus();

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'text': text,
    'expiresAt': expiresAt?.toIso8601String(),
    'pauseNotifications': pauseNotifications,
    'online': online,
  };

  factory UserStatus.fromJson(Map<String, dynamic> json) => UserStatus(
    emoji: json['emoji'] as String?,
    text: json['text'] as String?,
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : null,
    pauseNotifications: json['pauseNotifications'] as bool? ?? false,
    online: json['online'] as bool? ?? true,
  );
}

enum StatusTimeout {
  thirtyMinutes('30 minutes'),
  oneHour('1 hour'),
  today('today'),
  thisWeek('this week'),
  dontRemove("don't remove");

  const StatusTimeout(this.apiValue);

  final String apiValue;

  String get label => switch (this) {
    StatusTimeout.thirtyMinutes => '30 minutes',
    StatusTimeout.oneHour => '1 hour',
    StatusTimeout.today => 'Today',
    StatusTimeout.thisWeek => 'This week',
    StatusTimeout.dontRemove => "Don't remove",
  };
}
