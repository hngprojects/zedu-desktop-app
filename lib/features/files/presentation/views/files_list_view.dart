import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesListView extends StatelessWidget {
  final List<WorkspaceFile> files;

  const FilesListView({super.key, required this.files});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d > 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  IconData _getIconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType.startsWith('image/')) return Icons.image_outlined;
    if (mimeType.startsWith('video/')) return Icons.video_file_outlined;
    if (mimeType.startsWith('audio/')) return Icons.audio_file_outlined;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mimeType.contains('zip') || mimeType.contains('tar') || mimeType.contains('compressed')) return Icons.folder_zip_outlined;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel') || mimeType.contains('csv')) return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                child: Text(
                  'Name',
                  style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Owner',
                  style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Access',
                  style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Size',
                  style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Actions',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textHint, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        // Table Body
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: files.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: colors.borderOutline.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final file = files[index];
              return _FileTableRow(
                file: file,
                icon: _getIconForMimeType(file.mimeType),
                formattedSize: _formatBytes(file.size),
                formattedDate: _formatDate(file.createdAt),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FileTableRow extends ConsumerStatefulWidget {
  final WorkspaceFile file;
  final IconData icon;
  final String formattedSize;
  final String formattedDate;

  const _FileTableRow({
    required this.file,
    required this.icon,
    required this.formattedSize,
    required this.formattedDate,
  });

  @override
  ConsumerState<_FileTableRow> createState() => _FileTableRowState();
}

class _FileTableRowState extends ConsumerState<_FileTableRow> {
  bool _isHovered = false;

  void _openFile() async {
    final link = widget.file.fileLink;
    if (link != null && link.isNotEmpty) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _handleAction(String action) async {
    final repo = ref.read(fileRepositoryProvider);
    try {
      if (action == 'rename') {
        final newName = await RenameModal.show(context, currentName: widget.file.fileName, title: 'Rename File');
        if (newName != null) {
          await repo.renameFile(widget.file.id, newName);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          ref.invalidate(filesProvider);
        }
      } else if (action == 'move') {
        final folderId = await MoveFileModal.show(context, file: widget.file);
        if (folderId != null) {
          await repo.moveFile(widget.file.id, folderId);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          ref.invalidate(filesProvider);
        }
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Delete File'),
            content: Text('Are you sure you want to delete "${widget.file.fileName}"?'),
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
          await repo.deleteFiles([widget.file.id]);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          ref.invalidate(filesProvider);
        }
      }
    } catch (e) {
      debugPrint('File action failed: $e');
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
              child: InkWell(
                onTap: _openFile,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: colors.textPrimary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.file.fileName,
                          style: TextStyle(
                            color: _isHovered ? colors.primary : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: _isHovered ? TextDecoration.underline : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: colors.borderOutline,
                    child: Text(
                      'AU',
                      style: TextStyle(fontSize: 10, color: colors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anonymous...',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Public',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                widget.formattedSize,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                ),
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
                        value: 'move',
                        child: Text('Move to Folder'),
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
