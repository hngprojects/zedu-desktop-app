import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

class CreateOrganizationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
  }

  Future<void> create(CreateOrganizationRequest request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(organizationRepositoryProvider);
      await repository.createOrganization(request);
      
      
    });
  }
}
