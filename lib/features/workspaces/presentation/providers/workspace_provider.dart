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

    return WorkspaceState(
      workspaces: workspaces,
      selectedWorkspace: workspaces.first,
    );
  }

  Future<void> switchWorkspace(Workspace workspace) async {
    if (state.selectedWorkspace?.id == workspace.id) return;

    state = state.copyWith(isLoading: true);

    // Simulate network delay for switching
    await Future<void>.delayed(const Duration(milliseconds: 800));

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
