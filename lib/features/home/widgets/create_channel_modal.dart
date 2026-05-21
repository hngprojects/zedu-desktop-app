import 'package:zedu/core/core.dart';

class CreateChannelModal extends StatefulWidget {
  const CreateChannelModal({super.key});

  @override
  State<CreateChannelModal> createState() => _CreateChannelModalState();
}

class _CreateChannelModalState extends State<CreateChannelModal> {
  final _nameController = TextEditingController();

  String selectedCategory = 'General';
  String selectedType = 'Public';
  String? error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createChannel() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => error = 'Channel name is required');
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'category': selectedCategory,
      'type': selectedType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        color: colors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Create a Channel',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.divider),
            const SizedBox(height: 20),
            Text(
              'Channel name',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
              decoration: InputDecoration(
                hintText: 'e.g. project-x',
                errorText: error,
                suffixText: '40',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Channel Visibility',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _VisibilityOption(
              value: 'Public',
              groupValue: selectedType,
              label: 'Public - Anyone in aimz',
              onChanged: (value) => setState(() => selectedType = value),
            ),
            _VisibilityOption(
              value: 'Private',
              groupValue: selectedType,
              label: 'Private - Only specific people',
              onChanged: (value) => setState(() => selectedType = value),
            ),
            const SizedBox(height: 16),
            Divider(color: colors.divider),
            const SizedBox(height: 20),
            Text(
              'Note: Channels can house as many members as necessary.',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 18,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _createChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                  ),
                  child: const Text('Create Channel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 1.4),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}