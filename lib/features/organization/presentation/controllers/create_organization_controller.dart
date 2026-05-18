import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class CreateOrganizationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Organization?> create(CreateOrganizationRequest request) async {
    state = const AsyncLoading();
    Organization? createOrg;
    state = await AsyncValue.guard(() async {
      final repository = ref.read(organizationRepositoryProvider);
      createOrg = await repository.createOrganization(request);
      if (createOrg != null) {
        ref.read(activeOrganizationProvider.notifier).active = createOrg;
      }
    });
    return createOrg;
  }
}
