import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/home';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(path: home, builder: (context, state) => const HomeView()),
      GoRoute(path: signup, builder: (context, state) => const SignUpView()),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: resetPassword,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordView(email: email);
        },
      ),
    ],
  );
}
