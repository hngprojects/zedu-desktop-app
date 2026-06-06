import re

with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'r') as f:
    content = f.read()

new_dialog = """void _showNotificationSettingsDialog(
  BuildContext context,
  WidgetRef ref,
  String channelId,
  String channelName,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final settings = ref.watch(notificationSettingsProvider);
      bool isMuted = settings.isChannelMuted(channelId);
      int notifyFor = 0;
      bool notifyReplies = true;

      return StatefulBuilder(
        builder: (context, setState) {
          final colors = context.colors;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications for #$channelName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text('Send a notification for', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 0,
                      groupValue: notifyFor,
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('All new messages'),
                    onTap: () => setState(() => notifyFor = 0),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 1,
                      groupValue: notifyFor,
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Mentions'),
                    onTap: () => setState(() => notifyFor = 1),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<int>(
                      value: 2,
                      groupValue: notifyFor,
                      onChanged: (val) => setState(() => notifyFor = val!),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Channels'),
                    onTap: () => setState(() => notifyFor = 2),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: notifyReplies,
                      onChanged: (val) => setState(() => notifyReplies = val ?? true),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Get notified about all thread replies in this channel'),
                    onTap: () => setState(() => notifyReplies = !notifyReplies),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: isMuted,
                      onChanged: (val) => setState(() => isMuted = val ?? false),
                      activeColor: colors.primary,
                    ),
                    title: const Text('Mute channel'),
                    onTap: () => setState(() => isMuted = !isMuted),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: colors.onSurface.withOpacity(0.6), fontSize: 11),
                      children: [
                        const TextSpan(text: 'Note: You can set notification keywords and change your workspace-wide settings in your '),
                        TextSpan(
                          text: 'settings',
                          style: TextStyle(color: colors.primary, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: TextStyle(color: colors.onSurface)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (isMuted != settings.isChannelMuted(channelId)) {
                            ref.read(notificationSettingsProvider.notifier).toggleChannelMute(channelId);
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Save changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}"""

pattern = re.compile(r'void _showNotificationSettingsDialog\(.*?^  \);\n}', re.MULTILINE | re.DOTALL)
new_content = pattern.sub(new_dialog, content)

with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'w') as f:
    f.write(new_content)
