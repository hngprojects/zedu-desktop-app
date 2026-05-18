import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class OrganizationHomePage extends ConsumerWidget {
  const OrganizationHomePage({super.key});


  static const _mockOrgId = 'mock-org-123';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrg = ref.watch(activeOrganizationProvider);
    final orgId = activeOrg?.id ?? _mockOrgId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Organization Home'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to your Organization',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the actions below to manage your organization',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppButton(
                  label: 'Create Organization',
                  onPressed: () =>
                      context.go(AppRouter.createOrganization),
                ),
                const SizedBox(height: 16),
                AppButton.outlined(
                  label: 'Organization Settings',
                  onPressed: () =>
                      context.go(AppRouter.organizationSettings(orgId)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
