import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}
class MockDmRepository extends Mock implements DmRepository {}
class MockApiBaseService extends Mock implements ApiBaseService {}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);
  @override
  AuthState build() => _initialState;
}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  final WorkspaceState _initialState;
  FakeWorkspaceNotifier(this._initialState);
  @override
  WorkspaceState build() => _initialState;
}

class FakeUserProfileNotifier extends UserProfileNotifier {
  final UserProfileState _initialState;
  FakeUserProfileNotifier(this._initialState);
  @override
  UserProfileState build() => _initialState;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Channel(
      id: '',
      name: '',
      description: '',
      organisationId: '',
      ownerId: '',
    ));
  });

  group('HomeView Channel Switching Widget Tests', () {
    late MockChannelRepository mockChannelRepository;
    late MockDmRepository mockDmRepository;
    late AuthState authState;
    late WorkspaceState workspaceState;
    late UserProfileState userProfileState;
    late ChannelState channelState;

    setUp(() {
      mockChannelRepository = MockChannelRepository();
      mockDmRepository = MockDmRepository();

      // Register mocks in service locator if not registered
      if (!locator.isRegistered<SecureStorageService>()) {
        final mockStorage = MockSecureStorageService();
        locator.registerSingleton<SecureStorageService>(mockStorage);
        when(() => mockStorage.readData(any())).thenAnswer((_) async => null);
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'mock_token');
      }

      if (!locator.isRegistered<AppConfig>()) {
        locator.registerSingleton<AppConfig>(const AppConfig(
          apiBaseUrl: 'https://api.example.com',
          usesMockData: false,
        ));
      }

      if (!locator.isRegistered<ApiBaseService>()) {
        locator.registerSingleton<ApiBaseService>(MockApiBaseService());
      }

      final mockUser = User(
        id: 'user-123',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '',
        username: 'testuser',
        isVerified: true,
        isOnboarded: true,
        createdAt: DateTime.now(),
        avatarUrl: '',
        defaultAvatarUrl: '',
        creditBalance: 100,
        currentOrg: 'org-123',
        currentOrganisationSlug: '',
      );

      authState = AuthState(status: AuthStatus.authenticated, user: mockUser);

      workspaceState = WorkspaceState(
        selectedWorkspace: const Workspace(
          id: 'org-123',
          name: 'Test Org',
          avatar: '',
        ),
        workspaces: [
          const Workspace(
            id: 'org-123',
            name: 'Test Org',
            avatar: '',
          ),
        ],
      );

      userProfileState = const UserProfileState(
        teamMembers: [],
      );

      channelState = ChannelState(
        channels: [
          Channel(
            id: 'chan-general',
            name: 'general',
            description: 'General channel',
            organisationId: 'org-123',
            ownerId: 'user-123',
          ),
          Channel(
            id: 'chan-random',
            name: 'random',
            description: 'Random channel',
            organisationId: 'org-123',
            ownerId: 'user-123',
          ),
        ],
      );

      when(() => mockChannelRepository.fetchChannels(any())).thenAnswer((_) async => Success(channelState.channels));
      when(() => mockDmRepository.getMessages(any(), page: any(named: 'page'), threadId: any(named: 'threadId'))).thenAnswer((_) async => []);
    });

    testWidgets('renders channels from channelProvider and allows switching channels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
          workspaceProvider.overrideWith(() => FakeWorkspaceNotifier(workspaceState)),
          userProfileNotifierProvider.overrideWith(() => FakeUserProfileNotifier(userProfileState)),
          channelRepositoryProvider.overrideWithValue(mockChannelRepository),
          dmRepositoryProvider.overrideWithValue(mockDmRepository),
          // We don't override channelProvider completely because we want its notifier to run,
          // but we can override the repository it uses (mockChannelRepository).
        ],
        child: const MaterialApp(
          home: HomeView(),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Wait for fetchChannels to finish
      await tester.pumpAndSettle();

      // Check if both general and random channels are rendered in the sidebar
      expect(find.text('general'), findsWidgets);
      expect(find.text('random'), findsWidgets);

      // Initially, general is the active channel. Check if DmChatArea for general is shown.
      // DmChatArea is initialized with key ValueKey('channel_chan-general') or 'channel_general'
      expect(find.text('#general'), findsAtLeastNWidgets(1));

      // Now click on the 'random' channel
      final randomChannelFinder = find.text('random').last;
      await tester.ensureVisible(randomChannelFinder);
      await tester.tap(randomChannelFinder);

      // Pump to trigger build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // The active channel should change to random
      expect(find.text('#random'), findsAtLeastNWidgets(1));
    });
  });
}

class MockSecureStorageService extends Mock implements SecureStorageService {}
