import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/home';
  static const login = '/login';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(path: home, builder: (context, state) => const HomeView()),
    ],
  );
}
