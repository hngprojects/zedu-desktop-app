import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/home';
  static const login = '/login';
  static const createOrganization = '/create-organization';
  static const organizationHome = '/organization-home';
  static const _orgSettingsBase = '/organization-settings';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const changePassword = '/change-password';
  static const profile = '/profile';

  static String organizationSettings(String orgId) =>
      '$_orgSettingsBase/$orgId';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(
        path: createOrganization,
        builder: (context, state) => const CreateOrganizationPage(),
      ),
      GoRoute(
        path: organizationHome,
        builder: (context, state) => const OrganizationHomePage(),
      ),

      GoRoute(
        path: '$_orgSettingsBase/:orgId',
        builder: (context, state) => OrganizationGeneralSettingsPage(
          orgId: state.pathParameters['orgId']!,
        ),
      ),
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
      GoRoute(
        path: changePassword,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ChangePasswordView(email: email);
        },
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const UserProfileView(),
      ),
    ],
  );
}
