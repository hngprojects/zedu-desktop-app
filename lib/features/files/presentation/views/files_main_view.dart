
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesMainView extends ConsumerStatefulWidget {
  const FilesMainView({super.key});

  @override
  ConsumerState<FilesMainView> createState() => _FilesMainViewState();
}

class _FilesMainViewState extends ConsumerState<FilesMainView> {
  int _selectedTabIndex = 1; // 0 = Folders, 1 = Files

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filesAsync = ref.watch(filteredFilesProvider);
    final filterState = ref.watch(filesFilterProvider);

    String categoryTitle = 'All files';
    if (filterState.category == 'my_files') categoryTitle = 'My files';
    if (filterState.category == 'shared') categoryTitle = 'Shared with me';
    if (filterState.category == 'deleted') categoryTitle = 'Deleted files';

    return Stack(
      children: [
        Container(
          color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search files...',
                          hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
                          prefixIcon: Icon(Icons.search, size: 16, color: colors.textHint),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: colors.borderOutline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: colors.borderOutline),
                          ),
                        ),
                        onChanged: (value) => ref.read(filesFilterProvider.notifier).updateSearch(value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          allowMultiple: false,
                          type: FileType.any,
                        );
                        if (result != null && result.files.isNotEmpty && context.mounted) {
                          final shouldUpload = await UploadConfirmModal.show(context, result.files);
                          if (shouldUpload == true) {
                            final file = result.files.first;
                            if (file.path != null) {
                              ref.read(uploadProgressProvider.notifier).uploadFile(file.path!, file.name);
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload file'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final folderName = await CreateFolderModal.show(context);
                        if (folderName != null) {
                          await Future<void>.delayed(const Duration(milliseconds: 500));
                          ref.invalidate(filesProvider);
                          ref.invalidate(foldersProvider);
                        }
                      },
                      icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                      label: const Text('New folder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: colors.borderOutline),

          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _InteractiveFilterDropdown(
                  label: filterState.fileType == null || filterState.fileType == 'All' 
                      ? 'File Type' : filterState.fileType!,
                  options: const ['All', 'Image', 'Document', 'Video', 'Audio', 'Archive'],
                  onSelected: (val) => ref.read(filesFilterProvider.notifier).updateFilter(
                    type: val == 'All' ? null : val,
                    uploader: filterState.uploaderId,
                    sort: filterState.sortOrder,
                  ),
                ),
                _InteractiveFilterDropdown(
                  label: filterState.sortOrder == null ? 'Sort' : 'Sort: ${filterState.sortOrder}',
                  options: const ['date_desc', 'date_asc', 'name_asc', 'name_desc', 'size_desc', 'size_asc'],
                  onSelected: (val) => ref.read(filesFilterProvider.notifier).updateFilter(
                    type: filterState.fileType,
                    uploader: filterState.uploaderId,
                    sort: val,
                  ),
                ),
                if (filterState.fileType != null || filterState.sortOrder != null)
                  TextButton(
                    onPressed: () => ref.read(filesFilterProvider.notifier).clearFilters(),
                    child: Text('Clear Filters', style: TextStyle(color: colors.primary, fontSize: 13)),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.borderOutline),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.borderOutline.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          ),
                        ),
                        child: Icon(Icons.menu, size: 18, color: colors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Icon(Icons.grid_view, size: 18, color: colors.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.borderOutline),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.borderOutline)),
            ),
            child: Row(
              children: [
                _buildTab('Folders', 0),
                const SizedBox(width: 24),
                _buildTab('Files', 1),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTabIndex == 0
                ? ref.watch(foldersProvider).when(
                    data: (folders) => FoldersListView(folders: folders),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error loading folders: $e')),
                  )
                : filesAsync.when(
                    data: (files) {
                      if (files.isEmpty) {
                        return const EmptyFilesState();
                      }
                      return FilesListView(files: files);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
          ),
        ],
      ),
    ),
    const UploadProgressOverlay(),
  ],
);
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    final colors = context.colors;
    
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textHint,
          ),
        ),
      ),
    );
  }
}

class EmptyFilesState extends StatelessWidget {
  const EmptyFilesState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No files yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload or drag & drop to get started',
            style: TextStyle(
              fontSize: 16,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveFilterDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _InteractiveFilterDropdown({
    required this.label,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: colors.background,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem(
            value: opt,
            height: 36,
            child: Text(opt, style: TextStyle(fontSize: 13, color: colors.textPrimary)),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderOutline),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 16, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
