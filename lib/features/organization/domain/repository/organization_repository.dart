import 'package:zedu/features/features.dart';

abstract interface class OrganizationRepository {
  Future<Organization> createOrganization(CreateOrganizationRequest request);
}
