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

  @override
  Future<void> deleteOrganization(String orgId) async {
    try {
      await _remoteDataSource.deleteOrganization(orgId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Organization>> getOrganizations() async {
    try {
      final models = await _remoteDataSource.getOrganizations();
      return models.map((e) => e.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> switchOrganization(String orgId) async {
    try {
      await _remoteDataSource.switchOrganization(orgId);
    } catch (e) {
      rethrow;
    }
  }
}
