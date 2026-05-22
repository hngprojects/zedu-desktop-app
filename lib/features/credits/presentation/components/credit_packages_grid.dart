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
    if (lower.contains('free')) return const Color(0xFFD1D5DB); // Gray-300
    if (lower.contains('pro plus')) return const Color(0xFFF59E0B); // Amber/Gold
    if (lower.contains('pro')) return const Color(0xFF22C55E); // Green
    if (lower.contains('business')) return const Color(0xFF8B5CF6); // Purple
    if (lower.contains('enterprise')) return const Color(0xFF0EA5E9); // Light Blue
    return const Color(0xFF8B5CF6);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final package in packages)
          CreditPackageCard(
            package: package,
            accentColor: _getColorForPackage(package.name),
            isCurrentPlan: _isCurrentPlan(package),
            isLoading: purchasingPackageId == package.id,
            onPurchase: package.isFree
                ? null
                : () => onPurchase(package),
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
