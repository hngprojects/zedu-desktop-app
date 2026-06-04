import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final orgPeopleProvider = Provider<List<TeamMember>>((ref) {
  final workspace = ref.watch(workspaceProvider).selectedWorkspace;
  final orgId = workspace?.id ?? '';

  if (orgId.isEmpty) return [];

  // Watch the real-time team members list
  return ref.watch(userProfileNotifierProvider).teamMembers;
});
