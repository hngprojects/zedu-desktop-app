// import 'package:zedu/core/core.dart';
class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.username,
    required this.isVerified,
    required this.isOnboarded,
    required this.createdAt,
    required this.currentOrg,
    required this.currentOrganisationSlug,
    required this.avatarUrl,
    required this.defaultAvatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String username;
  final bool isVerified;
  final bool isOnboarded;
  final DateTime createdAt;
  final String currentOrg;
  final String currentOrganisationSlug;
  final String avatarUrl;
  final String defaultAvatarUrl;

  String get fullname => '$firstName $lastName';
}
