class OrganizationProfile {
  const OrganizationProfile({
    required this.id,
    required this.name,
    required this.natureOfBusiness,
    required this.country,
    this.logoUrl,
  });

  factory OrganizationProfile.empty() => const OrganizationProfile(
    id: '',
    name: '',
    natureOfBusiness: '',
    country: '',
  );

  final String id;
  final String name;
  final String natureOfBusiness;
  final String country;
  final String? logoUrl;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'ZO';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  OrganizationProfile copyWith({
    String? id,
    String? name,
    String? natureOfBusiness,
    String? country,
    String? logoUrl,
  }) {
    return OrganizationProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      natureOfBusiness: natureOfBusiness ?? this.natureOfBusiness,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
