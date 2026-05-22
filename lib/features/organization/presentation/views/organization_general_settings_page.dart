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
  bool _isSaving = false;

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

  Future<void> _deleteOrganization(Organization org) async {
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(organizationRepositoryProvider);
      await repository.deleteOrganization(org.id);

      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.success,
          message: 'Organization deleted successfully.',
        );
        context.go(AppRouter.home);
      }
    } catch (e) {
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Failed to delete organization: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(Organization org) async {
    if (org.industry.toLowerCase().contains('default') ||
        org.name.toLowerCase().contains('default')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot delete organization'),
          content: const Text('You cannot delete the default organization.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => DeleteOrganizationModal(
        organization: org,
        onConfirm: () => _deleteOrganization(org),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(activeOrganizationProvider);
    final notifier = ref.read(userProfileNotifierProvider.notifier);

    return ProfileSettingsShell(
      selectedSection: UserProfileSection.organization,
      onSectionSelected: (section) {
        if (section == UserProfileSection.organization) return;
        notifier.selectSection(section);
        context.go(AppRouter.profile);
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 40, 48),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ProfileSectionHeader(
                        title: 'Your Organisation Information',
                        subtitle: 'Manage your account data with ease.',
                      ),
                      const SizedBox(height: 28),
                      if (org != null) ...[
                        ProfileCard(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: 480,
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _OrganizationAvatar(
                                      initials: _getInitials(org.name),
                                    ),
                                    const SizedBox(height: 24),
                                    const ProfileFieldLabel('Name'),
                                    const SizedBox(height: 4),
                                    Text(
                                      org.name,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const ProfileFieldLabel('Nature of Business'),
                                    const SizedBox(height: 4),
                                    Text(
                                      org.industry,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const ProfileFieldLabel('Country'),
                                    const SizedBox(height: 4),
                                    Text(
                                      org.country,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: SquareIconButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (_) => UpdateOrganizationModal(
                                            organization: org),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        AppButton.outlined(
                          label: 'Delete this organisation',
                          expand: false,
                          height: 44,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.error,
                            side: BorderSide(color: context.colors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          loading: _isSaving,
                          onPressed: () => _confirmDelete(org),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'ZO';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _OrganizationAvatar extends StatelessWidget {
  const _OrganizationAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: context.colors.divider,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: context.colors.sidebar,
          ),
        ),
      ),
    );
  }
}
