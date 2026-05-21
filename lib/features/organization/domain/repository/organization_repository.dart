import 'package:zedu/features/features.dart';

abstract interface class OrganizationRepository {
  Future<Organization> createOrganization(CreateOrganizationRequest request);
  Future<Organization> updateOrganization(UpdateOrganizationRequest request);
  Future<Organization> getOrganization(String orgId);
  Future<void> deleteOrganization(String orgId);
  Future<List<Organization>> getOrganizations();
  Future<void> switchOrganization(String orgId);
}
