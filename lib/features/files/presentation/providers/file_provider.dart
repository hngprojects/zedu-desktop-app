import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// Provides the list of files
final filesProvider = FutureProvider.autoDispose<List<WorkspaceFile>>((
  ref,
) async {
  final repo = ref.watch(fileRepositoryProvider);
  return repo.getFiles();
});

// Provides the list of folders
final foldersProvider = FutureProvider.autoDispose<List<WorkspaceFolder>>((
  ref,
) async {
  final repo = ref.watch(fileRepositoryProvider);
  return repo.getFolders();
});

// Upload Progress State
class UploadProgressState {
  final bool isUploading;
  final double progress;
  final String? fileName;
  final WorkspaceFile? result;
  final String? error;

  UploadProgressState({
    this.isUploading = false,
    this.progress = 0.0,
    this.fileName,
    this.result,
    this.error,
  });

  UploadProgressState copyWith({
    bool? isUploading,
    double? progress,
    String? fileName,
    WorkspaceFile? result,
    String? error,
  }) {
    return UploadProgressState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      fileName: fileName ?? this.fileName,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

class UploadProgressNotifier extends Notifier<UploadProgressState> {
  @override
  UploadProgressState build() => UploadProgressState();

  Future<void> uploadFile(String filePath, String fileName) async {
    final repository = ref.read(fileRepositoryProvider);
    state = state.copyWith(
      isUploading: true,
      progress: 0.0,
      fileName: fileName,
      error: null,
      result: null,
    );
    try {
      final file = await repository.uploadFile(
        filePath: filePath,
        fileName: fileName,
        onSendProgress: (count, total) {
          if (total != -1) {
            state = state.copyWith(progress: count / total);
          }
        },
      );
      state = state.copyWith(isUploading: false, progress: 1.0, result: file);
      // Add a short delay to account for potential backend replication/indexing delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
      ref.invalidate(filesProvider); // Refresh the files list
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  void clear() {
    state = UploadProgressState();
  }
}

final uploadProgressProvider =
    NotifierProvider<UploadProgressNotifier, UploadProgressState>(
      UploadProgressNotifier.new,
    );
