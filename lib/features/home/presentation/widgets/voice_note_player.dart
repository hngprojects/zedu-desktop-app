import 'package:zedu/core/core.dart';

class VoiceNotePlayer extends StatefulWidget {
  final String audioSource;

  const VoiceNotePlayer({super.key, required this.audioSource});

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late final List<double> _waveformAmplitudes;

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveformAmplitudes = _generateMockAmplitudes(widget.audioSource);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  List<double> _generateMockAmplitudes(String source) {
    final rand = Random(source.hashCode);
    return List.generate(40, (index) => 0.1 + rand.nextDouble() * 0.9);
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (widget.audioSource.isEmpty ||
          widget.audioSource.contains('Attached')) {
        try {
          await _audioPlayer.play(
            UrlSource(
              'https://codesandbox.io/api/v1/sandboxes/play/mock-audio.mp3',
            ),
          );
        } catch (_) {
          _simulateMockPlayback();
        }
      } else {
        try {
          if (widget.audioSource.startsWith('http')) {
            await _audioPlayer.play(UrlSource(widget.audioSource));
          } else {
            await _audioPlayer.play(DeviceFileSource(widget.audioSource));
          }
        } catch (_) {
          _simulateMockPlayback();
        }
      }
    }
  }

  void _simulateMockPlayback() {
    setState(() => _isPlaying = true);
    _duration = const Duration(seconds: 5);
    _position = Duration.zero;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      setState(() {
        final newSec = _position.inMilliseconds + 200;
        if (newSec >= _duration.inMilliseconds) {
          _position = _duration;
          _isPlaying = false;
          timer.cancel();
        } else {
          _position = Duration(milliseconds: newSec);
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: colors.primary,
              size: 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _togglePlayback,
            splashRadius: 20,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (_duration.inMilliseconds > 0) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.globalPosition);

                final relativeX = (localOffset.dx - 44).clamp(0.0, 120.0);
                final newProgress = relativeX / 120.0;
                final newMs = (newProgress * _duration.inMilliseconds).toInt();
                _audioPlayer.seek(Duration(milliseconds: newMs));
              }
            },
            child: SizedBox(
              width: 120,
              height: 24,
              child: CustomPaint(
                painter: _WaveformPainter(
                  amplitudes: _waveformAmplitudes,
                  progress: progress,
                  color: colors.primary,
                  backgroundColor: colors.textHint.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isPlaying
                ? _formatDuration(_position)
                : (_duration == Duration.zero
                      ? '0:05'
                      : _formatDuration(_duration)),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.download_rounded,
              color: colors.textHint,
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio download started...')),
              );
            },
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color color;
  final Color backgroundColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final spacing = size.width / amplitudes.length;
    final centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = i * spacing + 1.25;
      final height = amplitudes[i] * size.height;
      final top = centerY - height / 2;
      final bottom = centerY + height / 2;

      final itemProgress = i / amplitudes.length;
      paint.color = itemProgress <= progress ? color : backgroundColor;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
