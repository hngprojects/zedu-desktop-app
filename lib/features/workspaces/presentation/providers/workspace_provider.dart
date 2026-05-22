import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    final authState = ref.watch(authNotifierProvider);
    return _resolveState(authState);
  }

  WorkspaceState _resolveState(AuthState authState) {
    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      return const WorkspaceState();
    }

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
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
