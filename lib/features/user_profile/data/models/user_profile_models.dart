import 'package:zedu/features/features.dart';

class ProfileAccountModel extends ProfileAccount {
  const ProfileAccountModel({
    required super.name,
    required super.email,
    required super.timezone,
    super.avatarUrl,
    super.username,
    super.displayName,
    super.phoneNumber,
    super.title,
    super.namePronunciation,
  });

  factory ProfileAccountModel.fromJson(Map<String, dynamic> json) {
    // The API returns full_name for the user's full name
    final name = (json['full_name'] as String?)?.trim() ??
        (json['name'] as String?)?.trim() ??
        '';
    final email = (json['email'] as String?)?.trim() ?? '';
    final rawUsername = (json['username'] as String?)?.trim() ?? '';
    final displayName = (json['display_name'] as String?)?.trim() ?? '';

    return ProfileAccountModel(
      name: name,
      email: email,
      timezone: (json['timezone'] as String?)?.trim() ?? 'Africa/Lagos',
      avatarUrl: json['avatar_url'] as String?,
      // Derive username from email prefix only if server provides none
      username: rawUsername.isNotEmpty
          ? rawUsername
          : (email.isNotEmpty ? email.split('@').first : ''),
      displayName: displayName,
      phoneNumber: (json['phone'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      namePronunciation:
          (json['name_pronounciation'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': name,
    'email': email,
    'timezone': timezone,
    'avatar_url': avatarUrl,
    'username': username,
    'display_name': displayName,
    'phone': phoneNumber,
    'title': title,
    'name_pronounciation': namePronunciation,
  };
}


class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    required super.mode,
    required super.fromTime,
    required super.toTime,
    required super.useDesktopSettings,
    required super.emailNotifications,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      mode: _modeFromJson(json['mode'] as String?),
      fromTime: json['from_time'] as String? ?? '12:00 AM',
      toTime: json['to_time'] as String? ?? '11:00 PM',
      useDesktopSettings: json['use_desktop_settings'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'from_time': fromTime,
    'to_time': toTime,
    'use_desktop_settings': useDesktopSettings,
    'email_notifications': emailNotifications,
  };

  static NotificationMode _modeFromJson(String? value) {
    return switch (value) {
      'mentionsOnly' || 'mentions_only' => NotificationMode.mentionsOnly,
      'none' => NotificationMode.none,
      _ => NotificationMode.allMessages,
    };
  }
}

class OrganizationProfileModel extends OrganizationProfile {
  const OrganizationProfileModel({
    required super.id,
    required super.name,
    required super.natureOfBusiness,
    required super.country,
    super.logoUrl,
  });

  factory OrganizationProfileModel.fromJson(Map<String, dynamic> json) {
    return OrganizationProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      // Map both type and description to natureOfBusiness since swagger mentions both
      natureOfBusiness: json['type'] as String? ?? 
          json['description'] as String? ?? 
          json['nature_of_business'] as String? ?? '',
      country: json['country'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': natureOfBusiness, // swagger expects description or type
    'type': natureOfBusiness,
    'country': country,
    'logo_url': logoUrl,
  };
}

class SecuritySessionModel extends SecuritySession {
  const SecuritySessionModel({
    required super.device,
    required super.location,
    required super.date,
    required super.lastActive,
    required super.status,
  });

  factory SecuritySessionModel.fromJson(Map<String, dynamic> json) {
    return SecuritySessionModel(
      device: json['device'] as String? ?? 'Chrome',
      location: json['location'] as String? ?? 'Lagos',
      date: json['date'] as String? ?? 'May 8, 2026 1:07 PM',
      lastActive: json['last_active'] as String? ?? 'May 8, 2026 3:07 PM',
      status: json['status'] as String? ?? 'Active',
    );
  }
}

class TeamMemberModel extends TeamMember {
  const TeamMemberModel({
    required super.id,
    required super.email,
    required super.role,
    required super.dateJoined,
    required super.status,
    super.name,
    super.avatarUrl,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as String? ?? 'member-1',
      email: json['email'] as String? ?? 'anonymoususer@gmail.com',
      role: json['role'] as String? ?? 'Administrator',
      dateJoined: json['date_joined'] as String? ?? 'May 3, 2026',
      status: _statusFromJson(json['status'] as String?),
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  static TeamMemberStatus _statusFromJson(String? value) {
    return switch (value) {
      'pending' => TeamMemberStatus.pending,
      'inactive' => TeamMemberStatus.inactive,
      _ => TeamMemberStatus.active,
    };
  }
}

class RolePermissionModel extends RolePermission {
  const RolePermissionModel({
    required super.role,
    required super.description,
    required super.permissions,
  });

  factory RolePermissionModel.fromJson(Map<String, dynamic> json) {
    return RolePermissionModel(
      role: json['role'] as String? ?? 'User',
      description: json['description'] as String? ?? '',
      permissions:
          (json['permissions'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class BillingInfoModel extends BillingInfo {
  const BillingInfoModel({
    required super.plan,
    required super.description,
    super.paymentHistory,
  });

  factory BillingInfoModel.fromJson(Map<String, dynamic> json) {
    return BillingInfoModel(
      plan: json['plan'] as String? ?? 'Zedu Free',
      description: json['description'] as String? ?? '',
      paymentHistory:
          (json['payment_history'] as List<dynamic>?)
              ?.map(
                (e) => PaymentRecordModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

class PaymentRecordModel extends PaymentRecord {
  const PaymentRecordModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    required super.status,
  });

  factory PaymentRecordModel.fromJson(Map<String, dynamic> json) {
    return PaymentRecordModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? 'Subscription Payment',
      amount: json['amount'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
