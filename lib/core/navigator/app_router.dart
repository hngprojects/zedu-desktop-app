import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AppRouter {
  const AppRouter._();

  static const splash = '/';
  static const home = '/home';
  static const login = '/login';
  static const magicLinkRequest = '/magic-link';
  static const magicLinkSent = '/magic-link/sent';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const changePassword = '/change-password';
  static const profile = '/profile';
  static const createOrganization = '/create-organization';

  static final navigatorKey = GlobalKey<NavigatorState>();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppRouter.navigatorKey,
    initialLocation: AppRouter.splash,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      if (authState.status == AuthStatus.unknown &&
          state.uri.path != AppRouter.splash) {
        return AppRouter.splash;
      }

      final protectedRoutes = [
        AppRouter.home,
        AppRouter.profile,
        AppRouter.createOrganization,
      ];

      if (authState.status == AuthStatus.unauthenticated &&
          protectedRoutes.contains(state.uri.path)) {
        return AppRouter.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.splash,
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: AppRouter.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRouter.magicLinkRequest,
        builder: (context, state) => const MagicLinkRequestView(),
      ),
      GoRoute(
        path: AppRouter.magicLinkSent,
        redirect: (context, state) =>
            state.extra is String && (state.extra! as String).trim().isNotEmpty
            ? null
            : AppRouter.magicLinkRequest,
        builder: (context, state) {
          final email = state.extra is String ? state.extra! as String : '';
          return MagicLinkSentView(email: email);
        },
      ),
      GoRoute(
        path: AppRouter.home,
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: AppRouter.signup,
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        path: AppRouter.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: AppRouter.resetPassword,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordView(email: email);
        },
      ),
      GoRoute(
        path: AppRouter.changePassword,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ChangePasswordView(email: email);
        },
      ),
      GoRoute(
        path: AppRouter.profile,
        builder: (context, state) => const UserProfileView(),
      ),
      GoRoute(
        path: AppRouter.createOrganization,
        builder: (context, state) => const CreateOrganizationView(),
      ),
    ],
  );
});
