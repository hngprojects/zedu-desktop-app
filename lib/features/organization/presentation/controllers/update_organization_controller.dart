import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UpdateOrganizationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Organization?> updateOrganization(UpdateOrganizationRequest request) async {
    state = const AsyncLoading();
    Organization? updateOrg;
    state = await AsyncValue.guard(() async {
      final repository = ref.read(organizationRepositoryProvider);
      updateOrg = await repository.updateOrganization(request);
      if (updateOrg != null) {
        ref.read(activeOrganizationProvider.notifier).active = updateOrg;
      }
    });
    return updateOrg;
  }
}
