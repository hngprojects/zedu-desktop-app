import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChannelRepository extends Mock implements ChannelRepository {}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  final WorkspaceState _initialState;
  FakeWorkspaceNotifier(this._initialState);

  @override
  WorkspaceState build() => _initialState;
}

class MockAppConfig extends Mock implements AppConfig {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initialState;
  FakeAuthNotifier(this._initialState);

  @override
  AuthState build() => _initialState;
}

void main() {
  group('ChannelNotifier Tests', () {
    late MockChannelRepository mockChannelRepository;
    late MockAppConfig mockAppConfig;
    late MockSecureStorageService mockSecureStorage;
    late WorkspaceState workspaceState;
    late AuthState authState;

    setUp(() {
      mockChannelRepository = MockChannelRepository();
      mockAppConfig = MockAppConfig();
      mockSecureStorage = MockSecureStorageService();

      when(() => mockAppConfig.usesMockData).thenReturn(false);
      when(() => mockAppConfig.websocketUrl).thenReturn('wss://test.com');
      when(
        () => mockSecureStorage.readData(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.getAccessToken(),
      ).thenAnswer((_) async => 'mock_token');

      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      locator.registerSingleton<SecureStorageService>(mockSecureStorage);

      if (locator.isRegistered<AppConfig>()) {
        locator.unregister<AppConfig>();
      }
      locator.registerSingleton<AppConfig>(mockAppConfig);

      final mockUser = LoginResponseModel.fromJson(
        LoginResponseModel.mockLoginResponse,
      ).user.toEntity();

      workspaceState = WorkspaceState(
        selectedWorkspace: const Workspace(
          id: 'org-123',
          name: 'Test Org',
          avatar: '',
        ),
      );

      authState = AuthState(status: AuthStatus.authenticated, user: mockUser);
    });

    tearDown(() {
      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      if (locator.isRegistered<AppConfig>()) {
        locator.unregister<AppConfig>();
      }
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          channelRepositoryProvider.overrideWithValue(mockChannelRepository),
          workspaceProvider.overrideWith(
            () => FakeWorkspaceNotifier(workspaceState),
          ),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
          currentOrgIdProvider.overrideWithValue('org-123'),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is default empty state', () async {
      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success(<Channel>[]));
      final container = createContainer();

      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(channelProvider);
      expect(state.channels, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('fetchChannels success updates channels list', () async {
      final mockChannels = [
        Channel(
          id: 'c-1',
          name: 'general',
          description: 'General channel',
          organisationId: 'org-123',
          ownerId: 'owner-1',
        ),
      ];

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success(mockChannels));

      final container = createContainer();

      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(channelProvider);
      expect(state.isLoading, isFalse);
      expect(state.channels, equals(mockChannels));
      expect(state.errorMessage, isNull);
    });

    test('fetchChannels failure sets errorMessage', () async {
      const apiFailure = ApiFailure(
        message: 'Could not fetch channels',
        kind: ApiFailureKind.server,
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => const Failure(apiFailure));

      final container = createContainer();

      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(channelProvider);
      expect(state.isLoading, isFalse);
      expect(state.channels, isEmpty);
      expect(state.errorMessage, 'Could not fetch channels');
    });

    test('createChannel success adds new channel to local state', () async {
      final newChannel = Channel(
        id: 'c-2',
        name: 'random',
        description: 'Random stuff',
        organisationId: 'org-123',
        ownerId: 'owner-1',
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success(<Channel>[]));

      when(
        () => mockChannelRepository.createChannel(
          name: 'random',
          description: 'Random stuff',
          orgId: 'org-123',
          username: any(named: 'username'),
          isPrivate: false,
          topic: any(named: 'topic'),
        ),
      ).thenAnswer((_) async => Success(newChannel));

      final container = createContainer();

      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.createChannel(
        name: 'random',
        description: 'Random stuff',
        isPrivate: false,
      );

      expect(result, isTrue);
      expect(container.read(channelProvider).channels, contains(newChannel));
    });

    test(
      'updateChannelTopicOrDescription updates local channel info',
      () async {
        final originalChannel = Channel(
          id: 'c-1',
          name: 'general',
          description: 'Old description',
          organisationId: 'org-123',
          ownerId: 'owner-1',
          topic: 'Old topic',
        );

        when(
          () => mockChannelRepository.fetchChannels('org-123'),
        ).thenAnswer((_) async => Success([originalChannel]));

        when(
          () => mockChannelRepository.updateChannelTopicOrDescription(
            channelId: 'c-1',
            topic: 'New topic',
            description: 'New description',
          ),
        ).thenAnswer((_) async => const Success(null));

        final container = createContainer();

        container.read(channelProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final notifier = container.read(channelProvider.notifier);
        final result = await notifier.updateChannelTopicOrDescription(
          channelId: 'c-1',
          topic: 'New topic',
          description: 'New description',
        );

        expect(result, isTrue);
        final updatedChannel = container.read(channelProvider).channels.first;
        expect(updatedChannel.topic, 'New topic');
        expect(updatedChannel.description, 'New description');
      },
    );

    test('archiveChannel removes channel if archived = true', () async {
      final originalChannel = Channel(
        id: 'c-1',
        name: 'general',
        description: 'General channel',
        organisationId: 'org-123',
        ownerId: 'owner-1',
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success([originalChannel]));

      when(
        () => mockChannelRepository.archiveChannel('c-1', true),
      ).thenAnswer((_) async => const Success(null));

      final container = createContainer();

      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.archiveChannel('c-1', true);

      expect(result, isTrue);
      expect(container.read(channelProvider).channels, isEmpty);
    });

    test('toggleChannelPrivacy updates local channel isPrivate flag', () async {
      final originalChannel = Channel(
        id: 'c-1',
        name: 'general',
        description: 'General channel',
        organisationId: 'org-123',
        ownerId: 'owner-1',
        isPrivate: false,
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success([originalChannel]));

      when(
        () => mockChannelRepository.toggleChannelPrivacy('c-1', true),
      ).thenAnswer((_) async => const Success(null));

      final container = createContainer();
      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.toggleChannelPrivacy('c-1', true);

      expect(result, isTrue);
      expect(container.read(channelProvider).channels.first.isPrivate, isTrue);
    });

    test('leaveChannel removes channel from local list', () async {
      final originalChannel = Channel(
        id: 'c-1',
        name: 'general',
        description: 'General channel',
        organisationId: 'org-123',
        ownerId: 'owner-1',
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success([originalChannel]));

      when(
        () => mockChannelRepository.leaveChannel('c-1'),
      ).thenAnswer((_) async => const Success(null));

      final container = createContainer();
      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.leaveChannel('c-1');

      expect(result, isTrue);
      expect(container.read(channelProvider).channels, isEmpty);
    });

    test('joinChannel triggers fetchChannels and updates list', () async {
      final newChannel = Channel(
        id: 'c-2',
        name: 'random',
        description: 'Random channel',
        organisationId: 'org-123',
        ownerId: 'owner-1',
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success([newChannel]));

      when(
        () => mockChannelRepository.joinChannel('c-2'),
      ).thenAnswer((_) async => const Success(null));

      final container = createContainer();
      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.joinChannel('c-2');

      expect(result, isTrue);
      verify(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).called(greaterThan(0));
    });

    test('addChannelMembers increments membersCount locally', () async {
      final originalChannel = Channel(
        id: 'c-1',
        name: 'general',
        description: 'General channel',
        organisationId: 'org-123',
        ownerId: 'owner-1',
        membersCount: 2,
      );

      when(
        () => mockChannelRepository.fetchChannels('org-123'),
      ).thenAnswer((_) async => Success([originalChannel]));

      when(
        () => mockChannelRepository.addChannelMembers('c-1', ['u-1', 'u-2']),
      ).thenAnswer((_) async => const Success(null));

      final container = createContainer();
      container.read(channelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(channelProvider.notifier);
      final result = await notifier.addChannelMembers('c-1', ['u-1', 'u-2']);

      expect(result, isTrue);
      expect(
        container.read(channelProvider).channels.first.membersCount,
        equals(4),
      );
    });
  });
}
