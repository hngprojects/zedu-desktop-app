import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
// import 'package:zedu/core/services/realtime_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final Map<String, DateTime> _lastNotificationTimes = {};

  NotificationService(this._ref);

  Future<void> init() async {
    await localNotifier.setup(
      appName: 'Zedu',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );

    // Global listener for realtime messages and calls
    _ref.read(realtimeServiceProvider).dmMessageStream.listen((event) {
      final channelId = event['channelId']?.toString() ?? '';
      final rawMessage = event['message'];
      if (rawMessage is! Map<String, dynamic>) return;

      // Handle Calls
      if (_handleCallEvent(rawMessage, channelId)) return;

      // Handle standard message
      final msg = _normalizeMessage(rawMessage);
      final senderName =
          msg['username']?.toString() ??
          msg['sender_name']?.toString() ??
          'Someone';

      handleIncomingMessage(msg, channelId, senderName);
    });
  }

  bool _handleCallEvent(Map<String, dynamic> event, String channelId) {
    final eventName = event['event']?.toString();
    final payload = event['payload'];
    if (eventName != 'direct_call_initiated' ||
        payload is! Map<String, dynamic>) {
      return false;
    }

    final authState = _ref.read(authNotifierProvider);
    final currentUserId = authState.user?.id ?? '';
    final callerId = payload['caller_id']?.toString() ?? '';

    if (callerId == currentUserId) return true; // Don't ring for our own calls

    final callerName = payload['caller_name']?.toString() ?? 'Incoming call';

    // 1. Trigger the app's ringing UI
    _ref
        .read(activeCallProvider)
        .receiveIncomingCall(
          buzzId: payload['buzz_id']?.toString() ?? '',
          remoteUserId: callerId,
          remoteUserName: callerName,
          channelId: payload['channel_id']?.toString() ?? channelId,
        );

    // 2. Show desktop notification
    final notification = LocalNotification(
      title: 'Incoming Buzz Call',
      body: '$callerName is calling you...',
    );
    notification.onClick = () async {
      await windowManager.show();
      await windowManager.focus();
    };
    notification.show();

    return true;
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> event) {
    final payload = event['payload'];
    Map<String, dynamic> msg;
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      msg = message is Map<String, dynamic>
          ? Map<String, dynamic>.from(message)
          : Map<String, dynamic>.from(payload);
    } else {
      final message = event['message'];
      msg = message is Map<String, dynamic>
          ? Map<String, dynamic>.from(message)
          : Map<String, dynamic>.from(event);
    }
    return msg;
  }

  /// Handles an incoming message and shows a desktop notification.
  ///
  /// When [forceShow] is `true` the focus-check and per-sender throttle are
  /// skipped so that test / manual notifications always fire.
  Future<void> handleIncomingMessage(
    Map<String, dynamic> message,
    String channelId,
    String senderName, {
    bool forceShow = false,
  }) async {
    final settings = _ref.read(notificationSettingsProvider);
    final authState = _ref.read(authNotifierProvider);
    final currentUserId = authState.user?.id ?? '';

    final senderId = (message['user_id'] ?? message['userId']).toString();

    // Never notify about our own messages (unless forced for testing).
    if (!forceShow && (senderId == currentUserId || senderId == 'me')) return;

    if (settings.isDndActive) return;
    if (settings.isMuted(senderId)) return;

    final String content = (message['content'] ?? '').toString();
    final bool isMuted = settings.isChannelMuted(channelId);
    final String currentUsername = authState.user?.username ?? '';
    final String currentFullname = authState.user?.fullname ?? '';
    final bool isMentioned =
        content.contains('@$currentUsername') ||
        (currentFullname.isNotEmpty && content.contains('@$currentFullname'));

    if (isMuted && !isMentioned) return;

    if (!forceShow) {
      final isFocused = await windowManager.isFocused();
      final selectedChannel = _ref.read(selectedDmProvider)?.channelId;

      if (isFocused && selectedChannel == channelId) {
        return;
      }

      final now = DateTime.now();
      final lastTime = _lastNotificationTimes[senderId];
      if (lastTime != null && now.difference(lastTime).inSeconds < 5) {
        return;
      }
      _lastNotificationTimes[senderId] = now;
    }

    String contentPreview = (message['content'] ?? '').toString();
    if (contentPreview.isEmpty) {
      final media = message['media'] as List<dynamic>? ?? [];
      if (media.isNotEmpty) {
        contentPreview = 'Sent an attachment';
      } else {
        contentPreview = 'New message';
      }
    }

    if (contentPreview.length > 80) {
      contentPreview = '${contentPreview.substring(0, 77)}...';
    }

    final notification = LocalNotification(
      title: 'New DM from $senderName',
      body: contentPreview,
    );

    notification.onClick = () async {
      await windowManager.show();
      await windowManager.focus();

      final router = locator<GoRouter>();
      router.go('/dms/$channelId');
    };

    await notification.show();
  }
}
