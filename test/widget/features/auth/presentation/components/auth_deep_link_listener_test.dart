import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockAppLinks extends Mock implements AppLinks {}

class FakeDeepLinkAuthNotifier extends AuthNotifier {
  FakeDeepLinkAuthNotifier({
    this.onVerify,
    this.initialStatus = AuthStatus.unauthenticated,
  });

  final void Function(String token)? onVerify;
  final AuthStatus initialStatus;

  @override
  AuthState build() => AuthState(
    status: initialStatus,
    user: initialStatus == AuthStatus.authenticated
        ? LoginResponseModel.fromJson(
            LoginResponseModel.mockLoginResponse,
          ).user.toEntity()
        : null,
  );

  @override
  Future<void> verifyMagicLink({required String token}) async {
    onVerify?.call(token);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void logIn() {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: LoginResponseModel.fromJson(
        LoginResponseModel.mockLoginResponse,
      ).user.toEntity(),
    );
  }
}

class FakeUserProfileNotifier extends UserProfileNotifier {
  FakeUserProfileNotifier({this.onAcceptInvite});

  final void Function(String token)? onAcceptInvite;

  @override
  UserProfileState build() => const UserProfileState(isLoading: false);

  @override
  Future<void> acceptInvitation(String token) async {
    onAcceptInvite?.call(token);
    state = const UserProfileState(
      isLoading: false,
      successMessage: 'Successfully joined the workspace.',
    );
  }
}

void main() {
  group('AuthDeepLinkListener', () {
    late MockAppLinks mockAppLinks;
    late StreamController<Uri> linkController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      linkController = StreamController<Uri>.broadcast();

      when(
        () => mockAppLinks.uriLinkStream,
      ).thenAnswer((_) => linkController.stream);
    });

    tearDown(() async {
      await linkController.close();
    });

    testWidgets('ignores link when token query param is missing', (
      tester,
    ) async {
      String? capturedToken;

      when(
        () => mockAppLinks.getInitialLink(),
      ).thenAnswer((_) async => Uri.parse('zedu://auth/magick-link/verify'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeDeepLinkAuthNotifier(
                onVerify: (token) => capturedToken = token,
              ),
            ),
          ],
          child: MaterialApp(
            home: AuthDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedToken, isNull);
    });

    testWidgets('passes token to verifyMagicLink for valid initial link', (
      tester,
    ) async {
      String? capturedToken;

      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('zedu://auth/magick-link/verify?token=t-123'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeDeepLinkAuthNotifier(
                onVerify: (token) => capturedToken = token,
              ),
            ),
          ],
          child: MaterialApp(
            home: AuthDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(capturedToken, 't-123');
    });

    testWidgets('accepts invitation immediately if authenticated', (
      tester,
    ) async {
      String? acceptedToken;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                AuthDeepLinkListener(appLinks: mockAppLinks, child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRouter.home,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );

      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('zedu://invite/accept?token=invite-999'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeDeepLinkAuthNotifier(
                initialStatus: AuthStatus.authenticated,
              ),
            ),
            userProfileNotifierProvider.overrideWith(
              () => FakeUserProfileNotifier(
                onAcceptInvite: (token) => acceptedToken = token,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(acceptedToken, 'invite-999');
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('saves invitation and accepts it post-authentication', (
      tester,
    ) async {
      String? acceptedToken;
      final authNotifier = FakeDeepLinkAuthNotifier(
        initialStatus: AuthStatus.unauthenticated,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                AuthDeepLinkListener(appLinks: mockAppLinks, child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRouter.home,
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRouter.login,
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );

      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('zedu://invite/accept?token=invite-later'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => authNotifier),
            userProfileNotifierProvider.overrideWith(
              () => FakeUserProfileNotifier(
                onAcceptInvite: (token) => acceptedToken = token,
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(acceptedToken, isNull);

      final element = tester.element(find.byType(AuthDeepLinkListener));
      final container = ProviderScope.containerOf(element);
      (container.read(authNotifierProvider.notifier)
              as FakeDeepLinkAuthNotifier)
          .logIn();
      await tester.pumpAndSettle();

      expect(acceptedToken, 'invite-later');
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
