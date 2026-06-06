import re

# auth_notifier.dart
path = "lib/features/auth/presentation/providers/auth_notifier.dart"
with open(path) as f: c = f.read()
c = re.sub(r'print\(.*?\);', 'AppLogger.i("debug");', c)
with open(path, 'w') as f: f.write(c)

# channel_provider.dart
path = "lib/features/channels/presentation/providers/channel_provider.dart"
with open(path) as f: c = f.read()
c = re.sub(r'print\(.*?\);', 'AppLogger.i("debug");', c)
with open(path, 'w') as f: f.write(c)

# dm_repository.dart
path = "lib/features/dms/data/dm_repository.dart"
with open(path) as f: c = f.read()
c = c.replace('?"organisation_id": orgId,', '// ignore: use_null_aware_elements\n      if (orgId != null) "organisation_id": orgId,')
with open(path, 'w') as f: f.write(c)

# dm_chat_area.dart
path = "lib/features/dms/presentation/components/dm_chat_area.dart"
with open(path) as f: c = f.read()
# Comment out unused functions
c = c.replace("void _showEditChannelDialog", "/* void _showEditChannelDialog")
c = c.replace("          ],", "          ], */")  # Too risky to guess end. I'll just use multi_replace_file_content!
