import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAppConfig extends Mock implements AppConfig {}

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

void main() {
  group('UserProfileNotifier Tests', () {
    late MockUserProfileRepository mockRepository;
    late MockSecureStorageService mockSecureStorage;
    late MockAppConfig mockAppConfig;
    late AuthState authState;
    late WorkspaceState workspaceState;
    late ProviderContainer container;

    final mockUser = LoginResponseModel.fromJson(
      LoginResponseModel.mockLoginResponse,
    ).user.toEntity();

    setUp(() {
      mockRepository = MockUserProfileRepository();
      mockSecureStorage = MockSecureStorageService();
      mockAppConfig = MockAppConfig();

      when(() => mockAppConfig.usesMockData).thenReturn(false);
      when(
        () => mockSecureStorage.readData(any()),
      ).thenAnswer((_) async => null);

      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      locator.registerSingleton<SecureStorageService>(mockSecureStorage);

      if (locator.isRegistered<AppConfig>()) {
        locator.unregister<AppConfig>();
      }
      locator.registerSingleton<AppConfig>(mockAppConfig);

      authState = AuthState(status: AuthStatus.authenticated, user: mockUser);
      workspaceState = WorkspaceState(
        workspaces: const [
          Workspace(id: 'org-1', name: 'Org 1', avatar: ''),
          Workspace(id: 'org-2', name: 'Org 2', avatar: ''),
        ],
        selectedWorkspace: const Workspace(
          id: 'org-1',
          name: 'Org 1',
          avatar: '',
        ),
      );

      registerFallbackValue(
        const ProfileAccount(name: '', email: '', timezone: ''),
      );
      registerFallbackValue(
        const NotificationPreferences(
          mode: NotificationMode.allMessages,
          fromTime: '',
          toTime: '',
          useDesktopSettings: false,
          emailNotifications: false,
        ),
      );
      registerFallbackValue(OrganizationProfile.empty());

      when(() => mockRepository.getAccount()).thenAnswer(
        (_) async => const Success(
          ProfileAccount(
            name: 'User One',
            email: 'test@example.com',
            timezone: 'UTC',
          ),
        ),
      );
      when(() => mockRepository.getNotificationPreferences()).thenAnswer(
        (_) async => const Success(
          NotificationPreferences(
            mode: NotificationMode.allMessages,
            fromTime: '',
            toTime: '',
            useDesktopSettings: true,
            emailNotifications: true,
          ),
        ),
      );
      when(
        () => mockRepository.getSecuritySessions(),
      ).thenAnswer((_) async => const Success(<SecuritySession>[]));
      when(() => mockRepository.getOrganization()).thenAnswer(
        (_) async => const Success(
          OrganizationProfile(
            id: 'org-1',
            name: 'Org 1',
            natureOfBusiness: '',
            country: '',
          ),
        ),
      );
      when(
        () => mockRepository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((invocation) async {
        final id = invocation.namedArguments[#orgId] as String?;
        if (id == 'org-1') {
          return const Success([
            TeamMember(
              id: 'm-1',
              email: 'm1@org1.com',
              role: 'User',
              dateJoined: '',
              status: TeamMemberStatus.active,
              name: 'Member 1',
            ),
          ]);
        } else if (id == 'org-2') {
          return const Success([
            TeamMember(
              id: 'm-2',
              email: 'm2@org2.com',
              role: 'User',
              dateJoined: '',
              status: TeamMemberStatus.active,
              name: 'Member 2',
            ),
          ]);
        }
        return const Success(<TeamMember>[]);
      });
      when(
        () => mockRepository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success(<RolePermission>[]));
      when(() => mockRepository.getBillingInfo()).thenAnswer(
        (_) async => const Success(BillingInfo(plan: 'free', description: '')),
      );
    });

    tearDown(() {
      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      if (locator.isRegistered<AppConfig>()) {
        locator.unregister<AppConfig>();
      }
    });

    ProviderContainer createContainer({WorkspaceState? initialWorkspaceState}) {
      final actualWorkspaceState = initialWorkspaceState ?? workspaceState;
      final cont = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(mockRepository),
          authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
          workspaceProvider.overrideWith(
            () => FakeWorkspaceNotifier(actualWorkspaceState),
          ),
        ],
      );
      cont.listen(userProfileNotifierProvider, (previous, next) {});
      addTearDown(cont.dispose);
      return cont;
    }

    test(
      'UserProfileNotifier loads data initially for selected workspace',
      () async {
        container = createContainer();

        container.read(userProfileNotifierProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final state = container.read(userProfileNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.account?.name, 'User One');
        expect(state.teamMembers, hasLength(1));
        expect(state.teamMembers.first.id, 'm-1');
      },
    );

    test(
      'rebuilds and updates team members list when current workspace ID changes',
      () async {
        container = createContainer();

        container.read(userProfileNotifierProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(
          container.read(userProfileNotifierProvider).teamMembers.first.id,
          'm-1',
        );

        final notifier = container.read(workspaceProvider.notifier);
        await notifier.switchWorkspace(
          const Workspace(id: 'org-2', name: 'Org 2', avatar: ''),
        );

        await Future<void>.delayed(const Duration(milliseconds: 350));

        final state = container.read(userProfileNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.teamMembers, hasLength(1));
        expect(state.teamMembers.first.id, 'm-2');
      },
    );
  });
}
