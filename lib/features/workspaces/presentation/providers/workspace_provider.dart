import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    return _getInitialState();
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
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
