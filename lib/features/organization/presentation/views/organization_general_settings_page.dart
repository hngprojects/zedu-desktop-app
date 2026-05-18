import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class OrganizationGeneralSettingsPage extends ConsumerStatefulWidget {
  const OrganizationGeneralSettingsPage({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationGeneralSettingsPage> createState() =>
      _OrganizationGeneralSettingsPageState();
}

class _OrganizationGeneralSettingsPageState
    extends ConsumerState<OrganizationGeneralSettingsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganization();
  }

  Future<void> _fetchOrganization() async {
    try {
      final repository = ref.read(organizationRepositoryProvider);
      final org = await repository.getOrganization(widget.orgId);

      ref.read(activeOrganizationProvider.notifier).active = org;
    } catch (e) {
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Failed to load organization details',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditModal(Organization org) {
    showDialog<void>(
      context: context,
      builder: (_) => UpdateOrganizationModal(organization: org),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(activeOrganizationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Your Organisation Information',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account data with ease.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (org != null) ...[
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: context.colors.borderOutline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OrganizationLogo(
                                logoUrl: org.logoUrl,
                                name: org.name,
                                size: 72,
                              ),

                              const Spacer(),

                              GestureDetector(
                                onTap: () => _openEditModal(org),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: context.colors.borderOutline,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _InfoRow(label: 'Name', value: org.name),
                          const SizedBox(height: 12),

                          _InfoRow(
                            label: 'Nature of Business',
                            value: org.industry,
                          ),
                          const SizedBox(height: 12),

                          _InfoRow(label: 'Country', value: org.country),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    OutlinedButton(
                      onPressed: () {
                        // TODO: wire up delete organisation logic
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.fieldRadius,
                          ),
                        ),
                      ),
                      child: const Text('Delete this organisation'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

}


class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
