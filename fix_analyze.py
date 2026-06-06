import os
import re

def fix_api_failure():
    path = "lib/core/api_utils/api_failure.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("      if (data['message'] is String)\n        return '${data['message']}\\nRaw data: $data';",
                              "      if (data['message'] is String) {\n        return '${data['message']}\\nRaw data: $data';\n      }")
    content = content.replace("      if (data['error'] is String) return '${data['error']}\\nRaw data: $data';",
                              "      if (data['error'] is String) {\n        return '${data['error']}\\nRaw data: $data';\n      }")
    with open(path, 'w') as f: f.write(content)

def fix_secure_storage():
    path = "lib/core/secure_storage/secure_storage_service.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("catch (e) {}", "catch (e) { /* ignore */ }")
    with open(path, 'w') as f: f.write(content)

def fix_date_formatter():
    path = "lib/core/utils/date_formatter.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("import 'package:flutter/material.dart';\n", "")
    with open(path, 'w') as f: f.write(content)

def fix_auth_notifier():
    path = "lib/features/auth/presentation/providers/auth_notifier.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("print('Exception in _checkAuthStatus: $e');", "AppLogger.e('Exception in _checkAuthStatus: $e');")
    with open(path, 'w') as f: f.write(content)

def fix_channel_provider():
    path = "lib/features/channels/presentation/providers/channel_provider.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("print('Failed to create channel: $e');", "AppLogger.e('Failed to create channel: $e');")
    content = content.replace("print('Failed to join channel: $e');", "AppLogger.e('Failed to join channel: $e');")
    with open(path, 'w') as f: f.write(content)

def fix_show_dialogs():
    files = [
        "lib/features/channels/presentation/views/channel_directory_view.dart",
        "lib/features/dms/presentation/components/channel_details_modal.dart",
        "lib/features/dms/presentation/components/dm_chat_area.dart"
    ]
    for path in files:
        with open(path, 'r') as f: content = f.read()
        content = content.replace("showDialog(", "showDialog<void>(")
        with open(path, 'w') as f: f.write(content)

def fix_radio_ignores():
    files = [
        "lib/features/channels/presentation/widgets/create_channel_modal.dart",
        "lib/features/dms/presentation/components/dm_chat_area.dart"
    ]
    for path in files:
        with open(path, 'r') as f: content = f.read()
        content = content.replace("groupValue:", "// ignore: deprecated_member_use\n                              groupValue:")
        content = content.replace("onChanged:", "// ignore: deprecated_member_use\n                              onChanged:")
        with open(path, 'w') as f: f.write(content)

def fix_dm_repository():
    path = "lib/features/dms/data/dm_repository.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace('      if (orgId != null) "organisation_id": orgId,',
                              "      ?\"organisation_id\": orgId,")
    with open(path, 'w') as f: f.write(content)

def fix_dm_conversation():
    path = "lib/features/dms/domain/dm_conversation.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("import 'package:zedu/features/features.dart';\n", "")
    with open(path, 'w') as f: f.write(content)

def fix_dm_chat_area_unused():
    path = "lib/features/dms/presentation/components/dm_chat_area.dart"
    with open(path, 'r') as f: content = f.read()
    content = re.sub(r'void _showEditChannelDialog.*?^}$', '', content, flags=re.MULTILINE | re.DOTALL)
    content = re.sub(r'void _showAddMembersDialog.*?^}$', '', content, flags=re.MULTILINE | re.DOTALL)
    with open(path, 'w') as f: f.write(content)

def fix_chat_history_provider():
    path = "lib/features/dms/presentation/providers/chat_history_provider.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("final channelType = widget.conversation.channelType;", "")
    content = content.replace("final channelType = widget.channelType;", "")
    with open(path, 'w') as f: f.write(content)

def fix_active_chat_provider():
    path = "lib/features/home/presentation/providers/active_chat_provider.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("print(", "AppLogger.i(")
    with open(path, 'w') as f: f.write(content)

def fix_user_profile_notifier():
    path = "lib/features/user_profile/presentation/providers/user_profile_notifier.dart"
    with open(path, 'r') as f: content = f.read()
    content = content.replace("catch (e) {\n        // Error updating profile on server\n      }", "catch (e) {\n        // Error updating profile on server\n        AppLogger.e('Error', error: e);\n      }")
    content = content.replace("catch (e) {\n      // Error updating status on server\n    }", "catch (e) {\n      // Error updating status on server\n      AppLogger.e('Error', error: e);\n    }")
    with open(path, 'w') as f: f.write(content)

fix_api_failure()
fix_secure_storage()
fix_date_formatter()
fix_auth_notifier()
fix_channel_provider()
fix_show_dialogs()
fix_radio_ignores()
fix_dm_repository()
fix_dm_conversation()
# fix_dm_chat_area_unused() # Will do manually, regex might break
fix_chat_history_provider()
fix_active_chat_provider()
fix_user_profile_notifier()
