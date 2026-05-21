import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import 'package:http_parser/http_parser.dart';

abstract interface class OrganizationRemoteDataSource {
  Future<OrganizationModel> createOrganization(
    CreateOrganizationRequest request,
  );
  Future<OrganizationModel> updateOrganization(
    UpdateOrganizationRequest request,
  );
  Future<OrganizationModel> getOrganization(String orgId);
  Future<void> deleteOrganization(String orgId);
  Future<List<OrganizationModel>> getOrganizations();
  Future<void> switchOrganization(String orgId);
}

class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  const OrganizationRemoteDataSourceImpl({
    required AppConfig config,
    required ApiBaseService apiBaseService,
  }) : _config = config,
       _apiBaseService = apiBaseService;

  final AppConfig _config;
  final ApiBaseService _apiBaseService;

  static const _tag = 'OrganizationRemoteDataSource';

  @override
  Future<OrganizationModel> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for POST /organisations', tag: _tag);
        return OrganizationModel(
          id: 'mock-id',
          name: request.name ?? 'Mock Org',
          description: request.description ?? 'Mock Description',
          email: request.email ?? 'mock@org.com',
          country: request.country ?? 'Mock Country',
          industry: request.type ?? 'Mock Industry',
          location: request.location ?? 'Mock Location',
          ownerId: 'mock-owner-id',
          logoUrl: request.logoUrl ?? 'mock-logo-url',
          channelsCount: 0,
          totalMessagesCount: 0,
          userRole: 'owner',
          organizationPlan: OrganizationPlanModel(
            id: 'mock-plan-id',
            organizationId: 'mock-id',
            planId: 'mock-plan-id',
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(days: 30)),
            status: 'Active',
            sessionId: 'mock-session-id',
            invoicePdfUrl: 'mock-pdf-url',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            planDetails: OrganizationPlanDetailsModel(
              id: 'mock-plan-details-id',
              name: 'Mock Plan',
              description: 'Mock Plan Description',
              benefits: [],
              fee: 0,
              credits: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      AppLogger.d('POST /organisations — ${request.name}', tag: _tag);
      final response = await _apiBaseService.post<Map<String, dynamic>>(
        path: '/organisations',
        data: request.toJson(),
      );

      final payload = response.data['data'] as Map<String, dynamic>;
      return OrganizationModel.fromJson(payload);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /organisation response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/organisation');
    }
  }

  @override
  Future<OrganizationModel> updateOrganization(
    UpdateOrganizationRequest request,
  ) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d(
          'Using mock data for UPDATE /organisations/{orgId}',
          tag: _tag,
        );
        return OrganizationModel(
          id: request.orgId,
          name: request.name ?? 'Mock Org',
          description: request.description ?? 'Mock Description',
          email: request.email ?? 'mock@org.com',
          country: request.country ?? 'Mock Country',
          industry: request.type ?? 'Mock Industry',
          location: request.location ?? 'Mock Location',
          ownerId: 'mock-owner-id',
          logoUrl: request.removeLogo
              ? ''
              : (request.logoFile?.path ?? request.logoUrl ?? 'mock-logo-url'),
          channelsCount: 0,
          totalMessagesCount: 0,
          userRole: 'owner',
          organizationPlan: OrganizationPlanModel(
            id: 'mock-plan-id',
            organizationId: 'mock-id',
            planId: 'mock-plan-id',
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(days: 30)),
            status: 'Active',
            sessionId: 'mock-session-id',
            invoicePdfUrl: 'mock-pdf-url',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            planDetails: OrganizationPlanDetailsModel(
              id: 'mock-plan-details-id',
              name: 'Mock Plan',
              description: 'Mock Plan Description',
              benefits: [],
              fee: 0,
              credits: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      var currentRequest = request;

      if (request.logoFile != null) {
        AppLogger.d('Uploading logo file to /files/upload-files', tag: _tag);
        final file = request.logoFile!;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.name,
            contentType: _getMediaType(file.name),
          ),
          'files': [
            await MultipartFile.fromFile(
              file.path,
              filename: file.name,
              contentType: _getMediaType(file.name),
            ),
          ],
          'image': await MultipartFile.fromFile(
            file.path,
            filename: file.name,
            contentType: _getMediaType(file.name),
          ),
          'logo': await MultipartFile.fromFile(
            file.path,
            filename: file.name,
            contentType: _getMediaType(file.name),
          ),
        });

        final uploadResponse = await _apiBaseService.post<Map<String, dynamic>>(
          path: '/files/upload-files',
          data: formData,
        );

        final uploadedUrl = _findFirstUrl(uploadResponse.data);

        if (uploadedUrl == null) {
          throw ApiFailure(
            message: 'Failed to retrieve uploaded logo URL from response: ${uploadResponse.data}',
            path: '/files/upload-files',
            kind: ApiFailureKind.client,
          );
        }

        AppLogger.d('Logo uploaded successfully: $uploadedUrl', tag: _tag);
        currentRequest = request.copyWith(logoUrl: uploadedUrl);
      }

      AppLogger.d(
        'UPDATE /organisations/{orgId} — ${currentRequest.orgId}',
        tag: _tag,
      );
      final response = await _apiBaseService.put<Map<String, dynamic>>(
        path: '/organisations/${currentRequest.orgId}',
        data: currentRequest.toJson(),
      );
      final payload = response.data['data'] as Map<String, dynamic>;
      return OrganizationModel.fromJson(payload);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /organisations response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/organisations');
    }
  }

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d(
          'Using mock data for GET /organisations/$orgId',
          tag: _tag,
        );
        return OrganizationModel(
          id: orgId,
          name: 'Mock Organization',
          description: 'Mock Description',
          email: 'mock@org.com',
          country: 'Mock Country',
          industry: 'Mock Industry',
          location: 'Mock Location',
          ownerId: 'mock-owner-id',
          logoUrl: 'mock-logo-url',
          channelsCount: 0,
          totalMessagesCount: 0,
          userRole: 'owner',
          organizationPlan: OrganizationPlanModel(
            id: 'mock-plan-id',
            organizationId: orgId,
            planId: 'mock-plan-id',
            startedAt: DateTime.now(),
            endedAt: DateTime.now().add(const Duration(days: 30)),
            status: 'Active',
            sessionId: 'mock-session-id',
            invoicePdfUrl: 'mock-pdf-url',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            planDetails: OrganizationPlanDetailsModel(
              id: 'mock-plan-details-id',
              name: 'Mock Plan',
              description: 'Mock Plan Description',
              benefits: [],
              fee: 0,
              credits: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      AppLogger.d('GET /organisations/$orgId', tag: _tag);
      final response = await _apiBaseService.get<Map<String, dynamic>>(
        path: '/organisations/$orgId',
      );
      final payload = response.data['data'] as Map<String, dynamic>;
      return OrganizationModel.fromJson(payload);
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /organisations/$orgId response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/organisations/$orgId');
    }
  }

  @override
  Future<void> deleteOrganization(String orgId) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for DELETE /organisations/$orgId', tag: _tag);
        return;
      }
      AppLogger.d('DELETE /organisations/$orgId', tag: _tag);
      await _apiBaseService.delete<Map<String, dynamic>>(
        path: '/organisations/$orgId',
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /organisations/$orgId delete response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/organisations/$orgId');
    }
  }

  @override
  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for GET /users/organisations', tag: _tag);
        return _mockOrganizations;
      }
      AppLogger.d('GET /users/organisations', tag: _tag);
      final response = await _apiBaseService.get<Map<String, dynamic>>(
        path: '/users/organisations',
      );
      final data = response.data['data'] as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(OrganizationModel.fromJson)
          .toList();
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /users/organisations response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/users/organisations');
    }
  }

  @override
  Future<void> switchOrganization(String orgId) async {
    try {
      if (_config.usesMockData) {
        AppLogger.d('Using mock data for POST /users/switch-org', tag: _tag);
        return;
      }
      AppLogger.d('POST /users/switch-org — $orgId', tag: _tag);
      await _apiBaseService.post<Map<String, dynamic>>(
        path: '/users/switch-org',
        data: {'current_org': orgId},
      );
    } on ApiFailure {
      rethrow;
    } catch (error) {
      AppLogger.e(
        'Failed to parse /users/switch-org response',
        tag: _tag,
        error: error,
      );
      throw ApiFailure.fromParsingError(error, path: '/users/switch-org');
    }
  }
  MediaType? _getMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'png') return MediaType('image', 'png');
    if (ext == 'jpg' || ext == 'jpeg') return MediaType('image', 'jpeg');
    if (ext == 'gif') return MediaType('image', 'gif');
    if (ext == 'webp') return MediaType('image', 'webp');
    return MediaType('application', 'octet-stream');
  }

  String? _findFirstUrl(dynamic json) {
    if (json is String) {
      final value = json.trim();
      if (value.startsWith('http://') || value.startsWith('https://')) {
        return value;
      }
    } else if (json is Map) {
      for (final value in json.values) {
        final url = _findFirstUrl(value);
        if (url != null) return url;
      }
    } else if (json is List) {
      for (final item in json) {
        final url = _findFirstUrl(item);
        if (url != null) return url;
      }
    }
    return null;
  }
}

final _mockPlan = OrganizationPlanModel(
  id: 'mock-plan-id',
  organizationId: 'mock-id',
  planId: 'mock-plan-id',
  startedAt: DateTime.now(),
  endedAt: DateTime.now().add(const Duration(days: 30)),
  status: 'Active',
  sessionId: 'mock-session-id',
  invoicePdfUrl: 'mock-pdf-url',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  planDetails: OrganizationPlanDetailsModel(
    id: 'mock-plan-details-id',
    name: 'Zedu Free',
    description: 'Mock Plan Description',
    benefits: [],
    fee: 0,
    credits: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);

final List<OrganizationModel> _mockOrganizations = [
  OrganizationModel(
    id: 'org-hng',
    name: 'HNG Workspace',
    description: 'HNG Internship Workspace',
    email: 'hello@hng.tech',
    country: 'Nigeria',
    industry: 'user default org',
    location: 'Lagos',
    ownerId: 'user-1',
    logoUrl: '',
    channelsCount: 15,
    totalMessagesCount: 12050,
    userRole: 'owner',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-tf',
    name: 'TeamFlow Collective',
    description: 'Workspace for TeamFlow',
    email: 'team@teamflow.com',
    country: 'USA',
    industry: 'Software',
    location: 'San Francisco',
    ownerId: 'user-2',
    logoUrl: '',
    channelsCount: 5,
    totalMessagesCount: 300,
    userRole: 'member',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-cc',
    name: 'Coffee & Code House',
    description: 'Coffee lovers and coders',
    email: 'coffee@code.com',
    country: 'UK',
    industry: 'Technology',
    location: 'London',
    ownerId: 'user-3',
    logoUrl: '',
    channelsCount: 2,
    totalMessagesCount: 50,
    userRole: 'member',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-ch',
    name: 'ConnectHub',
    description: 'ConnectHub main space',
    email: 'info@connecthub.com',
    country: 'Canada',
    industry: 'Networking',
    location: 'Toronto',
    ownerId: 'user-4',
    logoUrl: '',
    channelsCount: 8,
    totalMessagesCount: 1200,
    userRole: 'admin',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-ad',
    name: 'Apex Digital',
    description: 'Apex Digital agency',
    email: 'hello@apexdigital.com',
    country: 'Australia',
    industry: 'Marketing',
    location: 'Sydney',
    ownerId: 'user-5',
    logoUrl: '',
    channelsCount: 12,
    totalMessagesCount: 5400,
    userRole: 'member',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-lb',
    name: 'LoopBase',
    description: 'LoopBase engineering',
    email: 'eng@loopbase.io',
    country: 'Germany',
    industry: 'Software',
    location: 'Berlin',
    ownerId: 'user-6',
    logoUrl: '',
    channelsCount: 4,
    totalMessagesCount: 200,
    userRole: 'member',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  OrganizationModel(
    id: 'org-cn',
    name: 'CreativeNest',
    description: 'Creative design agency',
    email: 'design@creativenest.com',
    country: 'Netherlands',
    industry: 'Design',
    location: 'Amsterdam',
    ownerId: 'user-7',
    logoUrl: '',
    channelsCount: 6,
    totalMessagesCount: 800,
    userRole: 'member',
    organizationPlan: _mockPlan,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
