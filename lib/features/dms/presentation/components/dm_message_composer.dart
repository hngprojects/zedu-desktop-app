import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DmMessageComposer extends ConsumerStatefulWidget {
  final String recipientName;
  final String channelId;
  final List<DmParticipant> participants;
  final ValueChanged<String>? onSend;
  final bool isMember;

  const DmMessageComposer({
    super.key,
    required this.recipientName,
    required this.channelId,
    this.participants = const [],
    this.onSend,
    this.isMember = true,
  });

  @override
  ConsumerState<DmMessageComposer> createState() => DmMessageComposerState();
}

class DmMessageComposerState extends ConsumerState<DmMessageComposer> {
  late final RichTextController _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  bool _showEmojiPicker = false;
  bool _isEditMode = false;
  String? _editingMessageId;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrikethrough = false;
  bool _isCode = false;

  List<XFile> _pendingFiles = [];

  List<DmParticipant> _mentionSuggestions = [];
  String _mentionQuery = '';

  List<Channel> _channelSuggestions = [];
  String _channelQuery = '';

  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  bool _isRecordingPaused = false;

  @override
  void initState() {
    super.initState();
    _controller = RichTextController();
    _controller.addListener(_onTextChanged);
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _updateFormattingState();
    _updateMentionSuggestions();
    _updateChannelSuggestions();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      setState(() {
        _isRecording = true;
        _isRecordingPaused = false;
        _recordingDuration = 0;
      });
      final tempDir = Directory.systemTemp;
      final path =
          '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isRecordingPaused) {
          setState(() {
            _recordingDuration += 1;
            if (_recordingDuration >= 300) {
              _stopRecording();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording limit of 5 minutes reached.'),
                ),
              );
            }
          });
        }
      });
    }
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    setState(() => _isRecordingPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    setState(() => _isRecordingPaused = false);
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _recordingDuration = 0;
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _isRecordingPaused = false;
      _recordingDuration = 0;
      if (path != null) {
        _controller.text = '[Voice Note Attached]';
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        final file = XFile(path, name: 'voice_note.m4a', mimeType: 'audio/m4a');
        _pendingFiles = [file];
      }
    });
  }

  void _updateFormattingState() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      setState(() {
        _isBold = false;
        _isItalic = false;
        _isStrikethrough = false;
        _isCode = false;
      });
      return;
    }
    final before = text.substring(0, sel.baseOffset);
    setState(() {
      _isBold = '**'.allMatches(before).length % 2 != 0;
      _isItalic = RegExp(r'(?<!\*)\*(?!\*)').allMatches(before).length % 2 != 0;
      _isStrikethrough = '~~'.allMatches(before).length % 2 != 0;
      _isCode = '`'.allMatches(before).length % 2 != 0;
    });
  }

  void _updateMentionSuggestions() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      setState(() => _mentionSuggestions = []);
      return;
    }
    final before = text.substring(0, sel.baseOffset);
    final atMatch = RegExp(r'@(\w*)$').firstMatch(before);
    if (atMatch == null) {
      setState(() {
        _mentionSuggestions = [];
        _mentionQuery = '';
      });
      return;
    }
    final query = atMatch.group(1)!.toLowerCase();
    _mentionQuery = query;

    final teamMembers = ref.read(userProfileNotifierProvider).teamMembers;
    final allParticipants = teamMembers
        .map(
          (m) => DmParticipant(
            userId: m.id,
            username: m.name ?? m.email.split('@').first,
            email: m.email,
            avatarUrl: m.avatarUrl,
          ),
        )
        .toList();

    final uniqueParticipants = <String, DmParticipant>{};
    for (final p in widget.participants) {
      uniqueParticipants[p.userId] = p;
    }
    for (final p in allParticipants) {
      uniqueParticipants[p.userId] = p;
    }

    final suggestions = uniqueParticipants.values.where((p) {
      return p.username.toLowerCase().contains(query) ||
          p.email.toLowerCase().contains(query);
    }).toList();
    setState(() => _mentionSuggestions = suggestions);
  }

  void _insertMention(DmParticipant participant) {
    final text = _controller.text;
    final sel = _controller.selection;
    final before = text.substring(0, sel.baseOffset);
    final atIndex = before.lastIndexOf('@');
    if (atIndex == -1) return;

    final after = text.substring(sel.baseOffset);
    final replacement = '@${participant.username} ';
    final newText = text.substring(0, atIndex) + replacement + after;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: atIndex + replacement.length),
    );
    setState(() => _mentionSuggestions = []);
    _focusNode.requestFocus();
  }

  void _updateChannelSuggestions() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || !sel.isCollapsed) {
      setState(() => _channelSuggestions = []);
      return;
    }
    final before = text.substring(0, sel.baseOffset);
    final hashMatch = RegExp(r'#(\w*)$').firstMatch(before);
    if (hashMatch == null) {
      setState(() {
        _channelSuggestions = [];
        _channelQuery = '';
      });
      return;
    }
    final query = hashMatch.group(1)!.toLowerCase();
    _channelQuery = query;
    final channelState = ref.read(channelProvider);
    final suggestions = channelState.channels.where((c) {
      return !c.archived && c.name.toLowerCase().contains(query);
    }).toList();
    setState(() => _channelSuggestions = suggestions);
  }

  void _insertChannel(Channel channel) {
    final text = _controller.text;
    final sel = _controller.selection;
    final before = text.substring(0, sel.baseOffset);
    final hashIndex = before.lastIndexOf('#');
    if (hashIndex == -1) return;

    final after = text.substring(sel.baseOffset);
    final replacement = '#${channel.name} ';
    final newText = text.substring(0, hashIndex) + replacement + after;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: hashIndex + replacement.length,
      ),
    );
    setState(() => _channelSuggestions = []);
    _focusNode.requestFocus();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingFiles.isEmpty) return;

    if (_isEditMode && _editingMessageId != null) {
      ref
          .read(chatHistoryProvider(widget.channelId))
          .saveEdit(_editingMessageId!, text);
      _exitEditMode();
    } else {
      ref
          .read(chatHistoryProvider(widget.channelId))
          .sendMessage(text, media: List<XFile>.of(_pendingFiles));
      widget.onSend?.call(text);
    }

    _controller.clear();
    setState(() => _pendingFiles = []);
    _focusNode.requestFocus();
  }

  void _enterEditMode(String messageId, String content) {
    setState(() {
      _isEditMode = true;
      _editingMessageId = messageId;
      _controller.text = content;
      _controller.selection = TextSelection.collapsed(offset: content.length);
    });
    _focusNode.requestFocus();
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _editingMessageId = null;
    });
    _controller.clear();
    ref.read(chatHistoryProvider(widget.channelId)).cancelEditing();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (HardwareKeyboard.instance.isShiftPressed ||
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed) {
        final text = _controller.text;
        final sel = _controller.selection;
        final offset = sel.isValid ? sel.baseOffset : text.length;
        final newText =
            '${text.substring(0, offset)}\n${text.substring(offset)}';
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: offset + 1),
        );
        return KeyEventResult.handled;
      } else {
        _handleSend();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.escape) {
      if (_mentionSuggestions.isNotEmpty) {
        setState(() => _mentionSuggestions = []);
        return KeyEventResult.handled;
      }
      if (_isEditMode) {
        _exitEditMode();
        return KeyEventResult.handled;
      }
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

    if (key == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _handlePaste();
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.keyB &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _insertBold();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyI &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _insertItalic();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _wrapSelection(String before, [String? after]) {
    after ??= before;
    final text = _controller.text;
    var sel = _controller.selection;

    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: text.length);
    }

    if (sel.isCollapsed) {
      final insert = '$before$after';
      final newText =
          text.substring(0, sel.start) + insert + text.substring(sel.end);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: sel.start + before.length),
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final replacement = '$before$selected$after';
      final newText =
          text.substring(0, sel.start) + replacement + text.substring(sel.end);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + before.length,
          extentOffset: sel.start + before.length + selected.length,
        ),
      );
    }
    _focusNode.requestFocus();
  }

  void _insertBold() => _wrapSelection('**');
  void _insertItalic() => _wrapSelection('*');
  void _insertStrikethrough() => _wrapSelection('~~');
  void _insertCode() => _wrapSelection('`');

  void _insertBulletList() {
    final text = _controller.text;
    var sel = _controller.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: text.length);
    }
    final insert = sel.isCollapsed
        ? '\n- '
        : '\n- ${text.substring(sel.start, sel.end)}';
    final newText =
        text.substring(0, sel.start) + insert + text.substring(sel.end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _focusNode.requestFocus();
  }

  void _insertNumberedList() {
    final text = _controller.text;
    var sel = _controller.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: text.length);
    }
    final insert = sel.isCollapsed
        ? '\n1. '
        : '\n1. ${text.substring(sel.start, sel.end)}';
    final newText =
        text.substring(0, sel.start) + insert + text.substring(sel.end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _focusNode.requestFocus();
  }

  void _insertCodeBlock() {
    _wrapSelection('```\n', '\n```');
  }

  void _insertLink() => _wrapSelection('[', '](url)');

  void _insertQuote() {
    final text = _controller.text;
    var sel = _controller.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: text.length);
    }
    final insert = sel.isCollapsed
        ? '> '
        : '> ${text.substring(sel.start, sel.end)}';
    final newText =
        text.substring(0, sel.start) + insert + text.substring(sel.end);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + insert.length),
    );
    _focusNode.requestFocus();
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
    _focusNode.requestFocus();
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final sel = _controller.selection;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final newText = text.substring(0, pos) + emoji + text.substring(pos);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + emoji.length),
    );
    _focusNode.requestFocus();
  }

  bool _isDragging = false;

  Future<void> addFiles(List<XFile> newFiles) async {
    final validFiles = <XFile>[];
    for (final file in newFiles) {
      try {
        final length = await file.length();
        if (length > 20 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File ${file.name} exceeds 20MB limit.')),
            );
          }
          continue;
        }
        validFiles.add(file);
      } catch (e) {
        validFiles.add(file);
      }
    }
    setState(() {
      _pendingFiles.addAll(validFiles);
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result == null) return;
      final picked = result.files
          .where((PlatformFile f) => f.path != null)
          .map(
            (PlatformFile f) =>
                XFile(f.path!, name: f.name, mimeType: f.extension),
          )
          .toList();
      await addFiles(picked);
    } catch (e, stack) {
      debugPrint('Error picking files: $e\n$stack');
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Could not open file picker: $e',
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      final removed = _pendingFiles[index];
      _pendingFiles = List<XFile>.of(_pendingFiles)..removeAt(index);
      if (removed.name == 'voice_note.m4a' &&
          _controller.text == '[Voice Note Attached]') {
        _controller.clear();
      }
    });
  }

  bool get _hasVoiceNoteAttached {
    return _pendingFiles.any((f) => f.name == 'voice_note.m4a');
  }

  XFile? get _voiceNoteFile {
    try {
      return _pendingFiles.firstWhere((f) => f.name == 'voice_note.m4a');
    } catch (_) {
      return null;
    }
  }

  void _deleteVoiceNote() {
    setState(() {
      _pendingFiles = _pendingFiles
          .where((f) => f.name != 'voice_note.m4a')
          .toList();
      if (_controller.text == '[Voice Note Attached]') {
        _controller.clear();
      }
    });
  }

  Future<void> _handlePaste() async {
    final reader = await SystemClipboard.instance?.read();
    if (reader == null || !reader.canProvide(Formats.png)) return;

    reader.getFile(Formats.png, (file) async {
      final stream = file.getStream();
      final bytesBuilder = <int>[];
      await for (final chunk in stream) {
        bytesBuilder.addAll(chunk);
      }
      final bytes = Uint8List.fromList(bytesBuilder);
      if (bytes.isNotEmpty) {
        addFiles([
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'Pasted Image.png',
          ),
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (!widget.isMember) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        color: colors.primary.withOpacity(0.02),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.recipientName.startsWith('#')
                  ? widget.recipientName
                  : '#${widget.recipientName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'You are not a member of this channel',
              style: TextStyle(color: colors.textPrimary.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(channelProvider.notifier)
                    .joinChannel(widget.channelId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.sidebar,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Join channel'),
            ),
          ],
        ),
      );
    }

    final mainColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_mentionSuggestions.isNotEmpty)
          MentionSuggestionList(
            suggestions: _mentionSuggestions,
            query: _mentionQuery,
            colors: colors,
            onSelect: _insertMention,
          ),

        if (_channelSuggestions.isNotEmpty)
          ChannelSuggestionList(
            suggestions: _channelSuggestions,
            query: _channelQuery,
            colors: colors,
            onSelect: _insertChannel,
          ),

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

        if (_pendingFiles.where((f) => f.name != 'voice_note.m4a').isNotEmpty)
          AttachmentPreviewBar(
            files: _pendingFiles
                .where((f) => f.name != 'voice_note.m4a')
                .toList(),
            onRemove: (index) {
              final nonVoiceFiles = _pendingFiles
                  .where((f) => f.name != 'voice_note.m4a')
                  .toList();
              final fileToRemove = nonVoiceFiles[index];
              _removeFile(_pendingFiles.indexOf(fileToRemove));
            },
            colors: colors,
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
                    style: TextStyle(color: colors.textHint, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isEditMode ? colors.primary : colors.primary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      ToolbarButton(
                        icon: Icons.format_bold,
                        tooltip: 'Bold (Ctrl+B)',
                        onTap: _insertBold,
                        colors: colors,
                        isActive: _isBold,
                      ),
                      ToolbarButton(
                        icon: Icons.format_italic,
                        tooltip: 'Italic (Ctrl+I)',
                        onTap: _insertItalic,
                        colors: colors,
                        isActive: _isItalic,
                      ),
                      ToolbarButton(
                        icon: Icons.code_rounded,
                        tooltip: 'Inline code',
                        onTap: _insertCode,
                        colors: colors,
                        isActive: _isCode,
                      ),
                      ToolbarButton(
                        icon: Icons.terminal_rounded,
                        tooltip: 'Code block',
                        onTap: _insertCodeBlock,
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.format_list_bulleted_rounded,
                        tooltip: 'Bullet list',
                        onTap: _insertBulletList,
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.format_list_numbered_rounded,
                        tooltip: 'Numbered list',
                        onTap: _insertNumberedList,
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.emoji_emotions_outlined,
                        tooltip: 'Emoji picker',
                        onTap: _toggleEmojiPicker,
                        colors: colors,
                        isActive: _showEmojiPicker,
                      ),
                      ToolbarButton(
                        icon: Icons.attach_file,
                        tooltip: 'Attach file',
                        onTap: _pickFiles,
                        colors: colors,
                        isActive: _pendingFiles.isNotEmpty,
                      ),
                      ToolbarButton(
                        icon: Icons.strikethrough_s,
                        tooltip: 'Strikethrough',
                        onTap: _insertStrikethrough,
                        colors: colors,
                        isActive: _isStrikethrough,
                      ),
                      ToolbarButton(
                        icon: Icons.link_rounded,
                        tooltip: 'Link',
                        onTap: _insertLink,
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.format_quote_rounded,
                        tooltip: 'Block quote',
                        onTap: _insertQuote,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                Divider(height: 12, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _isRecording
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                color: colors.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording: ${_recordingDuration ~/ 60}:${(_recordingDuration % 60).toString().padLeft(2, '0')}',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.error,
                                ),
                              ),
                              if (_isRecordingPaused) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(Paused)',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textHint,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.close, color: colors.error),
                                tooltip: 'Discard',
                                onPressed: _cancelRecording,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isRecordingPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  color: colors.primary,
                                ),
                                tooltip: _isRecordingPaused
                                    ? 'Resume'
                                    : 'Pause',
                                onPressed: _isRecordingPaused
                                    ? _resumeRecording
                                    : _pauseRecording,
                              ),
                              IconButton(
                                icon: Icon(Icons.check, color: colors.primary),
                                tooltip: 'Finish and Attach',
                                onPressed: _stopRecording,
                              ),
                            ],
                          ),
                        )
                      : _hasVoiceNoteAttached
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: VoiceNotePlayer(
                                  audioSource: _voiceNoteFile!.path,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                tooltip: 'Delete Voice Note',
                                onPressed: _deleteVoiceNote,
                              ),
                            ],
                          ),
                        )
                      : Focus(
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
                                color: colors.textHint.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    children: [
                      ToolbarButton(
                        icon: Icons.add,
                        tooltip: 'Attach file',
                        onTap: _pickFiles,
                        colors: colors,
                        isActive: _pendingFiles.isNotEmpty,
                      ),
                      const SizedBox(width: 2),
                      ToolbarButton(
                        icon: Icons.emoji_emotions_outlined,
                        tooltip: 'Emoji',
                        onTap: _toggleEmojiPicker,
                        colors: colors,
                        isActive: _showEmojiPicker,
                      ),
                      ToolbarButton(
                        icon: Icons.alternate_email_rounded,
                        tooltip: 'Mention someone',
                        onTap: () {
                          final text = _controller.text;
                          final sel = _controller.selection;
                          final pos = sel.isValid
                              ? sel.baseOffset
                              : text.length;
                          final newText =
                              '${text.substring(0, pos)}@${text.substring(pos)}';
                          _controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: pos + 1),
                          );
                          _focusNode.requestFocus();
                        },
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.tag,
                        tooltip: 'Channel tag',
                        onTap: () {
                          final text = _controller.text;
                          final sel = _controller.selection;
                          final pos = sel.isValid
                              ? sel.baseOffset
                              : text.length;
                          final newText =
                              '${text.substring(0, pos)}#${text.substring(pos)}';
                          _controller.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(offset: pos + 1),
                          );
                          _focusNode.requestFocus();
                        },
                        colors: colors,
                      ),
                      ToolbarButton(
                        icon: Icons.horizontal_rule_rounded,
                        tooltip: 'Divider',
                        onTap: () => _wrapSelection('/'),
                        colors: colors,
                      ),
                      const SizedBox(width: 4),
                      ToolbarButton(
                        icon: Icons.videocam_outlined,
                        tooltip: 'Video call',
                        onTap: () {
                          ref
                              .read(activeCallProvider.notifier)
                              .initiateCall(
                                remoteUserId:
                                    widget.participants.firstOrNull?.userId ??
                                    widget.channelId,
                                remoteUserName: widget.recipientName,
                                channelId: widget.channelId,
                              );
                        },
                        colors: colors,
                      ),
                      const SizedBox(width: 4),
                      ToolbarButton(
                        icon: _isRecording
                            ? Icons.stop_circle_rounded
                            : Icons.mic_none_rounded,
                        tooltip: _isRecording
                            ? 'Stop recording'
                            : 'Voice message',
                        onTap: () {
                          if (_isRecording) {
                            _stopRecording();
                          } else {
                            _startRecording();
                          }
                        },
                        colors: colors,
                        isActive: _isRecording,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _handleSend,
                        child: Icon(
                          Icons.send_rounded,
                          color: colors.textHint.withValues(alpha: 0.55),
                          size: 22,
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

    return DropTarget(
      onDragDone: (detail) {
        addFiles(detail.files);
        setState(() => _isDragging = false);
      },
      onDragEntered: (detail) => setState(() => _isDragging = true),
      onDragExited: (detail) => setState(() => _isDragging = false),
      child: Stack(
        children: [
          mainColumn,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: colors.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Drop files to attach',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
