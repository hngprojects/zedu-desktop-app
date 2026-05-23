import 'package:zedu/core/core.dart';

import '../../auth/presentation/providers/auth_providers_di.dart';
import '../presentation/providers/dm_list_provider.dart';
import '../presentation/providers/notification_settings_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final Map<String, DateTime> _lastNotificationTimes = {};

  NotificationService(this._ref);

  /// Called automatically by main.dart on app start
  Future<void> init() async {
    await localNotifier.setup(
      appName: 'Zedu',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> handleIncomingMessage(
    Map<String, dynamic> message,
    String channelId,
    String senderName,
  ) async {
    final settings = _ref.read(notificationSettingsProvider);
    final authState = _ref.read(authNotifierProvider);
    final currentUserId = authState.user?.id ?? '';

    final senderId = (message['user_id'] ?? message['userId']).toString();

    // Do not notify for our own messages
    if (senderId == currentUserId || senderId == 'me') return;

    // Suppress if global DND is active
    if (settings.isDndActive) return;

    // Suppress if user is muted
    if (settings.isMuted(senderId)) return;

    // Suppress if the thread is already active and the window is focused
    final isFocused = await windowManager.isFocused();
    final selectedChannel = _ref.read(selectedDmProvider)?.channelId;

    if (isFocused && selectedChannel == channelId) {
      return;
    }

    // Rate limiter: 1 notification per user every 5 seconds
    final now = DateTime.now();
    final lastTime = _lastNotificationTimes[senderId];
    if (lastTime != null && now.difference(lastTime).inSeconds < 5) {
      return;
    }
    _lastNotificationTimes[senderId] = now;

    // Extract message content
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

      // Navigate to the DM using GoRouter
      final router = locator<GoRouter>();
      router.go('/dms/$channelId');
    };

    await notification.show();
  }
}
