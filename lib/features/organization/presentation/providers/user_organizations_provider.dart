import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final userOrganizationsProvider = FutureProvider<List<Organization>>((ref) async {
  final repository = ref.watch(organizationRepositoryProvider);
  return repository.getOrganizations();
});
