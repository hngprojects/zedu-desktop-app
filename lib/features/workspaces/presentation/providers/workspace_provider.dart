import 'package:zedu/core/core.dart';
import 'package:zedu/features/auth/auth.dart';

import '../../data/models/workspace.dart';
import 'workspace_state.dart';

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() {
    ref.watch(authNotifierProvider);
    Future.microtask(fetchWorkspaces);
    return const WorkspaceState(workspaces: [], isLoading: true);
  }

  Future<void> fetchWorkspaces() async {
    try {
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(
        path: '/users/organisations',
      );
      final data = response.data['data'] as List<dynamic>? ?? [];

      if (data.isNotEmpty) {
        final List<Workspace> workspaces = [];
        final currentUserId = ref.read(authNotifierProvider).user?.id;
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            final ownerId = item['owner_id'] as String? ?? item['creator_id'] as String?;
            if (ownerId != null && currentUserId != null && ownerId != currentUserId) {
              continue;
            }
            workspaces.add(
              Workspace(
                id: item['id'] as String? ?? '1',
                name: item['name'] as String? ?? 'Workspace',
                avatar: item['logo_url'] as String? ?? '',
                membersCount: (item['channels_count'] as num?)?.toInt() ?? 0,
                ownerId: ownerId,
              ),
            );
          }
        }
        if (workspaces.isNotEmpty) {
          state = state.copyWith(
            workspaces: workspaces,
            selectedWorkspace: workspaces.first,
            isLoading: false,
          );
        }
      } else {
        final createResponse = await api.post<Map<String, dynamic>>(
          path: '/organisations',
          data: {
            'name': 'Personal Workspace',
            'type': 'Personal',
            'country': 'Nigeria',
          },
        );
        final newOrgData = createResponse.data['data'] as Map<String, dynamic>;

        final newWorkspace = Workspace(
          id: newOrgData['id'] as String? ?? '',
          name: newOrgData['name'] as String? ?? 'Personal Workspace',
          avatar: newOrgData['logo_url'] as String? ?? '',
          membersCount: 1,
        );
        state = state.copyWith(
          workspaces: [newWorkspace],
          selectedWorkspace: newWorkspace,
          isLoading: false,
        );
      }
    } catch (e) {
      AppLogger.e(
        '_fetchWorkspaces failed',
        error: e,
        tag: 'WorkspaceNotifier',
      );
      if (e is ApiFailure && e.message.toLowerCase().contains('not a member')) {
        await _createPersonalWorkspace();
        return;
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _createPersonalWorkspace() async {
    final api = locator<ApiBaseService>();
    final createResponse = await api.post<Map<String, dynamic>>(
      path: '/organisations',
      data: {
        'name': 'Personal Workspace',
        'type': 'Personal',
        'country': 'Nigeria',
      },
    );
    final newOrgData = createResponse.data['data'] as Map<String, dynamic>;

    final newWorkspace = Workspace(
      id: newOrgData['id'] as String? ?? '',
      name: newOrgData['name'] as String? ?? 'Personal Workspace',
      avatar: newOrgData['logo_url'] as String? ?? '',
      membersCount: 1,
    );
    state = state.copyWith(
      workspaces: [newWorkspace],
      selectedWorkspace: newWorkspace,
      isLoading: false,
    );
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
