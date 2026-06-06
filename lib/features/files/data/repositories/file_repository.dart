import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return FileRepository(apiClient);
});

class FileRepository {
  final ApiBaseService _apiClient;

  FileRepository(this._apiClient);

  Future<WorkspaceFile> uploadFile({
    required String filePath,
    required String fileName,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'files': [
        await MultipartFile.fromFile(filePath, filename: fileName),
      ],
    });

    final response = await _apiClient.post<Map<String, dynamic>>(
      path: '/files/upload-files',
      data: formData,
      onSendProgress: onSendProgress,
      headers: {'Content-Type': 'multipart/form-data'},
    );

    // Assuming the API returns a list of files or a single file in 'data'
    final data = response.data['data'];
    if (data is List && data.isNotEmpty) {
      return WorkspaceFile.fromJson(data.first as Map<String, dynamic>);
    } else if (data is Map<String, dynamic>) {
      return WorkspaceFile.fromJson(data);
    }
    throw Exception('Failed to parse uploaded file');
  }

  Future<List<WorkspaceFile>> getFiles({
    String? channelId,
    String? folderId,
    int page = 1,
    int limit = 20,
  }) async {
    String path = '/files';
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'limit': limit,
    };
    if (channelId != null) {
      path = '/channels/$channelId/files';
    } else if (folderId != null) {
      queryParameters['folder_id'] = folderId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      path: path,
      queryParameters: queryParameters,
    );

    try {
      await File('/tmp/zedu_files_response.txt').writeAsString(response.data.toString());
    } catch (_) {}

    final data = response.data['data'];
    if (data is List) {
      return data.map((json) => WorkspaceFile.fromJson(json as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic> && data['files'] is List) {
      final filesList = data['files'] as List;
      return filesList.map((json) => WorkspaceFile.fromJson(json as Map<String, dynamic>)).toList();
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      final filesList = data['data'] as List;
      return filesList.map((json) => WorkspaceFile.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<WorkspaceFolder>> getFolders({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/files/folders',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data['data'];
    if (data is List) {
      return data.map((json) => WorkspaceFolder.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<WorkspaceFolder> createFolder(String name) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      path: '/files/folders',
      data: {'name': name, 'folder_name': name},
    );

    final data = response.data['data'];
    return WorkspaceFolder.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFiles(List<String> ids, {bool permanent = false}) async {
    await _apiClient.delete<Map<String, dynamic>>(
      path: '/files',
      data: {
        'ids': ids,
        'permanent': permanent,
      },
    );
  }

  Future<void> renameFolder(String id, String newName) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/files/folders/$id',
      data: {'folder_name': newName},
    );
  }

  Future<void> deleteFolder(String id) async {
    await _apiClient.delete<Map<String, dynamic>>(
      path: '/files/folders/$id',
    );
  }

  Future<void> renameFile(String id, String newName) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/files/file/$id',
      data: {'file_name': newName},
    );
  }

  Future<void> moveFile(String id, String folderId) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/files/$id/move',
      data: {'folder_id': folderId},
    );
  }
}
