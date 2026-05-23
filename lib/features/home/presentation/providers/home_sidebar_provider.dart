import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Workspace areas selectable from [AppSidebarRail].
enum HomeSidebarType { home, dms, people, files, buzz, notifications, settings }

/// Tracks the active workspace module for [HomeView] panel switchers.
class HomeSidebarNotifier extends Notifier<HomeSidebarType> {
  @override
  HomeSidebarType build() => HomeSidebarType.home;

  void setType(HomeSidebarType type) {
    if (state == type) return;
    if (state == HomeSidebarType.dms && type != HomeSidebarType.dms) {
      ref.read(selectedDmProvider.notifier).select(null);
    }
    state = type;
  }
}

final homeSidebarProvider =
    NotifierProvider<HomeSidebarNotifier, HomeSidebarType>(
      HomeSidebarNotifier.new,
    );

/// Selects a workspace module and navigates to [AppRouter.home] when needed.
void openWorkspaceModule(
  WidgetRef ref,
  HomeSidebarType type, {
  required BuildContext context,
}) {
  ref.read(homeSidebarProvider.notifier).setType(type);
  if (!context.mounted) return;
  if (GoRouterState.of(context).matchedLocation != AppRouter.home) {
    context.go(AppRouter.home);
  }
}

/// Opens workspace settings (profile sections) inside the home shell.
void openWorkspaceSettings(WidgetRef ref, {required BuildContext context}) {
  openWorkspaceModule(ref, HomeSidebarType.settings, context: context);
}
