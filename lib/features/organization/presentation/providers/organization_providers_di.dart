import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final organizationRemoteDataSourceProvider = Provider<OrganizationRemoteDataSource>(
  (ref) => OrganizationRemoteDataSourceImpl(
    config: locator<AppConfig>(),
    apiBaseService: locator<ApiBaseService>(),
  ),
);

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepositoryImpl(ref.watch(organizationRemoteDataSourceProvider)),
);

final createOrganizationControllerProvider = AsyncNotifierProvider<CreateOrganizationController, void>(
  CreateOrganizationController.new,
);
