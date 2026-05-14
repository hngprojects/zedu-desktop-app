import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileNotifierProvider);

    return ProfileSettingsShell(
      selectedSection: state.section,
      onSectionSelected: ref
          .read(userProfileNotifierProvider.notifier)
          .selectSection,
      child: state.isLoading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 32, 40, 48),
              child: ProfileSectionHeader(
                title: 'Your Account Information',
                subtitle: 'Manage your account data with ease.',
              ),
            ),
    );
  }
}
