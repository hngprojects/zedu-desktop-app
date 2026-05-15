import 'package:zedu/features/features.dart';

class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.email,
    required super.country,
    required super.industry,
    required super.location,
    required super.ownerId,
    required super.logoUrl,
    required super.channelsCount,
    required super.totalMessagesCount,
    required super.userRole,
    required super.organizationPlan,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      email: json['email'] as String? ?? '',
      country: _readCountry(json['country']),
      industry: json['industry'] as String? ?? '',
      location: json['location'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      channelsCount: json['channels_count'] as int? ?? 0,
      totalMessagesCount: json['total_messages_count'] as int? ?? 0,
      userRole: _readUserRole(json['user_role']),
      organizationPlan: OrganizationPlanModel.fromJson(
        _readMap(json['organisation_plan']),
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'email': email,
      'country': country,
      'industry': industry,
      'location': location,
      'owner_id': ownerId,
      'logo_url': logoUrl,
      'channels_count': channelsCount,
      'total_messages_count': totalMessagesCount,
      'user_role': userRole,
      'organisation_plan': (organizationPlan as OrganizationPlanModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String _readCountry(Object? rawCountry) {
    if (rawCountry is String) return rawCountry;
    if (rawCountry is Map) {
      return _firstString(Map<String, dynamic>.from(rawCountry), const [
            'name',
            'country',
            'country_name',
            'display_name',
            'display_name_no_e164_cc',
            'iso2_cc',
            'countryCode',
            'code',
            'value',
          ]) ??
          '';
    }
    return '';
  }

  static String _readUserRole(Object? rawUserRole) {
    if (rawUserRole is String) return rawUserRole;
    if (rawUserRole is Map) {
      return _firstString(
            Map<String, dynamic>.from(rawUserRole),
            const ['name', 'role', 'slug', 'id'],
          ) ??
          '';
    }
    return '';
  }

  static Map<String, dynamic> _readMap(Object? rawValue) {
    if (rawValue is Map) return Map<String, dynamic>.from(rawValue);
    return <String, dynamic>{};
  }

  static String? _firstString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
