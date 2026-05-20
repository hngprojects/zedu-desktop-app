import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmMessageComposer extends StatefulWidget {
  final String recipientName;
  final ValueChanged<String>? onSend;

  const DmMessageComposer({
    super.key,
    required this.recipientName,
    this.onSend,
  });

  @override
  State<DmMessageComposer> createState() => _DmMessageComposerState();
}

class _DmMessageComposerState extends State<DmMessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  _ToolbarIcon(icon: Icons.format_bold, colors: colors),
                  _ToolbarIcon(icon: Icons.format_italic, colors: colors),
                  _ToolbarIcon(icon: Icons.strikethrough_s, colors: colors),
                  _ToolbarIcon(icon: Icons.link, colors: colors),
                  _ToolbarIcon(
                    icon: Icons.format_list_numbered,
                    colors: colors,
                  ),
                  _ToolbarIcon(
                    icon: Icons.format_list_bulleted,
                    colors: colors,
                  ),
                  _ToolbarIcon(icon: Icons.code, colors: colors),
                  _ToolbarIcon(
                    icon: Icons.format_quote_outlined,
                    colors: colors,
                  ),
                ],
              ),
            ),
            Divider(height: 16, color: colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      (HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed)) {
                    _handleSend();
                  }
                },
                child: PasteRegion(
                  onPaste: (PasteEvent event) {
                    final reader = event.data;
                    if (reader.canProvide(Formats.png) || reader.canProvide(Formats.jpeg)) {
                      // Handled file pasting here
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.recipientName}',
                      hintStyle: TextStyle(
                        color: colors.textHint.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Bottom action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _ToolbarIcon(icon: Icons.add, colors: colors),
                  const SizedBox(width: 4),
                  _ToolbarIcon(
                    icon: Icons.text_fields,
                    colors: colors,
                    label: 'Aa',
                  ),
                  _ToolbarIcon(
                    icon: Icons.emoji_emotions_outlined,
                    colors: colors,
                  ),
                  _ToolbarIcon(
                    icon: Icons.alternate_email,
                    colors: colors,
                  ),
                  _ToolbarIcon(icon: Icons.tag, colors: colors),
                  _ToolbarIcon(
                    icon: Icons.data_object,
                    colors: colors,
                  ),
                  _ToolbarIcon(
                    icon: Icons.attach_file_outlined,
                    colors: colors,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _handleSend,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.send_rounded,
                        color: colors.textHint.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
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

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final AppColorScheme colors;
  final String? label;

  const _ToolbarIcon({
    required this.icon,
    required this.colors,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                color: colors.textHint.withValues(alpha: 0.75),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )
          : Icon(
              icon,
              size: 18,
              color: colors.textHint.withValues(alpha: 0.75),
            ),
    );
  }
}
