import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authNotifierProvider.select((s) => s.status));
    final colors = context.colors;

    // Reactively redirect once the session state is resolved
    if (status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRouter.home);
        }
      });
    } else if (status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(AppRouter.login);
        }
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Zedu',
              style: TextStyle(
                color: colors.primary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poetsen One',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
