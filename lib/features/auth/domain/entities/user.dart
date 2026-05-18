import 'package:zedu/features/features.dart';

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
    required this.organisation,
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
  final Organization organisation;

  String get fullname => '$firstName $lastName';
}
