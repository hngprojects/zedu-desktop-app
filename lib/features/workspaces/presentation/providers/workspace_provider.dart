import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    Future.microtask(_fetchWorkspaces);
    return _getInitialState();
  }

  Future<void> _fetchWorkspaces() async {
    try {
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(path: '/users/organisations');
      final data = response.data['data'] as List<dynamic>? ?? [];
      
      if (data.isNotEmpty) {
        final List<Workspace> workspaces = [];
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            workspaces.add(Workspace(
              id: item['id'] as String? ?? '1',
              name: item['name'] as String? ?? 'Workspace',
              avatar: item['logo_url'] as String? ?? '',
              membersCount: (item['channels_count'] as num?)?.toInt() ?? 0,
            ));
          }
        }
        if (workspaces.isNotEmpty) {
          state = state.copyWith(
            workspaces: workspaces,
            selectedWorkspace: workspaces.first,
          );
        }
      }
    } catch (e) {
      // Ignore API errors and fallback to mock data implicitly
    }
  }

  WorkspaceState _getInitialState() {
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

    final user = authState.user!;
    final workspaces = _buildWorkspacesFromUser(user);

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

  List<Workspace> _buildWorkspacesFromUser(User user) {
    final workspaces = <Workspace>[];

    if (user.currentOrg.isNotEmpty) {
      workspaces.add(
        Workspace(
          id: user.currentOrg,
          name: user.currentOrganisationSlug.isNotEmpty
              ? user.currentOrganisationSlug
              : '${user.firstName}\'s Workspace',
          avatar: '',
        ),
      );
    }

    if (workspaces.isEmpty) {
      workspaces.add(
        const Workspace(
          id: '01910544-d1e1-7ada-bdac-c761e527ec91',
          name: 'Default Workspace',
          avatar: '',
        ),
      );
    }

    return workspaces;
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

  void addWorkspace(Workspace workspace) {
    state = state.copyWith(
      workspaces: [...state.workspaces, workspace],
      selectedWorkspace: workspace, // Optional: auto-switch to new workspace
    );
  }

  void removeWorkspace(String id) {
    final updatedWorkspaces = state.workspaces.where((w) => w.id != id).toList();
    Workspace? nextSelected = state.selectedWorkspace;
    if (state.selectedWorkspace?.id == id) {
      nextSelected = updatedWorkspaces.isNotEmpty ? updatedWorkspaces.first : null;
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
