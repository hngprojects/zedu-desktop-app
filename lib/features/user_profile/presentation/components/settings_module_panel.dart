import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SettingsModuleSidebar extends ConsumerWidget {
  const SettingsModuleSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileNotifierProvider);

    return SettingsNavigationSidebar(
      userName: state.account?.name ?? 'Zedu User',
      selectedSection: state.section,
      onSectionSelected: ref
          .read(userProfileNotifierProvider.notifier)
          .selectSection,
    );
  }
}

class SettingsModuleContent extends ConsumerWidget {
  const SettingsModuleContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UserProfileState>(userProfileNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        _showToast(context, AppToastType.error, next.error!);
      }
      if (next.successMessage != null &&
          previous?.successMessage != next.successMessage) {
        _showToast(context, AppToastType.success, next.successMessage!);
      }
    });

    final state = ref.watch(userProfileNotifierProvider);

    if (state.isLoading) {
      return Container(
        color: context.colors.background,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.white,
      child: ProfileSectionContent(
        state: state,
        notifier: ref.read(userProfileNotifierProvider.notifier),
      ),
    );
  }

  void _showToast(BuildContext context, AppToastType type, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      AppToastService.show(context, type: type, message: message);
    });
  }
}
