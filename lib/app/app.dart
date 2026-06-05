import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../features/user_profile/presentation/components/global_profile_overlay.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return DesktopManager(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Zedu',
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => DesktopManager(
          child: AuthDeepLinkListener(
            child: GlobalProfileOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
