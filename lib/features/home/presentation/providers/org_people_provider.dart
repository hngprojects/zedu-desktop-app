import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final orgPeopleProvider = FutureProvider<List<TeamMember>>((ref) async {
  final workspace = ref.watch(workspaceProvider).selectedWorkspace;
  final orgId = workspace?.id ?? '';
  
  if (orgId.isEmpty) return [];

  final repository = ref.watch(userProfileRepositoryProvider);
  final result = await repository.getTeamMembers(orgId: orgId);
  
  if (result is Success<List<TeamMember>>) {
    return result.value;
  }
  
  return [];
});
