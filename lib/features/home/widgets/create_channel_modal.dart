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
    final textTheme = context.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.s(12)),
      ),
      child: Container(
        width: context.s(520),
        padding: context.all(24),
        color: colors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Create a Channel',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textPrimary),
                ),
              ],
            ),
            context.gapV(12),
            Divider(color: colors.divider),
            context.gapV(20),
            AppTextField(
              label: 'Channel name',
              controller: _nameController,
              hint: 'e.g. project-x',
              maxLength: 40,
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
              validator: (_) => error,
            ),
            if (error != null) ...[
              context.gapV(6),
              Text(
                error!,
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            context.gapV(22),
            Text(
              'Channel Visibility',
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            context.gapV(10),
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
            context.gapV(16),
            Divider(color: colors.divider),
            context.gapV(18),
            Text(
              'Note: Channels can house as many members as necessary.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            context.gapV(28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.outlined(
                  label: 'Cancel',
                  expand: false,
                  height: context.s(48),
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: context.symmetric(horizontal: 24),
                  ),
                ),
                context.gapH(16),
                AppButton(
                  label: 'Create Channel',
                  expand: false,
                  height: context.s(48),
                  onPressed: _createChannel,
                  style: ElevatedButton.styleFrom(
                    padding: context.symmetric(horizontal: 26),
                  ),
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
    final textTheme = context.textTheme;
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: context.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: context.s(18),
              height: context.s(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 1.4),
              ),
              child: Center(
                child: Container(
                  width: context.s(10),
                  height: context.s(10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            context.gapH(12),
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
