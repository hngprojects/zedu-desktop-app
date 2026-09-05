import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    final authStatus = ref.watch(authNotifierProvider.select((s) => s.status));
    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(fetchWorkspaces);
    }
    return _getInitialState();
  }

  Future<void> fetchWorkspaces() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.status != AuthStatus.authenticated) return;

    try {
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(
        path: '/users/organisations',
      );
      final data = response.data['data'] as List<dynamic>? ?? [];

      final currentUserId = authState.user?.id;
      final List<Workspace> workspaces = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          final ownerId =
              item['owner_id'] as String? ?? item['creator_id'] as String?;
          final usersList = item['Users'] as List? ?? item['users'] as List?;

          bool isMember = false;
          if (ownerId == currentUserId) isMember = true;
          if (usersList != null) {
            for (var u in usersList) {
              final uId = u['id'] ?? u['user_id'];
              if (uId == currentUserId) {
                isMember = true;
                break;
              }
            }
          }
          if (!isMember) continue;

          final parsedMembersCount =
              (item['members_count'] as num?)?.toInt() ??
              (item['users_count'] as num?)?.toInt() ??
              usersList?.length ??
              (item['channels_count'] as num?)?.toInt() ??
              0;

          workspaces.add(
            Workspace(
              id: item['id'] as String? ?? '1',
              name: item['name'] as String? ?? 'Workspace',
              avatar: item['logo_url'] as String? ?? '',
              membersCount: parsedMembersCount,
              ownerId: ownerId,
            ),
          );
        }
      }

      Workspace? selected;
      String? previousId;
      try {
        previousId = state.selectedWorkspace?.id;
      } catch (_) {}

      if (previousId != null) {
        for (final ws in workspaces) {
          if (ws.id == previousId) {
            selected = ws;
            break;
          }
        }
      }
      selected ??= workspaces.isNotEmpty ? workspaces.first : null;

      state = WorkspaceState(
        workspaces: workspaces,
        selectedWorkspace: selected,
        isLoading: false,
      );
    } catch (e) {
      AppConfig? config;
      try {
        config = locator<AppConfig>();
      } catch (_) {}
      if ((config?.usesMockData ?? false) && state.workspaces.isEmpty) {
        state = _getInitialState();
      }
    }
  }

  WorkspaceState _getInitialState() {
    AppConfig? config;
    try {
      config = locator<AppConfig>();
    } catch (_) {}
    final usesMockData = config?.usesMockData ?? false;
    final authState = ref.read(authNotifierProvider);

    if (!usesMockData || authState.status != AuthStatus.authenticated) {
      return const WorkspaceState(workspaces: [], selectedWorkspace: null);
    }

    final workspaces = [
      const Workspace(
        id: '1',
        name: 'HNG Workspace',
        avatar: '',
        unreadCount: 1351,
        membersCount: 1351,
      ),
      const Workspace(
        id: '2',
        name: 'TeamFlow Collective',
        avatar: '',
        unreadCount: 15,
        membersCount: 42,
      ),
      const Workspace(
        id: '3',
        name: 'Coffee & Code House',
        avatar: '',
        unreadCount: 0,
        membersCount: 12,
      ),
      const Workspace(
        id: '4',
        name: 'ConnectHub',
        avatar: '',
        unreadCount: 3,
        membersCount: 89,
      ),
    ];

    String? previousId;
    try {
      previousId = state.selectedWorkspace?.id;
    } catch (_) {}

    final selected = previousId != null
        ? workspaces.firstWhere(
            (ws) => ws.id == previousId,
            orElse: () => workspaces.first,
          )
        : workspaces.first;

    return WorkspaceState(workspaces: workspaces, selectedWorkspace: selected);
  }

  void addWorkspace(Workspace workspace, {bool switchTo = true}) {
    final current = state.workspaces;
    if (current.any((w) => w.id == workspace.id)) return;
    final updated = [...current, workspace];
    state = state.copyWith(
      workspaces: updated,
      selectedWorkspace: switchTo ? workspace : state.selectedWorkspace,
    );
  }

  Future<void> switchWorkspace(Workspace workspace) async {
    if (state.selectedWorkspace?.id == workspace.id) return;

    state = state.copyWith(isLoading: true);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(selectedWorkspace: workspace, isLoading: false);
  }

  void removeWorkspace(String id) {
    final updatedWorkspaces = state.workspaces
        .where((w) => w.id != id)
        .toList();
    Workspace? nextSelected = state.selectedWorkspace;
    if (state.selectedWorkspace?.id == id) {
      nextSelected = updatedWorkspaces.isNotEmpty
          ? updatedWorkspaces.first
          : null;
    }
    state = state.copyWith(
      workspaces: updatedWorkspaces,
      selectedWorkspace: nextSelected,
    );
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
