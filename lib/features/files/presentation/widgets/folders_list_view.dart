import 'package:zedu/core/core.dart';
import '../../domain/models/file_models.dart';
import '../../data/repositories/file_repository.dart';
import '../providers/file_provider.dart';
import 'rename_modal.dart';

class FoldersListView extends ConsumerWidget {
  final List<WorkspaceFolder> folders;

  const FoldersListView({super.key, required this.folders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: colors.textHint),
            const SizedBox(height: 16),
            Text(
              'No folders yet',
              style: TextStyle(color: colors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.borderOutline)),
            color: colors.background,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Name', style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 2,
                child: Text('Items', style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              SizedBox(
                width: 80,
                child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        
        // Table Body
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: folders.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderOutline.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _FolderTableRow(folder: folder);
            },
          ),
        ),
      ],
    );
  }
}

class _FolderTableRow extends ConsumerStatefulWidget {
  final WorkspaceFolder folder;

  const _FolderTableRow({required this.folder});

  @override
  ConsumerState<_FolderTableRow> createState() => _FolderTableRowState();
}

class _FolderTableRowState extends ConsumerState<_FolderTableRow> {
  bool _isHovered = false;

  void _handleAction(String action) async {
    final repo = ref.read(fileRepositoryProvider);
    try {
      if (action == 'rename') {
        final newName = await RenameModal.show(context, currentName: widget.folder.name, title: 'Rename Folder');
        if (newName != null) {
          await repo.renameFolder(widget.folder.id, newName);
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(foldersProvider);
        }
      } else if (action == 'delete') {
        // Simple confirmation
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete Folder'),
            content: Text('Are you sure you want to delete "${widget.folder.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await repo.deleteFolder(widget.folder.id);
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(foldersProvider);
        }
      }
    } catch (e) {
      debugPrint('Folder action failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? colors.primary.withValues(alpha: 0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Icon(Icons.folder, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.folder.name,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.folder.itemCount} items',
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PopupMenuButton<String>(
                    onSelected: _handleAction,
                    icon: Icon(Icons.more_vert, size: 20, color: colors.textPrimary),
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
