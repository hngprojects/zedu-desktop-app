import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final dmNotificationServiceProvider = Provider<DmNotificationService>((ref) {
  return DmNotificationService();
});

class DmNotificationService {
  Future<void> init() async {
    await localNotifier.setup(
      appName: 'Zedu',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String messageContent,
    required String conversationId,
  }) async {
    final notification = LocalNotification(
      title: 'New Message from $senderName',
      body: messageContent,
      actions: [
        LocalNotificationAction(text: 'Reply'),
      ],
    );

    notification.onClick = () async {
      await windowManager.show();
      await windowManager.focus();
    };

    notification.onClickAction = (actionIndex) async {
      await windowManager.show();
      await windowManager.focus();
    };

    await notification.show();
  }
}
