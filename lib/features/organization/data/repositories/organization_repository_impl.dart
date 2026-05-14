import 'package:zedu/features/features.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  const OrganizationRepositoryImpl(this._remoteDataSource);

  final OrganizationRemoteDataSource _remoteDataSource;

  @override
  Future<Organization> createOrganization(CreateOrganizationRequest request) async {
    return _remoteDataSource.createOrganization(request);
  }
}
