import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class CreditPackagesGrid extends StatelessWidget {
  const CreditPackagesGrid({
    super.key,
    required this.packages,
    required this.currentPlanSlug,
    required this.onPurchase,
    this.purchasingPackageId,
  });

  final List<CreditPackage> packages;
  final String? currentPlanSlug;
  final void Function(CreditPackage package) onPurchase;
  final String? purchasingPackageId;

  Color _getColorForPackage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('free')) return const Color(0xFFD1D5DB);
    if (lower.contains('pro plus')) return const Color(0xFFF59E0B);
    if (lower.contains('pro')) return const Color(0xFF22C55E);
    if (lower.contains('business')) return const Color(0xFF8B5CF6);
    if (lower.contains('enterprise')) return const Color(0xFF0EA5E9);
    return const Color(0xFF8B5CF6);
  }

  CreditPackage _enrichPackageWithUI(CreditPackage apiPackage) {
    final slug = apiPackage.planSlug?.toLowerCase() ?? apiPackage.name.toLowerCase();
    
    String name = apiPackage.name;
    String desc = apiPackage.description;
    List<String> benefits = apiPackage.benefits;
    int credits = apiPackage.credits;

    if (slug.contains('pro_plus') || slug.contains('pro plus') || slug.contains('pro-plus')) {
      name = 'Pro Plus';
      desc = 'Built for advanced learning teams';
      benefits = [
        'Create your own AI Co Workers',
        'Unlimited AI Co Workers',
        'AI Credits purchaeable',
        '1 hour maximum call duration',
        'Up to 500 buzz partiipants',
        'Up to 500 active calls per workspace',
        'Advanced controls for administrator only',
        'Call records available',
      ];
    } else if (slug.contains('pro') && !slug.contains('plus')) {
      name = 'Pro';
      desc = 'Ideal for growing learners';
      benefits = [
        'Create your own AI Co Workers',
        'Unlimited AI Co Workers',
        'AI Credits purchaeable',
        '1 hour maximum call duration',
        'Up to 50 buzz participants',
        'Up to 50 active calls per workspace',
        'Advanced controls for administrator only',
      ];
    } else if (slug.contains('business')) {
      name = 'Business';
      desc = 'Designed for organizations';
      benefits = [
        'Create your own AI Co Workers',
        'Unlimited AI Co Workers',
        'AI Credits purchaeable',
        'Unlimited call duration',
        'Up to 1500 buzz participants',
        'Up to 1500 active calls per workspace',
        'Call records and transcript available',
        'Advanced controls for administrator only',
      ];
    } else if (slug.contains('enterprise')) {
      name = 'Enterprise';
      desc = 'Tailored for large institutions';
      benefits = [
        'Create your own AI Co Workers',
        'Unlimited AI Co Workers',
        'AI Credits purchaeable',
        'Unlimited call duration',
        'Unlimited buzz participants',
        'Up to 1000 active calls per workspace',
        'Call records and transcript available',
        'Advanced controls for every user',
      ];
    }

    return CreditPackage(
      id: apiPackage.id,
      name: name,
      description: desc,
      price: apiPackage.price,
      credits: credits,
      benefits: benefits.isEmpty ? apiPackage.benefits : benefits,
      planSlug: apiPackage.planSlug,
    );
  }

  List<CreditPackage> get _displayPackages {
    final list = <CreditPackage>[
      const CreditPackage(
        id: 'free',
        name: 'Free',
        description: 'Perfect for individuals',
        price: 0,
        credits: 0,
        benefits: [
          'Create your own AI Co Workers',
          'Unlimited AI Co Workers',
          'AI Credits purchaeable',
          '1 hour maximum call duration',
          'Up to 5 buzz participants',
          'Up to 5 active calls per workspace',
        ],
        planSlug: 'free',
      ),
    ];
    
    for (final p in packages) {
      list.add(_enrichPackageWithUI(p));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _displayPackages;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 520, // Increased to fit the longest benefits list
      ),
      itemBuilder: (context, index) {
        final package = items[index];
        return CreditPackageCard(
          package: package,
          accentColor: _getColorForPackage(package.name),
          isCurrentPlan: _isCurrentPlan(package),
          isLoading: purchasingPackageId == package.id,
          onPurchase: package.isFree ? null : () => onPurchase(package),
        );
      },
    );
  }

  bool _isCurrentPlan(CreditPackage package) {
    final slug = package.planSlug;
    if (slug == null || currentPlanSlug == null) {
      return package.isFree && (currentPlanSlug == null || currentPlanSlug == 'free');
    }
    return slug == currentPlanSlug;
  }
}
