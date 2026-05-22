import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ProfileAccount {
  const ProfileAccount({
    required this.name,
    required this.email,
    required this.timezone,
    this.avatarUrl,
  });

  factory ProfileAccount.empty() => const ProfileAccount(
    name: 'Anonymous user',
    email: 'anonymoususer@email.com',
    timezone: 'Africa/Lagos',
  );

  final String name;
  final String email;
  final String timezone;
  final String? avatarUrl;

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
  }) {
    return ProfileAccount(
      name: name ?? this.name,
      email: email ?? this.email,
      timezone: timezone ?? this.timezone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
