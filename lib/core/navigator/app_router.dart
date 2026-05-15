import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/organization/presentation/pages/create_organization_page.dart';
import 'package:zedu/features/organization/presentation/pages/organization_home_page.dart';

class AppRouter {
  const AppRouter._();

  static const home = '/';
  static const login = '/login';
  static const createOrganization = '/create-organization';
  static const organizationHome = '/organization-home';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginView()),
      GoRoute(path: createOrganization, builder: (context, state) => const CreateOrganizationPage()),
      GoRoute(path: organizationHome, builder: (context, state) => const OrganizationHomePage()),
    ],
  );
}
