import 'package:zedu/core/core.dart';
import '../providers/file_provider.dart';

class UploadProgressOverlay extends ConsumerWidget {
  const UploadProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(uploadProgressProvider);
    final colors = context.colors;

    if (!uploadState.isUploading && uploadState.error == null && uploadState.result == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 80, bottom: 24),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: colors.background,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderOutline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadState.isUploading
                              ? 'Uploading...'
                              : (uploadState.error != null ? 'Upload Failed' : 'Upload Complete'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: uploadState.error != null ? colors.error : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          uploadState.isUploading ? '${(uploadState.progress * 100).toStringAsFixed(0)}% completed' : '1 completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _ControlButton(icon: Icons.remove, onPressed: () {}),
                        const SizedBox(width: 8),
                        _ControlButton(
                          icon: Icons.close, 
                          onPressed: () => ref.read(uploadProgressProvider.notifier).clear(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderOutline),
              // File section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined, size: 20, color: colors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uploadState.fileName ?? 'Unknown file',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            uploadState.isUploading ? 'Uploading' : (uploadState.error != null ? uploadState.error! : 'Completed'),
                            style: TextStyle(
                              color: uploadState.isUploading ? colors.primary : (uploadState.error != null ? colors.error : colors.textSecondary),
                              fontSize: 12,
                            ),
                          ),
                          if (uploadState.isUploading) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: uploadState.progress,
                              backgroundColor: colors.borderOutline,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                              minHeight: 4,
                            ),
                          ]
                        ],
                      ),
                    ),
                    if (!uploadState.isUploading && uploadState.error == null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.check_circle_outline, color: colors.success, size: 18),
                      const SizedBox(width: 8),
                      Icon(Icons.close, color: colors.textHint, size: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderOutline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: colors.textPrimary),
      ),
    );
  }
}
