import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';
  static const login = '/login';
  static const magicLinkRequest = '/magic-link';
  static const magicLinkSent = '/magic-link/sent';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(
        path: magicLinkRequest,
        builder: (context, state) => const MagicLinkRequestView(),
      ),
      GoRoute(
        path: magicLinkSent,
        builder: (context, state) {
          final email = state.extra is String ? state.extra! as String : '';
          return MagicLinkSentView(email: email);
        },
      ),
    ],
  );
}
