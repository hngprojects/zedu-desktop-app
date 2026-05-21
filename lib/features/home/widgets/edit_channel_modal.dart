import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class EditChannelModal extends StatefulWidget {
  const EditChannelModal({required this.channel, super.key});

  final WorkspaceChannel channel;

  @override
  State<EditChannelModal> createState() => _EditChannelModalState();
}

class _EditChannelModalState extends State<EditChannelModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _topicController;

  String? error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel.name);
    _descriptionController = TextEditingController(
      text: widget.channel.description,
    );
    _topicController = TextEditingController(text: widget.channel.topic);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => error = 'Channel name is required');
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'description': _descriptionController.text.trim(),
      'topic': _topicController.text.trim(),
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
                  'Edit Channel',
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
            _LabeledInput(
              label: 'Channel name',
              controller: _nameController,
              errorText: error,
              hintText: 'e.g. project-x',
              maxLengthLabel: '40',
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
            ),
            const SizedBox(height: 18),
            _LabeledInput(
              label: 'Topic',
              controller: _topicController,
              hintText: 'e.g. Course updates',
            ),
            const SizedBox(height: 18),
            _LabeledInput(
              label: 'Description',
              controller: _descriptionController,
              hintText: 'Describe what this channel is for',
              maxLines: 3,
            ),
            const SizedBox(height: 22),
            Divider(color: colors.divider),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.maxLengthLabel,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final String? maxLengthLabel;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixText: maxLengthLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }
}