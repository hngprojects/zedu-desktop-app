import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmMessageComposer extends ConsumerStatefulWidget {
  final String recipientName;
  final String channelId;
  final ValueChanged<String>? onSend;
  final ValueChanged<List<XFile>>? onFilesAttached;

  const DmMessageComposer({
    super.key,
    required this.recipientName,
    required this.channelId,
    this.onSend,
    this.onFilesAttached,
  });

  @override
  ConsumerState<DmMessageComposer> createState() => _DmMessageComposerState();
}

class _DmMessageComposerState extends ConsumerState<DmMessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isEditMode = false;
  String? _editingMessageId;

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isEditMode && _editingMessageId != null) {
      ref
          .read(chatHistoryProvider(widget.channelId))
          .saveEdit(_editingMessageId!, text);
      _exitEditMode();
    } else {
      widget.onSend?.call(text);
    }
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _enterEditMode(String messageId, String content) {
    setState(() {
      _isEditMode = true;
      _editingMessageId = messageId;
      _controller.text = content;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: content.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _editingMessageId = null;
      _controller.clear();
    });
    ref.read(chatHistoryProvider(widget.channelId)).cancelEditing();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _handleSend();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape && _isEditMode) {
      _exitEditMode();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp && _controller.text.isEmpty) {
      final history = ref.read(chatHistoryProvider(widget.channelId));
      final lastId = history.lastSentMessageId;
      final lastContent = history.lastSentMessageContent;
      if (lastId != null && lastContent != null) {
        _enterEditMode(lastId, lastContent);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _wrapSelection(String before, [String? after]) {
    after ??= before;
    final text = _controller.text;
    final sel = _controller.selection;

    if (sel.isCollapsed) {
      final insert = '$before$after';
      final newText = text.replaceRange(sel.start, sel.end, insert);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: sel.start + before.length,
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final replacement = '$before$selected$after';
      final newText = text.replaceRange(sel.start, sel.end, replacement);
      _controller.text = newText;
      _controller.selection = TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      );
    }
    _focusNode.requestFocus();
  }

  void _insertBold() => _wrapSelection('**');
  void _insertItalic() => _wrapSelection('*');
  void _insertStrikethrough() => _wrapSelection('~~');
  void _insertCode() => _wrapSelection('`');
  void _insertLink() => _wrapSelection('[', '](url)');

  void _insertQuote() {
    final text = _controller.text;
    final sel = _controller.selection;
    final insert = sel.isCollapsed ? '> ' : '> ${text.substring(sel.start, sel.end)}';
    final newText = text.replaceRange(sel.start, sel.end, insert);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: sel.start + insert.length,
    );
    _focusNode.requestFocus();
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final newText = text.replaceRange(pos, pos, emoji);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: pos + emoji.length);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showEmojiPicker)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: DmEmojiPicker(
                onEmojiSelected: _insertEmoji,
                onClose: () => setState(() => _showEmojiPicker = false),
              ),
            ),
          ),

        if (_isEditMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            color: colors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.edit, size: 14, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Editing message',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _exitEditMode,
                  child: Text(
                    'Cancel (Esc)',
                    style: TextStyle(
                      color: colors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isEditMode ? colors.primary : colors.divider,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      _ToolbarButton(
                        icon: Icons.format_bold,
                        tooltip: 'Bold',
                        onTap: _insertBold,
                        colors: colors,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_italic,
                        tooltip: 'Italic',
                        onTap: _insertItalic,
                        colors: colors,
                      ),
                      _ToolbarButton(
                        icon: Icons.strikethrough_s,
                        tooltip: 'Strikethrough',
                        onTap: _insertStrikethrough,
                        colors: colors,
                      ),
                      _ToolbarButton(
                        icon: Icons.link,
                        tooltip: 'Link',
                        onTap: _insertLink,
                        colors: colors,
                      ),
                      _ToolbarButton(
                        icon: Icons.code,
                        tooltip: 'Inline code',
                        onTap: _insertCode,
                        colors: colors,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_quote_outlined,
                        tooltip: 'Block quote',
                        onTap: _insertQuote,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                Divider(height: 16, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Focus(
                    onKeyEvent: _handleKeyEvent,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: _isEditMode
                            ? 'Editing message…'
                            : 'Message ${widget.recipientName}',
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
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    children: [
                      _ToolbarButton(
                        icon: Icons.attach_file_outlined,
                        tooltip: 'Attach file',
                        onTap: () => widget.onFilesAttached?.call([]),
                        colors: colors,
                      ),
                      const SizedBox(width: 4),
                      _ToolbarButton(
                        icon: Icons.emoji_emotions_outlined,
                        tooltip: 'Emoji',
                        onTap: _toggleEmojiPicker,
                        colors: colors,
                        isActive: _showEmojiPicker,
                      ),
                      _ToolbarButton(
                        icon: Icons.alternate_email,
                        tooltip: 'Mention',
                        onTap: () => _wrapSelection('@'),
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
                            color: _isEditMode
                                ? colors.primary
                                : colors.textHint.withValues(alpha: 0.5),
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
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final AppPalette colors;
  final bool isActive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? colors.primary
                : colors.textHint.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }
}
