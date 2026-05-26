import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http_parser/http_parser.dart';

import 'package:zedu/core/core.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return FileRepository(apiClient);
});

class FileRepository {
  final ApiBaseService _apiClient;

  FileRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> uploadFiles(List<XFile> files) async {
    if (files.isEmpty) return [];

    final multipartFiles = <MultipartFile>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      multipartFiles.add(
        MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: file.mimeType != null ? MediaType.parse(file.mimeType!) : null,
        ),
      );
    }

    final formData = FormData.fromMap({
      'files': multipartFiles,
    });

    final response = await _apiClient.post<Map<String, dynamic>>(
      path: ApiEndpoints.uploadFiles,
      data: formData,
    );

    final data = response.data;
    final rawList = data['data'];
    if (rawList is List) {
      return rawList
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}
