class CreateOrganizationRequest {
  const CreateOrganizationRequest({
    this.name,
    this.description,
    this.email,
    this.type,
    this.location,
    this.country,
    this.logoUrl,
  });

  final String? name;
  final String? description;
  final String? email;
  final String? type;
  final String? location;
  final String? country;
  final String? logoUrl;

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (email != null) 'email': email,
      if (type != null) 'industry': type,
      if (location != null) 'location': location,
      if (country != null) 'country': country,
      if (logoUrl != null) 'logo_url': logoUrl,
    };
  }
}
