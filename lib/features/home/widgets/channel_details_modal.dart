import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelDetailsModal extends ConsumerStatefulWidget {
  const ChannelDetailsModal({required this.channel, super.key});

  final WorkspaceChannel channel;

  @override
  ConsumerState<ChannelDetailsModal> createState() =>
      _ChannelDetailsModalState();
}

class _ChannelDetailsModalState extends ConsumerState<ChannelDetailsModal> {
  late String topic;
  late String description;

  @override
  void initState() {
    super.initState();
    topic = widget.channel.topic.isEmpty ? 'present' : widget.channel.topic;
    description = widget.channel.description;
  }

  Future<void> _saveChanges() async {
    final error = await ref
        .read(channelProvider.notifier)
        .updateChannelRemote(
          channel: widget.channel,
          name: widget.channel.name,
          description: description,
          topic: topic,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context);
  }

  Future<void> _editField({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: title == 'Description' ? 3 : 1,
            decoration: InputDecoration(hintText: 'Enter $title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    setState(() => onSaved(result));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 430,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.only(top: 20),
        color: colors.background,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${widget.channel.isPrivate ? 'Private ' : '# '}${widget.channel.name}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _SmallActionButton(icon: Icons.star_border, label: ''),
                    const SizedBox(width: 12),
                    _SmallActionButton(
                      icon: Icons.notifications_off_outlined,
                      label: 'Mute',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.divider),
                    bottom: BorderSide(color: colors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    _DetailsTab(label: 'About', active: true),
                    _DetailsTab(label: 'People', badge: '1'),
                    _DetailsTab(label: 'Agents'),
                    _DetailsTab(label: 'Files'),
                  ],
                ),
              ),
              Container(
                color: colors.background,
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _DetailsRow(
                        title: 'Topic',
                        value: topic.isEmpty ? 'Add topic' : topic,
                        onEdit: () => _editField(
                          title: 'Topic',
                          currentValue: topic,
                          onSaved: (value) => topic = value,
                        ),
                      ),
                      Divider(height: 1, color: colors.divider),
                      _DetailsRow(
                        title: 'Description',
                        value: description.isEmpty
                            ? 'Add a description'
                            : description,
                        onEdit: () => _editField(
                          title: 'Description',
                          currentValue: description,
                          onSaved: (value) => description = value,
                        ),
                      ),
                      Divider(height: 1, color: colors.divider),
                      _StaticDetailsRow(
                        title: 'Created by',
                        value: 'aimz on May 21, 2026',
                      ),
                      Divider(height: 1, color: colors.divider),
                      const _DangerRow(label: 'Archive channel for everyone'),
                      Divider(height: 1, color: colors.divider),
                      const _DangerRow(label: 'Leave channel'),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text('Save Changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: label.isEmpty ? const SizedBox.shrink() : Text(label),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.label, this.active = false, this.badge});

  final String label;
  final bool active;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? colors.textPrimary : colors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 11,
                  backgroundColor: colors.primary.withValues(alpha: 0.12),
                  child: Text(
                    badge!,
                    style: TextStyle(color: colors.primary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 52,
            height: 2,
            color: active ? colors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: _RowText(title: title, value: value),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _StaticDetailsRow extends StatelessWidget {
  const _StaticDetailsRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: _RowText(title: title, value: value),
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(color: colors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Text(
          label,
          style: TextStyle(
            color: context.colors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
