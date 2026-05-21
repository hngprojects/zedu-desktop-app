# Direct Messaging Implementation Tasks (Updated)

- `[x]` **Phase 1: Project Setup & Architecture**
  - `[x]` Create `features/dms` feature folder structure.
  - `[x]` Add required dependencies to `pubspec.yaml`.

- `[x]` **Phase 2: DM-01 Sidebar Navigation & List (Paginated)**
  - `[x]` Implement `DmRepository` for fetching paginated conversation list (limit=50).
  - `[x]` Create `dmListProvider` to handle loading, caching, and pagination state.
  - `[x]` Build `DmSidebarList` UI component for the `_MainSidebar` with scroll listener for pagination.
  - `[x]` Build `DmListTile` with unread badge support.
  - `[x]` Wire up sidebar toggling in `home_view.dart` (switch between Channels and DMs).
  - `[x]` Implement "No recent chats" empty state.

- `[x]` **Phase 3: DM-02 Center Panel & Compose**
  - `[x]` Implement `chatHistoryProvider` to fetch and paginate messages per DM.
  - `[x]` Build `DmChatArea` to replace the main view when a DM is selected.
  - `[x]` Build `DmProfileCard` for the top of the chat thread.
  - `[x]` Build `MessageList` to render chat bubbles and handle reverse pagination.
  - `[x]` Build `DmMessageComposer` with rich text formatting toolbar.
  - `[x]` Implement keyboard shortcut listeners (Cmd/Ctrl+Enter to send).
  - `[x]` Add optimistic UI for sending messages.

- `[x]` **Phase 4: DM-03 Native File Handling**
  - `[x]` Setup `desktop_drop` for drag-and-drop support on `DmChatArea`.
  - `[x]` Setup `super_clipboard` listener in `DmMessageComposer` for Ctrl+V image pasting.
  - `[x]` Implement `AttachmentPreview` UI for pending uploads.
  - `[x]` Manage direct uploads to the backend.

- `[x]` **Phase 5: DM-04 OS Notifications**
  - `[x]` Integrate `local_notifier` for desktop notifications.
  - `[x]` Build `NotificationService` background listener connected to the WebSocket.
  - `[x]` Add tap-to-focus and deep linking back to the specific DM thread.

- `[x]` **Phase 6: DM-05 Buzz Calls from DM (Agora)**
  - `[x]` Add "Start Call" button to the `DmChatArea` header.
  - `[x]` Build `BuzzPreparationView` for the loading state.
  - `[x]` Build `BuzzMeetingView` for the active call, matching the provided Figma screenshots.
  - `[x]` Implement `BuzzEngineService` using `agora_rtc_engine` for A/V processing.
