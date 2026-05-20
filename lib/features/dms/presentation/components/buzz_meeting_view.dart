import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BuzzMeetingView extends StatefulWidget {
  final String channelName;
  final String token;
  final int localUid;
  final String remoteUserName;

  const BuzzMeetingView({
    super.key,
    required this.channelName,
    required this.token,
    required this.localUid,
    required this.remoteUserName,
  });

  @override
  State<BuzzMeetingView> createState() => _BuzzMeetingViewState();
}

class _BuzzMeetingViewState extends State<BuzzMeetingView> {
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isHandRaised = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_isVideoOff)
                        AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: createAgoraRtcEngine(),
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      else
                        const Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFF6458F5),
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                        ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      if (_isHandRaised)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.back_hand, size: 20, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_remoteUid != null)
                        AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: createAgoraRtcEngine(),
                            canvas: VideoCanvas(uid: _remoteUid),
                            connection: RtcConnection(channelId: widget.channelName),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Color(0xFF6458F5),
                                child: Icon(Icons.person, size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Waiting for ${widget.remoteUserName}...',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.remoteUserName,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white24,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                  color: _isVideoOff ? Colors.red : Colors.white24,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: Icons.back_hand,
                  color: _isHandRaised ? Colors.amber : Colors.white24,
                  onTap: () => setState(() => _isHandRaised = !_isHandRaised),
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
