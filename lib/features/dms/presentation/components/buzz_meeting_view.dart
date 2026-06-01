import 'package:permission_handler/permission_handler.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BuzzMeetingView extends ConsumerStatefulWidget {
  const BuzzMeetingView({super.key});

  @override
  ConsumerState<BuzzMeetingView> createState() => _BuzzMeetingViewState();
}

class _BuzzMeetingViewState extends ConsumerState<BuzzMeetingView> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isHandRaised = false;

  late RtcEngine _engine;
  int? _remoteUid;
  bool _isEngineInitialized = false;

  // New State variables
  VideoViewController? _localVideoController;
  VideoViewController? _remoteVideoController;

  bool? _lastIsFullPage;
  bool _showEmojis = false;

  final Set<int> _mutedUsers = {};
  final Set<int> _activeSpeakers = {};
  final Set<int> _raisedHands = {};

  final Map<int, String> _activeEmojis = {};
  final Map<int, Timer> _emojiTimers = {};

  int? _dataStreamId;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    final activeCall = ref.read(activeCallProvider);
    final appId = activeCall.state.appId;
    final token = activeCall.state.token;
    final channelName = activeCall.state.channelName;

    if (appId == null || appId.isEmpty) {
      debugPrint('No Agora App ID provided');
      return;
    }

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Setup Video Controllers immediately
    _localVideoController = VideoViewController(
      rtcEngine: _engine,
      canvas: const VideoCanvas(uid: 0),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('local user ${connection.localUid} joined');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('remote user $remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
            _remoteVideoController = VideoViewController.remote(
              rtcEngine: _engine,
              canvas: VideoCanvas(uid: remoteUid),
              connection: RtcConnection(channelId: channelName),
            );
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint('remote user $remoteUid left channel');
              setState(() {
                if (_remoteUid == remoteUid) {
                  _remoteUid = null;
                  _remoteVideoController = null;
                }
                _mutedUsers.remove(remoteUid);
                _activeSpeakers.remove(remoteUid);
                _raisedHands.remove(remoteUid);
                _clearEmoji(remoteUid);
              });
            },
        onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
          setState(() {
            if (muted) {
              _mutedUsers.add(remoteUid);
              _activeSpeakers.remove(remoteUid);
            } else {
              _mutedUsers.remove(remoteUid);
            }
          });
        },
        onAudioVolumeIndication:
            (
              RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int speakerNumber,
              int totalVolume,
            ) {
              setState(() {
                _activeSpeakers.clear();
                for (var speaker in speakers) {
                  // uid 0 means local user
                  if (speaker.volume != null && speaker.volume! > 5) {
                    _activeSpeakers.add(speaker.uid ?? 0);
                  }
                }
              });
            },
        onStreamMessage:
            (
              RtcConnection connection,
              int remoteUid,
              int streamId,
              Uint8List data,
              int length,
              int sentTs,
            ) {
              try {
                final payload = utf8.decode(data);
                final json = jsonDecode(payload);
                if (json['type'] == 'hand_raise') {
                  setState(() {
                    if (json['value'] == true) {
                      _raisedHands.add(remoteUid);
                    } else {
                      _raisedHands.remove(remoteUid);
                    }
                  });
                } else if (json['type'] == 'emoji') {
                  _showEmoji(remoteUid, json['value'] as String);
                }
              } catch (e) {
                debugPrint('Data stream error: $e');
              }
            },
      ),
    );

    // Enable Audio and Video
    await _engine.enableAudio();
    await _engine.enableVideo();

    // Enable Audio Volume Indication
    await _engine.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    await _engine.startPreview();

    // Create Data Stream for realtime features
    _dataStreamId = await _engine.createDataStream(
      const DataStreamConfig(syncWithAudio: false, ordered: true),
    );

    if (token != null && channelName != null) {
      await _engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    }

    setState(() {
      _isEngineInitialized = true;
    });
  }

  @override
  void dispose() {
    for (var timer in _emojiTimers.values) {
      timer.cancel();
    }
    if (_isEngineInitialized) {
      _engine.leaveChannel();
      _engine.release();
    }
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isEngineInitialized) {
      _engine.muteLocalAudioStream(_isMuted);
    }
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    if (_isEngineInitialized) {
      _engine.enableLocalVideo(!_isVideoOff);
      if (!_isVideoOff) {
        _engine.startPreview();
      }
    }
  }

  void _toggleHandRaise() {
    setState(() {
      _isHandRaised = !_isHandRaised;
      if (_isHandRaised) {
        _raisedHands.add(0);
      } else {
        _raisedHands.remove(0);
      }
    });
    _sendDataStream({'type': 'hand_raise', 'value': _isHandRaised});
  }

  void _toggleEmojiMenu() {
    setState(() {
      _showEmojis = !_showEmojis;
    });
  }

  void _sendEmoji(String emoji) {
    setState(() {
      _showEmojis = false;
    });
    _showEmoji(0, emoji);
    _sendDataStream({'type': 'emoji', 'value': emoji});
  }

  void _sendDataStream(Map<String, dynamic> data) {
    if (_isEngineInitialized && _dataStreamId != null) {
      final jsonStr = jsonEncode(data);
      _engine.sendStreamMessage(
        streamId: _dataStreamId!,
        data: Uint8List.fromList(utf8.encode(jsonStr)),
        length: jsonStr.length,
      );
    }
  }

  void _showEmoji(int uid, String emoji) {
    setState(() {
      _activeEmojis[uid] = emoji;
    });
    _emojiTimers[uid]?.cancel();
    _emojiTimers[uid] = Timer(const Duration(seconds: 5), () {
      _clearEmoji(uid);
    });
  }

  void _clearEmoji(int uid) {
    setState(() {
      _activeEmojis.remove(uid);
    });
    _emojiTimers[uid]?.cancel();
    _emojiTimers.remove(uid);
  }

  Widget _buildInlineEmojiPicker() {
    if (!_showEmojis) return const SizedBox.shrink();
    final emojis = ['👍', '❤️', '😂', '🎉', '👏', '😮', '👎', '😢'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojis
            .map(
              (e) => InkWell(
                onTap: () => _sendEmoji(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(e, style: const TextStyle(fontSize: 20)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeCall = ref.watch(activeCallProvider);

    if (activeCall.state.status != CallStatus.active) {
      return const SizedBox.shrink();
    }

    final bool isFullPage = activeCall.state.isFullPage;

    if (_lastIsFullPage != null && _lastIsFullPage != isFullPage) {
      // Recreate controllers to rebind native views after UI restructure
      _localVideoController = VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      );
      if (_remoteUid != null && activeCall.state.channelName != null) {
        _remoteVideoController = VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid!),
          connection: RtcConnection(channelId: activeCall.state.channelName!),
        );
      }
      if (!_isVideoOff && _isEngineInitialized) {
        Future.microtask(() async {
          await _engine.enableLocalVideo(false);
          await _engine.enableLocalVideo(true);
          await _engine.startPreview();
        });
      }
    }
    _lastIsFullPage = isFullPage;

    final remoteName = activeCall.state.remoteUserName ?? 'Unknown';

    if (!isFullPage) {
      return Positioned(
        top: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buzz Call',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '2 participant',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.open_in_full, size: 16),
                        color: colors.textHint,
                        onPressed: () {
                          ref
                              .read(activeCallProvider.notifier)
                              .setFullPage(true);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildVideoFeed(
                          Colors.green.shade900,
                          'You',
                          null,
                          80,
                          isLocal: true,
                          uid: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildVideoFeed(
                          Colors.grey.shade800,
                          remoteName,
                          activeCall.state.remoteAvatarUrl,
                          80,
                          isLocal: false,
                          uid: _remoteUid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInlineEmojiPicker(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.red : Colors.grey.shade800,
                        onTap: _toggleMute,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoOff ? Colors.red : Colors.grey.shade800,
                        onTap: _toggleVideo,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: Icons.emoji_emotions_outlined,
                        color: Colors.grey.shade800,
                        onTap: _toggleEmojiMenu,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: Icons.back_hand,
                        color: _isHandRaised
                            ? Colors.amber
                            : Colors.grey.shade800,
                        onTap: _toggleHandRaise,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onTap: () {
                          ref.read(activeCallProvider.notifier).leaveCall();
                        },
                        small: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: colors.background,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider)),
            ),
            child: Row(
              children: [
                Text(
                  'Buzz Meeting',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people_outline, size: 16, color: colors.textHint),
                const SizedBox(width: 4),
                Text(
                  '2 participant',
                  style: TextStyle(fontSize: 13, color: colors.textHint),
                ),
                const Spacer(),
                Text(
                  'Full page',
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: true,
                  onChanged: (val) {
                    ref.read(activeCallProvider.notifier).setFullPage(false);
                  },
                  activeThumbColor: colors.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: _buildVideoFeed(
                      const Color(0xFF4A2B1D),
                      remoteName,
                      activeCall.state.remoteAvatarUrl,
                      double.infinity,
                      isLocal: false,
                      uid: _remoteUid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildVideoFeed(
                      const Color(0xFF1E3A2F),
                      'You',
                      null,
                      double.infinity,
                      isLocal: true,
                      uid: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Controls
          _buildInlineEmojiPicker(),
          Container(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.grey.shade800,
                  onTap: _toggleMute,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.screen_share_outlined,
                  color: Colors.grey.shade800,
                  onTap: () {},
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff ? Colors.red : Colors.grey.shade800,
                  onTap: _toggleVideo,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.emoji_emotions_outlined,
                  color: Colors.grey.shade800,
                  onTap: _toggleEmojiMenu,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.back_hand,
                  color: _isHandRaised ? Colors.amber : Colors.grey.shade800,
                  onTap: _toggleHandRaise,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.more_vert,
                  color: Colors.grey.shade800,
                  onTap: () {},
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: () {
                    ref.read(activeCallProvider.notifier).leaveCall();
                  },
                  small: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoFeed(
    Color bgColor,
    String name,
    String? avatarUrl,
    double height, {
    required bool isLocal,
    int? uid,
  }) {
    final isSpeaker = uid != null && _activeSpeakers.contains(uid);
    final isUserMuted =
        (isLocal && _isMuted) ||
        (!isLocal && uid != null && _mutedUsers.contains(uid));
    final hasHandRaised = uid != null && _raisedHands.contains(uid);
    final activeEmoji = uid != null ? _activeEmojis[uid] : null;

    Widget? videoView;
    if (_isEngineInitialized) {
      if (isLocal && !_isVideoOff && _localVideoController != null) {
        videoView = AgoraVideoView(controller: _localVideoController!);
      } else if (!isLocal && uid != null && _remoteVideoController != null) {
        videoView = AgoraVideoView(controller: _remoteVideoController!);
      }
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isSpeaker && !isUserMuted
            ? Border.all(color: Colors.green, width: 3)
            : Border.all(color: Colors.transparent, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoView != null)
            videoView
          else
            Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6458F5),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasHandRaised) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.back_hand,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUserMuted)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off, size: 14, color: Colors.red),
              ),
            ),
          if (activeEmoji != null)
            Positioned(
              top: 40,
              left: 12,
              child: Text(activeEmoji, style: const TextStyle(fontSize: 32)),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool small,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(small ? 6 : 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: small ? 18 : 24),
      ),
    );
  }
}
