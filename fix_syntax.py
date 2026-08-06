import re

# Fix channel_details_modal.dart
with open('lib/features/dms/presentation/components/channel_details_modal.dart', 'r') as f:
    content = f.read()

# Fix updateChannel -> updateChannelTopicOrDescription
content = re.sub(
    r'await ref.read\(channelProvider.notifier\).updateChannel\(\s*channel.id,\s*channel.copyWith\(topic: controller.text\),\s*\);',
    r'await ref.read(channelProvider.notifier).updateChannelTopicOrDescription(channelId: channel.id, topic: controller.text);',
    content
)
content = re.sub(
    r'await ref.read\(channelProvider.notifier\).updateChannel\(\s*channel.id,\s*channel.copyWith\(description: controller.text\),\s*\);',
    r'await ref.read(channelProvider.notifier).updateChannelTopicOrDescription(channelId: channel.id, description: controller.text);',
    content
)

# Fix context.colors.outline -> context.colors.borderOutline
content = content.replace('colors.outline', 'colors.borderOutline')
content = content.replace('colors.onSurface', 'colors.textPrimary')
content = content.replace('colors.surface', 'colors.background')
# Remove const from DmParticipant since it's not a const constructor
content = content.replace('const DmParticipant(', 'DmParticipant(')

with open('lib/features/dms/presentation/components/channel_details_modal.dart', 'w') as f:
    f.write(content)

# Fix dm_chat_area.dart
with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'r') as f:
    content2 = f.read()

content2 = content2.replace('colors.onSurface', 'colors.textPrimary')
content2 = content2.replace('colors.surface', 'colors.background')
content2 = content2.replace('toggleChannelMute', 'muteChannel') # Wait, toggle does not exist. Let's write custom logic for toggle.
# Actually, the logic was: if (isMuted != settings.isChannelMuted(channelId)) toggleChannelMute(). 
# If isMuted is true, muteChannel. If false, unmuteChannel.
content2 = re.sub(
    r'ref\.read\(notificationSettingsProvider\.notifier\)\.toggleChannelMute\(channelId\);',
    r'isMuted ? ref.read(notificationSettingsProvider.notifier).muteChannel(channelId) : ref.read(notificationSettingsProvider.notifier).unmuteChannel(channelId);',
    content2
)

with open('lib/features/dms/presentation/components/dm_chat_area.dart', 'w') as f:
    f.write(content2)
