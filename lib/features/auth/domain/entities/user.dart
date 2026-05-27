import 'user_status.dart';

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
    this.creditBalance = 0,
    this.subscriptionPlanId = 'free',
    this.aiCreditsPurchasable = true,
    this.status = UserStatus.empty,
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
  final int creditBalance;
  final String subscriptionPlanId;
  final bool aiCreditsPurchasable;

  /// Live presence and custom status for this user.
  final UserStatus status;

  String get fullname => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'username': username,
    'is_verified': isVerified,
    'is_onboarded': isOnboarded,
    'created_at': createdAt.toIso8601String(),
    'current_org': currentOrg,
    'current_organisation_slug': currentOrganisationSlug,
    'avatar_url': avatarUrl,
    'default_avatar_url': defaultAvatarUrl,
    'credit_balance': creditBalance,
    'subscription_plan_id': subscriptionPlanId,
    'ai_credits_purchasable': aiCreditsPurchasable,
    'status': status.toJson(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    firstName: json['first_name'] as String? ?? '',
    lastName: json['last_name'] as String? ?? '',
    email: json['email'] as String,
    phone: json['phone'] as String? ?? '',
    username: json['username'] as String? ?? '',
    isVerified: json['is_verified'] as bool? ?? false,
    isOnboarded: json['is_onboarded'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    currentOrg: json['current_org'] as String? ?? '',
    currentOrganisationSlug: json['current_organisation_slug'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
    defaultAvatarUrl: json['default_avatar_url'] as String? ?? '',
    creditBalance: json['credit_balance'] as int? ?? 0,
    subscriptionPlanId: json['subscription_plan_id'] as String? ?? 'free',
    aiCreditsPurchasable: json['ai_credits_purchasable'] as bool? ?? true,
    status: json['status'] != null
        ? UserStatus.fromJson(json['status'] as Map<String, dynamic>)
        : UserStatus.empty,
  );
}
