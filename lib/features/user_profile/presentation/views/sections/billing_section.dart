import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BillingSection extends ConsumerStatefulWidget {
  const BillingSection({super.key, required this.billing});

  final BillingInfo billing;

  @override
  ConsumerState<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends ConsumerState<BillingSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgId = ref.read(authNotifierProvider).user?.currentOrg;
      if (orgId != null && orgId.isNotEmpty) {
        ref.read(creditsNotifierProvider.notifier).load(orgId: orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final creditsState = ref.watch(creditsNotifierProvider);
    final authUser = ref.watch(authNotifierProvider).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Billing & Plans',
          subtitle: widget.billing.description,
          trailing: TextButton(
            onPressed: () => context.go(AppRouter.buyCredits),
            child: const Text('Buy AI credits'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Current subscription: ${widget.billing.plan}',
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text(
          'All Plans',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 20),
        if (creditsState.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          CreditPackagesGrid(
            packages: creditsState.packages,
            currentPlanSlug: authUser?.subscriptionPlanId,
            onPurchase: (_) => context.go(AppRouter.buyCredits),
          ),
      ],
    );
  }
}
