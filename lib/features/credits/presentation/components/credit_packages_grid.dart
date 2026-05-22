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

  static const _accentColors = [
    Color(0xFF6458F5),
    Color(0xFF22C55E),
    Color(0xFF6458F5),
    Color(0xFFFBBF24),
    Color(0xFF3B82F6),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (var i = 0; i < packages.length; i++)
          CreditPackageCard(
            package: packages[i],
            accentColor: _accentColors[i % _accentColors.length],
            isCurrentPlan: _isCurrentPlan(packages[i]),
            isLoading: purchasingPackageId == packages[i].id,
            onPurchase: packages[i].isFree
                ? null
                : () => onPurchase(packages[i]),
          ),
      ],
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
