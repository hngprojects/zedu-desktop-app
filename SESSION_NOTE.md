# Zedu Desktop — Session Note
**Developer:** Babajide James (`james-clean` / `james-mini`)  
**Session Date:** 2026-06-06  
**Status:** Pre-merge planning — no conflicts resolved yet

---

## What This App Is

A Flutter desktop application for real-time team communication. Think Slack-like: channels, DMs, voice/video calls (Buzz), workspace/org management. Desktop-first (Windows/macOS/Linux), built with a clean architecture pattern.

**Tech Stack:** Flutter + Riverpod (state) + GoRouter (navigation) + Centrifugo WebSocket (real-time) + Agora (voice/video) + Dio (HTTP) + Hive + Secure Storage.

---

## Features YOU Built (james-clean branch)

These are implemented and functional. During any merge, your version wins for these.

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
- `chat_history_provider` — message history per conversation
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
- Note: credits route `/credits/buy` is **commented out** intentionally

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

## Features the Other Developer Built (origin/dev branch)

These exist in `dev` but are either absent or stripped from your branch. Receive these during merge.

### 1. Credits Feature (complete, full-stack)
- `lib/features/credits/` — entire feature directory
- `BuyCreditsView` at route `/credits/buy`
- Credit packages, checkout session, transaction history, usage reports
- Payment deep link listener + parser
- `creditsNotifierProvider` — loaded in `HomeView.initState` with `orgId`
- Was removed from your branch with `// ref.read(creditsNotifierProvider.notifier).load(...)` comment

### 2. Personal Profile Panel in Home
- `PersonalProfilePanel` — slides in from the right side of home
- `personalProfilePanelProvider` — show/hide state
- dev's `home_view.dart` wraps `_ChatAreaSwitcher` in a `Stack` with `PersonalProfilePanel` positioned on the right

### 3. Additional Home Widgets (dev has, check if missing from yours)
- `thread_panel.dart` — message thread side panel
- `search_panel.dart` — search panel UI
- `group_details_panel.dart` — group DM details

### 4. User Profile Improvements
- `profile_details_panel.dart` — detailed profile view panel
- `global_profile_overlay.dart` — profile overlay component
- Changes to `user_profile_notifier.dart` — may have new update flows
- `delete_account_dialog.dart` — account deletion flow

### 5. Workspace Switcher
- `workspace_header.dart`, `workspace_switcher_list.dart` — in sidebar
- `workspace_provider.dart` — improved workspace switching logic
- `WorkspaceSwitcherHeader` referenced from your `_MainSidebar`

### 6. InviteTeammatesModal
- `invite_teammates_modal.dart` — referenced in your `_InviteCard` via `showDialog`

### 7. Chat Infrastructure
- `home/data/services/chat_websocket_service.dart`
- `home/data/services/chat_storage_service.dart`

---

## Files With Conflicts (Both Developers Modified These)

These are the critical files to resolve carefully. Your version is the base, but you will need to selectively integrate from dev.

| File | Your Change | Dev Change | Strategy |
|------|-------------|------------|----------|
| `lib/core/navigator/app_router.dart` | Riverpod auth guards, splash route, no credits route | Static router, `buyCredits` route, no splash | **Keep yours** + add `/credits/buy` route from dev |
| `lib/core/api_utils/api_failure.dart` | Extended error kinds, `friendlyMessage` | Different error structure | **Keep yours** — more complete |
| `lib/core/config/app_config.dart` | env-based config, websocket URL builder | Slightly different structure | **Keep yours** — more robust |
| `lib/core/core.dart` | More exports (agora, desktop_drop, etc) | Different export set | **Merge both** — take union |
| `lib/core/secure_storage/secure_storage_service.dart` | Extended storage (cached user, token ops) | Rewritten version | **Keep yours** — critical for session restore |
| `lib/features/auth/data/datasource/auth_remote_datasource.dart` | Your implementation | Their implementation | **Compare carefully** — may have different endpoints |
| `lib/features/channels/presentation/providers/channel_provider.dart` | Your channel state | Their channel state | **Compare** — may have different APIs |
| `lib/features/channels/presentation/widgets/create_channel_modal.dart` | Your modal | Their modal | **Compare UI + logic** |
| `lib/features/home/presentation/views/home_view.dart` | GlobalCallOverlay, Window controls, no credits init | PersonalProfilePanel overlay, credits init | **Keep yours** + add `PersonalProfilePanel` overlay + wire credits init |

---

## Merge Strategy Summary

### Receive FROM incoming (dev branch)
- `lib/features/credits/` — entire folder, this is completely theirs
- `lib/features/home/presentation/widgets/thread_panel.dart` — if absent in yours
- `lib/features/home/presentation/widgets/search_panel.dart` — if absent in yours
- `lib/features/home/presentation/widgets/group_details_panel.dart` — if absent in yours
- `lib/features/user_profile/presentation/components/profile_details_panel.dart` — verify
- `lib/features/user_profile/presentation/components/global_profile_overlay.dart` — verify
- `PersonalProfilePanel` reference in `home_view.dart`
- `creditsNotifierProvider.load(orgId: orgId)` call in `HomeView.initState`
- `/credits/buy` GoRoute in `app_router.dart`

### Keep FROM current (your james-clean branch)
- All buzz/call system (active_call_provider, org_buzz_provider, buzz_log_provider, all buzz UI)
- `global_call_overlay.dart` + Stack wrapper in home scaffold
- Window caption buttons in `_HomeAppBar`
- Splash route + Riverpod auth guards in `app_router.dart`
- Extended `active_call_provider` state fields
- `pinned_messages_provider`, `notification_settings_provider`
- `people_sidebar_list.dart`, `voice_note_player.dart`
- `channel_suggestion_list.dart`
- Your `auth_notifier.dart` session fallback logic
- Your `api_failure.dart` extended error types
- Your `secure_storage_service.dart`
- `api_endpoints.dart`, `file_repository.dart`, `network_status_provider.dart`
- Assets: `buzz.png`, `default_avatar.png`, `recent_message.png`

### Merge carefully (both modified)
These need line-level review — don't blindly accept either side:
- `auth_remote_datasource.dart` — check endpoint paths, ensure all auth flows (login, signup, magic link, google, status, forgot/reset password) are present
- `channel_provider.dart` — ensure channel create/join/leave + real-time subscription coexist
- `create_channel_modal.dart` — UI parity check
- `core.dart` — take union of exports, eliminate duplicates
- `app_config.dart` — keep your env parsing logic, add any missing config fields from dev
- `home_view.dart` — surgical merge: keep your scaffold structure, add PersonalProfilePanel Stack layer

---

## Current Branch State

- **Active branch:** `james-clean`
- **Uncommitted changes:** `app_router.dart` and `home_view.dart` (2 files, unstaged)
- **WIP stash:** `james-mini` has a broken-merge-state backup stash (`ee5d32d`)
- **Before merging:** Commit or stash your current 2 unstaged changes first

---

## Pre-Merge Checklist

- [ ] Commit/stash the 2 unstaged files (`app_router.dart`, `home_view.dart`)
- [ ] Confirm which remote branch to merge (likely `origin/dev`)
- [ ] Run `git merge origin/dev` — expect conflicts in the "both modified" files above
- [ ] Resolve each conflict file using this document as the decision guide
- [ ] Re-check barrel exports: `core.dart`, `features.dart`, `dms.dart`, `auth.dart`
- [ ] Verify `flutter pub get` succeeds (pubspec.yaml may conflict)
- [ ] Run `flutter analyze` until clean
- [ ] Smoke test: splash → login → home → DM → Buzz → Credits

---

*This note is a living document. Update it after the merge is complete.*
