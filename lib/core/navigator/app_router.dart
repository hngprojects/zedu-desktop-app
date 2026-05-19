import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';
  static const login = '/login';
  static const profile = '/profile';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(
        path: home, // This is '/'
        builder: (context, state) => const UserProfileView(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const UserProfileView(),
      ),
    ],
  );
}
