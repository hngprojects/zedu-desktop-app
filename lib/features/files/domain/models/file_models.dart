class WorkspaceFile {
  final String id;
  final String fileName;
  final String? fileType;
  final String? mimeType;
  final String? fileLink;
  final int size;
  final String? organisationId;
  final String? userId;
  final String? folderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastAccessedAt;
  final String? accessType;
  final bool? isShareable;

  WorkspaceFile({
    required this.id,
    required this.fileName,
    this.fileType,
    this.mimeType,
    this.fileLink,
    this.size = 0,
    this.organisationId,
    this.userId,
    this.folderId,
    this.createdAt,
    this.updatedAt,
    this.lastAccessedAt,
    this.accessType,
    this.isShareable,
  });

  factory WorkspaceFile.fromJson(Map<String, dynamic> json) {
    return WorkspaceFile(
      id: json['id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'Unknown',
      fileType: json['file_type'] as String?,
      mimeType: json['mime_type'] as String?,
      fileLink: json['file_link'] as String?,
      size: json['size'] as int? ?? 0,
      organisationId: json['organisation_id'] as String?,
      userId: json['user_id'] as String?,
      folderId: json['folder_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.tryParse(json['last_accessed_at'] as String)
          : null,
      accessType: json['access_type'] as String?,
      isShareable: json['is_shareable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_type': fileType,
      'mime_type': mimeType,
      'file_link': fileLink,
      'size': size,
      'organisation_id': organisationId,
      'user_id': userId,
      'folder_id': folderId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'access_type': accessType,
      'is_shareable': isShareable,
    };
  }

  // Type Helpers
  bool get isImage =>
      mimeType?.startsWith('image/') == true ||
      _hasExtension(['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp']);
  bool get isVideo =>
      mimeType?.startsWith('video/') == true ||
      _hasExtension(['mp4', 'mov', 'avi', 'mkv', 'webm']);
  bool get isAudio =>
      mimeType?.startsWith('audio/') == true ||
      _hasExtension(['mp3', 'wav', 'ogg', 'm4a']);
  bool get isDocument => _hasExtension([
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
  ]);
  bool get isArchive => _hasExtension(['zip', 'rar', '7z', 'tar', 'gz']);

  bool _hasExtension(List<String> extensions) {
    if (fileName.isEmpty || !fileName.contains('.')) return false;
    final ext = fileName.split('.').last.toLowerCase();
    return extensions.contains(ext);
  }
}

class WorkspaceFolder {
  final String id;
  final String name;
  final int itemCount;
  final String? organisationId;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkspaceFolder({
    required this.id,
    required this.name,
    this.itemCount = 0,
    this.organisationId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceFolder.fromJson(Map<String, dynamic> json) {
    return WorkspaceFolder(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'New Folder',
      itemCount: json['item_count'] as int? ?? 0,
      organisationId: json['organisation_id'] as String?,
      userId: json['user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'item_count': itemCount,
      'organisation_id': organisationId,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
