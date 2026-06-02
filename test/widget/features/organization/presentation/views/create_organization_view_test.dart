import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
  }) : _initial = initial;

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState(isLoading: false);
}

Widget buildCreateOrgUnderTest() {
  final router = GoRouter(
    initialLocation: AppRouter.createOrganization,
    routes: [
      GoRoute(
        path: AppRouter.home,
        builder: (context, state) => const Scaffold(body: Text('Home View')),
      ),
      GoRoute(
        path: AppRouter.createOrganization,
        builder: (context, state) => const CreateOrganizationView(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
      userProfileNotifierProvider.overrideWith(() => FakeUserProfileNotifier()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('CreateOrganizationView Tests', () {
    testWidgets('renders back button and form inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildCreateOrgUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.text('Create Your Organization'), findsOneWidget);
      expect(find.text('Organization Name'), findsOneWidget);
      expect(find.text('Organization Type'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets(
      'clicking back button navigates to Home View when pop is not possible',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1440, 1024));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildCreateOrgUnderTest());
        await tester.pumpAndSettle();

        final backButton = find.byIcon(Icons.arrow_back);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.text('Home View'), findsOneWidget);
      },
    );
  });
}
