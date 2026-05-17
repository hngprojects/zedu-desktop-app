import 'package:zedu/features/features.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  const OrganizationRepositoryImpl(this._remoteDataSource);

  final OrganizationRemoteDataSource _remoteDataSource;

  @override
  Future<Organization> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    return _remoteDataSource.createOrganization(request);
  }

  @override
  Future<Organization> updateOrganization(
    UpdateOrganizationRequest request,
  ) async {
    return _remoteDataSource.updateOrganization(request);
  }

  @override
  Future<Organization> getOrganization(String orgId) async {
    return _remoteDataSource.getOrganization(orgId);
  }
}
