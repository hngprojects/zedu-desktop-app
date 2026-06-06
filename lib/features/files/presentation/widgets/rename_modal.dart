import 'package:zedu/core/core.dart';

class RenameModal extends StatefulWidget {
  final String currentName;
  final String title;

  const RenameModal({super.key, required this.currentName, required this.title});

  static Future<String?> show(BuildContext context, {required String currentName, required String title}) {
    return showDialog<String>(
      context: context,
      builder: (context) => RenameModal(currentName: currentName, title: title),
    );
  }

  @override
  State<RenameModal> createState() => _RenameModalState();
}

class _RenameModalState extends State<RenameModal> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    // Select name without extension if possible
    if (widget.currentName.contains('.')) {
      final extIndex = widget.currentName.lastIndexOf('.');
      _nameController.selection = TextSelection(baseOffset: 0, extentOffset: extIndex);
    } else {
      _nameController.selection = TextSelection(baseOffset: 0, extentOffset: widget.currentName.length);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Name',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintStyle: TextStyle(color: colors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderOutline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.borderOutline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty && val.trim() != widget.currentName) {
                  Navigator.of(context).pop(val.trim());
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final val = _nameController.text.trim();
                    if (val.isNotEmpty && val != widget.currentName) {
                      Navigator.of(context).pop(val);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
