# Direct Messaging (DM) Implementation Plan (Updated)

This document outlines the architectural approach and specific tasks to implement the Direct Messaging module in the Zedu desktop application, strictly adhering to the double barrel export pattern, Riverpod state management, and the updated requirement to **exclude local persistence** in favor of global standard pagination.

## Goal Description
Implement a fully functional, Slack-like Direct Messaging interface on the Zedu desktop app. This includes the sidebar conversation list, a center panel for messaging with rich text formatting, file attachments, native desktop OS integration (notifications, drag-and-drop), and an integrated 1-on-1 audio/video call system (Buzz) powered by the **Agora** RTC SDK. All data will be fetched directly from the backend API, using pagination (batches of 50) instead of local caching.

## User Review Required
> [!IMPORTANT]
> Please review the updated plan, which removes Hive and introduces pagination for both the conversation list and message history. 
> Also, confirm the UI breakdown for the "Buzz Meeting" views matches your expectations based on the Figma attachments.

## Proposed Changes

### 1. DM-01: DM Conversation List & Navigation Sidebar (Paginated)
**Objective:** Display a paginated, real-time list of DMs in the sidebar with unread badges.
- **Data Layer**:
  - `DmRepository`: Fetch conversations from the backend (e.g., `GET /api/v1/dms/conversations`) passing `page` and `limit=50`. No local caching logic.
- **Presentation Layer**:
  - `DmSidebarList`: A `ListView.builder` combined with a `NotificationListener<ScrollNotification>` to trigger loading the next page of 50 conversations when the user scrolls near the bottom.
  - `DmListTile`: Renders individual conversations (avatar, name, last message, timestamp, unread badge).
- **State Management**:
  - `dmListProvider`: An `AsyncNotifier` that manages the paginated list state, tracking the current page and whether more pages are available (`hasMore`).

### 2. DM-02: Center Panel & Rich Message Composer
**Objective:** Robust messaging center panel with rich text toolbar, profile card header, and paginated message history.
- **Presentation Layer**:
  - `DmChatArea`: Replaces the current `_ChatArea` when a DM is selected. Contains the header, message list, and composer.
  - `DmProfileCard`: Renders the initial state of a conversation (Avatar, "This conversation is just between you and @User... View Profile").
  - `MessageList`: A reversed `ListView.builder` that paginates older messages (batches of 50) as the user scrolls up.
  - `DmMessageComposer`: Advanced text input supporting:
    - Rich text formatting toolbar (bold, italic, strikethrough, link, lists, code, quote).
    - `Cmd/Ctrl+Enter` to send.
- **State Management**:
  - `chatHistoryProvider(String conversationId)`: Family modifier to fetch and paginate messages per thread.

### 3. DM-03: Native File Handling
**Objective:** Seamless drag-and-drop, clipboard pasting, and native OS file viewing.
- **Dependencies**: `desktop_drop` (drag & drop), `super_clipboard` (pasting images), `file_picker`, `url_launcher`.
- **Implementation**:
  - Wrap `DmChatArea` with a `DropTarget` to intercept dragged files.
  - Implement a clipboard listener inside `DmMessageComposer` to intercept `Cmd/Ctrl+V` for image pasting.
  - Since we aren't using a local queue (no Hive), files will be uploaded directly to the backend endpoint and tracked in state with a loading indicator in the UI.

### 4. DM-04: Native OS Notifications
**Objective:** Native OS notifications for incoming messages.
- **Dependencies**: `local_notifier`.
- **Implementation**:
  - `NotificationService`: Listens to the global WebSocket for incoming messages.
  - Evaluates user settings (Global DND, User Muted) before triggering a native desktop notification.
  - Tapping the notification brings the Zedu window to focus and navigates to the specific DM.

### 5. DM-05: Buzz Calls (Agora RTC Integration)
**Objective:** Initiate, ring, and manage A/V calls directly from the DM interface.
- **Dependencies**: `agora_rtc_engine`.
- **Presentation Layer**:
  - Add a "Buzz" (Start Call) action to the DM Header.
  - `BuzzPreparationView`: Shows the "Preparing your buzz..." loading state.
  - `BuzzMeetingView`: The active call interface. Renders the split video grid (e.g., Devon Lane and Darlene Robertson) as per the Figma designs, including controls for Mute, Video, End, and "Hand Raised" indicators.
  - Supports both full-page mode and responsive sidebar-adjacent modes.
- **Data Layer (`features/buzz/`)**:
  - `BuzzRepository`: Calls the backend to create a meeting room and acquire the Agora Token.
  - `BuzzEngineService`: Wraps the Agora SDK to handle joining channels, rendering remote/local video views, and managing audio/video state.

## Verification Plan
### Automated Tests
- Write unit tests for `dmListProvider` to verify the pagination logic (e.g., correctly appending new pages of 50 items and stopping when `hasMore` is false).

### Manual Verification
1. **Pagination:** Scroll down the DM list and ensure it seamlessly fetches the next 50 chats. Repeat for scrolling up in the message history.
2. **Composer:** Verify the formatting toolbar renders correctly. Type a message and hit `Cmd/Ctrl+Enter` to verify it sends.
3. **Buzz Calls:** Initiate a call, verify the "Preparing..." state, connect, and ensure the Agora video views render correctly with the custom UI overlays (Hand raised, mute toggles).
4. **Notifications:** Simulate an incoming message in the background and verify `local_notifier` displays the desktop popup.
