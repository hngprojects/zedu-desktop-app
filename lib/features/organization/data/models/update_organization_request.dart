import 'package:zedu/core/core.dart';

class UpdateOrganizationRequest {
  const UpdateOrganizationRequest({
    required this.orgId,
    this.name,
    this.description,
    this.email,
    this.type,
    this.location,
    this.country,
    this.logoUrl,
    this.logoFile,
    this.removeLogo = false,
  });

  final String orgId;
  final String? name;
  final String? description;
  final String? email;
  final String? type;
  final String? location;
  final String? country;
  final String? logoUrl;
  final XFile? logoFile;
  final bool removeLogo;

  UpdateOrganizationRequest copyWith({
    String? orgId,
    String? name,
    String? description,
    String? email,
    String? type,
    String? location,
    String? country,
    String? logoUrl,
    XFile? logoFile,
    bool? removeLogo,
  }) {
    return UpdateOrganizationRequest(
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      description: description ?? this.description,
      email: email ?? this.email,
      type: type ?? this.type,
      location: location ?? this.location,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      logoFile: logoFile ?? this.logoFile,
      removeLogo: removeLogo ?? this.removeLogo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (email != null) 'email': email,
      if (type != null) 'type': type,
      if (location != null) 'location': location,
      if (country != null) 'country': country,
      if (removeLogo)
        'logo_url': ''
      else if (logoUrl != null)
        'logo_url': logoUrl,
    };
  }
}
