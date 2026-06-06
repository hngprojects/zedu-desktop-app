# Zedu Desktop — Session Note
**Developer:** Babajide James (`james-mini`)  
**Last Updated:** 2026-06-06  
**Status:** Merge COMPLETE — all conflicts resolved, `flutter analyze lib/` clean (0 errors)

---

## What This App Is

A Flutter desktop application for real-time team communication. Think Slack-like: channels, DMs, voice/video calls (Buzz), workspace/org management. Desktop-first (Windows/macOS/Linux), built with a clean architecture pattern.

**Tech Stack:** Flutter + Riverpod (state) + GoRouter (navigation) + Centrifugo WebSocket (real-time) + Agora (voice/video) + Dio (HTTP) + Hive + Secure Storage.

---

## Features YOU Built (james-mini branch)

These are implemented and functional. During any future merge, your version wins for these.

### 1. General Buzz — Group Call Hub
- Full Agora SDK integration for video/voice calls
- `ActiveCallState` — extended state machine: `status`, `buzzId`, `channelId`, `remoteUserName`, `remoteUserId`, `token`, `appId`, `channelName`, `buzzCode`, `invitationId`, `isOrgBuzz`, `isRemoteJoined`, `isFullPage`
- `active_call_provider` — your version has significantly more fields than the dev branch version
- `org_buzz_provider` — org-level buzz session state
- `buzz_log_provider` — call history/logs
- `GeneralBuzzView` — entry point for the buzz hub
- `BuzzMeetingView`, `BuzzPreparationView`, `BuzzReadyCard`, `BuzzAddPeopleDialog`
- `GlobalCallOverlay` — persistent floating call overlay on top of the home scaffold
- Auto-mute on call start

### 2. Real-time Messaging System
- Centrifugo WebSocket integration directly in providers (not a core service)
- Voice note recording and playback (`voice_note_player.dart`, uses `record` package)
- Image display and upload in chat
- `chat_history_provider` — message history per conversation, with pre-upload file flow
- `pinned_messages_provider` — pinned messages per channel
- `notification_settings_provider` — per-chat notification preferences
- Message deduplication (prevents double messages from WebSocket + REST)
- `channel_suggestion_list.dart` in composer

### 3. People Sidebar & Org Management
- `PeopleSidebarList` — org-members list in the DMs sidebar
- `org_people_provider` — fetches and holds org member list
- Avatar color coding by user ID hash
- Tap-to-DM directly from the people list

### 4. Home Layout & Navigation
- `home_view.dart` — 3-column layout: `AppSidebarRail` → `_MainSidebarSwitcher` → `_ChatAreaSwitcher`
- `_HomeAppBar` with custom Window caption buttons (minimize/maximize/close)
- `GlobalCallOverlay` wrapped in a Stack over the entire home scaffold
- `homeSidebarProvider` drives the entire navigation between DMs / People / Buzz / Files
- `activeChatProvider` holds the currently-selected DM, channel, or group
- `_ChatAreaSwitcher` — smart routing between DM chat, channel chat, group DM, buzz, files
- Files view (UI scaffold, not wired to backend)
- `_MainSidebarSwitcher` — swaps between DmSidebarList, PeopleSidebarList, or main channel list

### 5. Auth & Session
- `AuthNotifier` — full state machine: unknown → unauthenticated → authenticated
- Offline session fallback: if API fails but a cached user JSON is in secure storage, restores auth silently
- JWT clear on 401/403, cache clear on logout
- Magic link verification via deep link
- Invitation deep link parser
- Google Sign-In (OAuth grant code → backend → JWT)
- Status management (online/offline/custom emoji + text + timeout)
- Splash screen (`/` route) to handle session restoration before routing

### 6. Routing
- `app_router.dart` — Riverpod-aware `GoRouter` with:
  - Auth redirect guards (unauthenticated → `/login`, unknown → `/`)
  - Splash route `/` as initial location
  - Protected routes: `/home`, `/profile`, `/create-organization`

### 7. Desktop Window Controls
- Minimize, maximize (toggle), and close buttons in `_HomeAppBar`
- Guard: only renders on Windows/macOS/Linux
- `DesktopManager` — tray icon, prevent-close-to-tray behavior, local notifications

### 8. Additional Assets & Config
- `assets/pngs/buzz.png`, `default_avatar.png`, `recent_message.png`
- GitHub Actions workflow for Windows release (`windows-release.yml`)
- `api_endpoints.dart` — centralized endpoint constants
- `file_repository.dart` — multipart file upload via Dio
- `network_status_provider.dart` — connectivity check

---

## Completed Merge: `origin/dev-test` → `james-mini`

### What was REMOVED from the merge (credits feature — fully deleted)
- `lib/features/credits/` — entire folder deleted
- Credits menu items removed from `top_user_menu.dart` and `user_menu_dialog.dart`
- Credits provider init removed from home view
- Credits route `/credits/buy` not included in router

### What was RECEIVED from `origin/dev-test`

| Feature | Files |
|---------|-------|
| Thread replies panel | `dm_chat_area.dart` — dev's full ~2400-line version taken (includes `_ThreadRepliesPanel`, `_PinnedMessagesPanel`) |
| Group DM API | `group_dm_provider.dart` — added `fetchGroupDms()` from server + `sendMessage` with channelType routing |
| Profile panels | `PersonalProfilePanel` + `ProfileDetailsPanel` — wired into `home_view.dart` as right-side overlays |
| DM list tile routing | `dm_list_tile.dart` — dev's `onTap` dispatches correctly to group_dm vs dm |
| Add channel members | `create_channel_modal.dart` + `components.dart` barrel updated |
| Group DM create | `create_channel_modal.dart` — dev's full implementation |
| Workspace header/switcher | `workspace_header.dart`, `workspace_switcher_list.dart` |
| Profile action/contact rows | `action_button.dart`, `contact_info_row.dart` in user_profile components |

### What was KEPT from `james-mini` (your branch wins)

| Concern | Decision |
|---------|----------|
| `dm_chat_area.dart` | Took dev's version (strictly superset — has thread + pinned panels absent in ours) |
| `home_view.dart` | Restored our HEAD (GlobalCallOverlay + 3-column structure), then added dev's profile panel Stack layer |
| `dm_sidebar_list.dart` | Kept ours (has search + `_GroupDmsSection` class) |
| `dm_repository.dart` | Kept our structure + added channelType routing; `sendMessage` uses `List<dynamic>?` (pre-uploaded) not `List<XFile>?` |
| `chat_history_provider.dart` | Kept our file pre-upload flow; added channelType routing + `_isChannel` getter + nested sender normalization |
| `user_profile_notifier.dart` | Kept our Centrifugo subscription; added dev's auth guard; kept our robust role ID extraction |
| `secure_storage_service.dart` | Kept ours (critical for session restore) |
| `api_failure.dart` | Kept ours (more complete error kinds + `friendlyMessage`) |
| `app_config.dart` | Kept ours (env-based config, websocket URL builder) |
| `app_router.dart` | Kept ours (Riverpod auth guards, splash route, no credits route) |
| `channel_provider.dart` | Kept ours (Centrifugo subscription + channel state machine) |
| `core.dart` | Union merge (ours + dev exports, excluding test packages flutter_test/mocktail from barrel) |

---

## Post-Merge Analysis Results

### `flutter analyze lib/` result: **0 errors, 1 warning, 2 infos**
- Warning: `isHighlight` param in `user_menu_dialog.dart` never passed `true` (harmless — credits items removed)
- Info: redundant imports in `global_call_overlay.dart` (already re-exported via `core.dart`)

### Fixes applied after analysis
- Removed duplicate recording methods in `dm_message_composer.dart` (lines 77-148 were dead code from merge)
- Removed non-existent `presentation/presentation.dart` export from `sidebar.dart`
- Removed unused `_generateUuid` + `_mediaPayloadFromFile` helpers from `dm_repository.dart`

---

## Current Branch State

- **Active branch:** `james-mini`
- **Merge source:** `origin/dev-test`
- **All conflict files staged** — ready to commit
- **Next step:** commit the resolved merge, then run a full build test

## Remaining To-Do

- [ ] Commit the merge resolution
- [ ] `flutter build windows` — confirm release build succeeds
- [ ] Smoke test: splash → login → home → DM → group DM → Buzz → profile panel
- [ ] Push `james-mini` when build is confirmed

---

*Updated after merge completion on 2026-06-06.*
