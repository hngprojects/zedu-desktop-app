# DM Bug Fixes — Task Tracker

## Bug 1: TypeError in UserProfile Notifier
- `[x]` Fix `_getRoleId()` unsafe cast at line 359
- `[x]` Fix `fetchRegisteredUsers()` unsafe cast at line 394

## Bug 2: "Conversation still being set up"
- `[x]` Add `_tryResolveChannel()` helper to `ChatHistoryNotifier`
- `[x]` Update `sendMessage()` to attempt channel resolution before failing
- `[x]` Fix `dm_sidebar_list.dart` — show error instead of silent fallback
- `[x]` Fix `dm_list_provider.dart` — resolve self-conversation channel properly

## Verification
- `[/]` Run `flutter analyze`
- `[ ]` Verify no regressions
