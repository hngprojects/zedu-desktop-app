class ProfileAccount {
  const ProfileAccount({
    required this.name,
    required this.email,
    required this.timezone,
    this.avatarUrl,
    this.displayName = '',
    this.username = '',
    this.phoneNumber = '',
    this.title = '',
    this.namePronunciation = '',
    this.country = '',
  });

  factory ProfileAccount.empty() => const ProfileAccount(
    name: '',
    email: '',
    timezone: 'Africa/Lagos',
  );

  final String name;
  final String email;
  final String timezone;
  final String? avatarUrl;
  final String displayName;
  final String username;
  final String phoneNumber;
  final String title;
  final String namePronunciation;
  final String country;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'ZU';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  ProfileAccount copyWith({
    String? name,
    String? email,
    String? timezone,
    String? avatarUrl,
    String? displayName,
    String? username,
    String? phoneNumber,
    String? title,
    String? namePronunciation,
    String? country,
  }) {
    final e = email ?? this.email;
    final u = username ?? this.username;
    
    return ProfileAccount(
      name: name ?? this.name,
      email: e,
      timezone: timezone ?? this.timezone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      displayName: displayName ?? this.displayName,
      username: u.isNotEmpty ? u : e.split('@').first,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      title: title ?? this.title,
      namePronunciation: namePronunciation ?? this.namePronunciation,
      country: country ?? this.country,
    );
  }
}
