import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:zedu/core/core.dart';

class ChannelMessageComposer extends StatefulWidget {
  const ChannelMessageComposer({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.enabled = true,
    this.placeholder = 'Message #general',
  });

  final ValueChanged<String> onSend;
  final bool isSending;
  final bool enabled;
  final String placeholder;

  @override
  State<ChannelMessageComposer> createState() => _ChannelMessageComposerState();
}

class _ChannelMessageComposerState extends State<ChannelMessageComposer> {
  late quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController.basic();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildToolbar(context),
            Divider(height: 1, color: colors.divider),
            SizedBox(
              height: 110,
              child: IgnorePointer(
                ignoring: !widget.enabled || widget.isSending,
                child: quill.QuillEditor.basic(
                  controller: _controller,
                  config: quill.QuillEditorConfig(
                    placeholder: widget.placeholder,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: colors.divider),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.add, color: colors.textHint),
                  const SizedBox(width: 12),
                  Icon(Icons.emoji_emotions_outlined, color: colors.textHint),
                  const SizedBox(width: 12),
                  Icon(Icons.alternate_email, color: colors.textHint),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.enabled && !widget.isSending ? _onSendPressed : null,
                    icon: widget.isSending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Icon(Icons.send_rounded, color: colors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.format_bold,
            onTap: () => _toggleAttribute(quill.Attribute.bold),
          ),
          _ToolbarButton(
            icon: Icons.format_italic,
            onTap: () => _toggleAttribute(quill.Attribute.italic),
          ),
          _ToolbarButton(
            icon: Icons.link,
            onTap: _insertLink,
          ),
          _ToolbarButton(
            icon: Icons.format_list_bulleted,
            onTap: () => _toggleAttribute(quill.Attribute.ul),
          ),
          _ToolbarButton(
            icon: Icons.code,
            onTap: () => _toggleAttribute(quill.Attribute.codeBlock),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Clear',
            onPressed: () {
              setState(() => _controller = quill.QuillController.basic());
            },
            icon: Icon(Icons.clear, size: 18, color: colors.textHint),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _toggleAttribute(quill.Attribute<dynamic> attribute) {
    final styleAttrs = _controller.getSelectionStyle().attributes;
    final hasAttribute = styleAttrs.containsKey(attribute.key);

    _controller.formatSelection(
      quill.Attribute.fromKeyValue(
        attribute.key,
        hasAttribute ? null : attribute.value,
      ),
    );
  }

  Future<void> _insertLink() async {
    final selection = _controller.selection;
    if (selection.start < 0) return;

    final linkController = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert link'),
        content: TextField(
          controller: linkController,
          decoration: const InputDecoration(hintText: 'https://example.com'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(linkController.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (link == null || link.isEmpty) return;
    _controller.formatSelection(quill.Attribute.fromKeyValue('link', link));
  }

  void _onSendPressed() {
    final html = _toHtml(_controller.document.toDelta().toJson());
    final plainText = _controller.document.toPlainText().trim();
    if (plainText.isEmpty) return;

    widget.onSend(html);
    setState(() => _controller = quill.QuillController.basic());
  }

  String _toHtml(List<dynamic> rawDelta) {
    try {
      final ops = rawDelta.whereType<Map<String, dynamic>>().toList();
      final converter = QuillDeltaToHtmlConverter(ops, ConverterOptions());
      final html = converter.convert().trim();
      if (html.isNotEmpty) return html;
    } catch (_) {
      // Fallback below
    }

    final escaped = const HtmlEscape().convert(_controller.document.toPlainText().trim());
    return '<p>$escaped</p>';
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      onPressed: onTap,
      splashRadius: 18,
      icon: Icon(icon, size: 18, color: colors.textHint),
    );
  }
}
