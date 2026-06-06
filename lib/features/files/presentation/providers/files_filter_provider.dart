import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesFilterState {
  final String category; // 'all', 'my_files', 'shared', 'deleted'
  final String? searchQuery;
  final String? fileType;
  final String? uploaderId;
  final String? sortOrder;

  const FilesFilterState({
    this.category = 'all',
    this.searchQuery,
    this.fileType,
    this.uploaderId,
    this.sortOrder,
  });

  FilesFilterState copyWith({
    String? category,
    String? searchQuery,
    String? fileType,
    String? uploaderId,
    String? sortOrder,
  }) {
    return FilesFilterState(
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      fileType: fileType ?? this.fileType,
      uploaderId: uploaderId ?? this.uploaderId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class FilesFilterNotifier extends Notifier<FilesFilterState> {
  @override
  FilesFilterState build() => const FilesFilterState();

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateSearch(String? query) {
    state = state.copyWith(searchQuery: query?.isEmpty == true ? null : query);
  }

  void updateFilter({String? type, String? uploader, String? sort}) {
    state = state.copyWith(
      fileType: type,
      uploaderId: uploader,
      sortOrder: sort,
    );
  }

  void clearFilters() {
    state = FilesFilterState(category: state.category);
  }
}

final filesFilterProvider =
    NotifierProvider<FilesFilterNotifier, FilesFilterState>(
      FilesFilterNotifier.new,
    );

final filteredFilesProvider = Provider.autoDispose<AsyncValue<List<WorkspaceFile>>>((
  ref,
) {
  final filesAsync = ref.watch(filesProvider);
  final filter = ref.watch(filesFilterProvider);

  return filesAsync.whenData((files) {
    var result = List<WorkspaceFile>.from(files);

    // Filter by Category
    // Note: Assuming 'my_files' maps to files uploaded by the current user.
    // If we don't have current user ID here easily, we might need to fetch it from auth provider.
    if (filter.category == 'my_files') {
      // TODO: Filter by current user ID when available
    } else if (filter.category == 'shared') {
      result = result.where((f) => f.isShareable == true).toList();
    } else if (filter.category == 'deleted') {
      // Assuming deleted files are not returned by default, or have a specific flag.
      // If no flag exists, this might be handled completely by the backend.
    }

    // Filter by Search Query
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      result = result
          .where((f) => f.fileName.toLowerCase().contains(q))
          .toList();
    }

    // Filter by File Type
    if (filter.fileType != null &&
        filter.fileType!.isNotEmpty &&
        filter.fileType != 'All') {
      final type = filter.fileType!.toLowerCase();
      result = result.where((f) {
        if (type == 'image') return f.isImage;
        if (type == 'document') return f.isDocument;
        if (type == 'video') return f.isVideo;
        if (type == 'audio') return f.isAudio;
        if (type == 'archive') return f.isArchive;
        return false;
      }).toList();
    }

    // Sort Order
    if (filter.sortOrder != null) {
      switch (filter.sortOrder) {
        case 'name_asc':
          result.sort((a, b) => a.fileName.compareTo(b.fileName));
          break;
        case 'name_desc':
          result.sort((a, b) => b.fileName.compareTo(a.fileName));
          break;
        case 'date_desc':
          result.sort(
            (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
              a.updatedAt ?? a.createdAt ?? DateTime(0),
            ),
          );
          break;
        case 'date_asc':
          result.sort(
            (a, b) => (a.updatedAt ?? a.createdAt ?? DateTime(0)).compareTo(
              b.updatedAt ?? b.createdAt ?? DateTime(0),
            ),
          );
          break;
        case 'size_desc':
          result.sort((a, b) => b.size.compareTo(a.size));
          break;
        case 'size_asc':
          result.sort((a, b) => a.size.compareTo(b.size));
          break;
      }
    } else {
      // Default sort by date desc
      result.sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
          a.updatedAt ?? a.createdAt ?? DateTime(0),
        ),
      );
    }

    return result;
  });
});
