import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BillingSection extends StatelessWidget {
  const BillingSection({super.key, required this.billing});

  final BillingInfo billing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Billing & Plans',
          subtitle: 'Manage your organization subscription and billing.',
        ),
        const SizedBox(height: 28),
        ProfileCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                billing.plan,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(billing.description, style: context.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
