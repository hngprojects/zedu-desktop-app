import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isEngineInitialized = false;

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

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('local user \${connection.localUid} joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('remote user \$remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint('remote user \$remoteUid left channel');
              setState(() {
                _remoteUid = null;
              });
            },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

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
      _engine.muteLocalVideoStream(_isVideoOff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeCall = ref.watch(activeCallProvider);

    if (activeCall.state.status != CallStatus.active) {
      return const SizedBox.shrink();
    }

    final bool isFullPage = activeCall.state.isFullPage;
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
                          remoteUid: _remoteUid,
                          channelName: activeCall.state.channelName,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.red : Colors.white24,
                        onTap: _toggleMute,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoOff ? Colors.red : Colors.white24,
                        onTap: _toggleVideo,
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: Icons.emoji_emotions_outlined,
                        color: Colors.white24,
                        onTap: () {},
                        small: true,
                      ),
                      const SizedBox(width: 8),
                      _buildControlButton(
                        icon: Icons.back_hand,
                        color: _isHandRaised ? Colors.amber : Colors.white24,
                        onTap: () =>
                            setState(() => _isHandRaised = !_isHandRaised),
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
                      remoteUid: _remoteUid,
                      channelName: activeCall.state.channelName,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Controls
          Container(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted
                      ? Colors.red
                      : colors.primary.withValues(alpha: 0.2),
                  onTap: _toggleMute,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.screen_share_outlined,
                  color: colors.primary.withValues(alpha: 0.2),
                  onTap: () {},
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff
                      ? Colors.red
                      : colors.primary.withValues(alpha: 0.2),
                  onTap: _toggleVideo,
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.emoji_emotions_outlined,
                  color: colors.primary.withValues(alpha: 0.2),
                  onTap: () {},
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.back_hand,
                  color: _isHandRaised
                      ? Colors.amber
                      : colors.primary.withValues(alpha: 0.2),
                  onTap: () => setState(() => _isHandRaised = !_isHandRaised),
                  small: false,
                ),
                const SizedBox(width: 16),
                _buildControlButton(
                  icon: Icons.more_vert,
                  color: colors.primary.withValues(alpha: 0.2),
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
    bool isLocal = false,
    int? remoteUid,
    String? channelName,
  }) {
    Widget? videoView;
    if (_isEngineInitialized) {
      if (isLocal && !_isVideoOff) {
        videoView = AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine,
            canvas: const VideoCanvas(uid: 0),
          ),
        );
      } else if (!isLocal && remoteUid != null && channelName != null) {
        videoView = AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: _engine,
            canvas: VideoCanvas(uid: remoteUid),
            connection: RtcConnection(channelId: channelName),
          ),
        );
      }
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
                    ? Icon(Icons.person, size: 24, color: Colors.white)
                    : null,
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
