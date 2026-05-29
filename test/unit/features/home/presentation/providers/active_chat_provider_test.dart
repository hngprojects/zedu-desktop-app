import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('ActiveChatNotifier Tests', () {
    test('initial state is generalChannel', () {
      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWithValue('org-1'),
        ],
      );
      addTearDown(container.dispose);

      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.channel));
      expect(activeChat.id, equals('general'));
    });

    test('selectChannel updates state correctly', () {
      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWithValue('org-1'),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.channel));
      expect(activeChat.id, equals('channel-123'));
    });

    test('selectDirectMessage updates state correctly', () {
      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWithValue('org-1'),
        ],
      );
      addTearDown(container.dispose);

      container.read(activeChatProvider.notifier).selectDirectMessage('user-123');
      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.directMessage));
      expect(activeChat.id, equals('user-123'));
    });

    test('changing orgId resets to generalChannel if lastOrgId and newOrgId are both non-empty and different', () {
      final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(orgIdStateProvider)),
        ],
      );
      addTearDown(container.dispose);

      // Read activeChat to initialize the provider
      var activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));

      // Select channel
      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Re-read activeChat to verify it is still 'channel-123'
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Change org ID
      container.read(orgIdStateProvider.notifier).state = 'org-2';

      // Verify activeChat resets to 'general' because the organization ID changed from 'org-1' to 'org-2'
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));
    });

    test('rebuilding with same orgId does not reset to generalChannel', () {
      final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(orgIdStateProvider)),
        ],
      );
      addTearDown(container.dispose);

      // Read to initialize
      var activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));

      // Select channel
      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Trigger a rebuild of currentOrgIdProvider with the same value
      container.read(orgIdStateProvider.notifier).state = 'org-1';

      // Verify activeChat remains 'channel-123'
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));
    });

    test('rebuilding with transition from empty to non-empty orgId does not reset to generalChannel if a channel was selected', () {
      final orgIdStateProvider = StateProvider<String>((ref) => '');

      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(orgIdStateProvider)),
        ],
      );
      addTearDown(container.dispose);

      // Read to initialize
      var activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));

      // Select channel
      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Transition from empty to 'org-1'
      container.read(orgIdStateProvider.notifier).state = 'org-1';

      // Verify activeChat remains 'channel-123' (since the transition was from empty, not a true switch between two distinct organizations)
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));
    });

    test('rebuilding with transition from non-empty to empty to same non-empty orgId does not reset to generalChannel', () {
      final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(orgIdStateProvider)),
        ],
      );
      addTearDown(container.dispose);

      // Read to initialize
      var activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));

      // Select channel
      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Transition from 'org-1' to ''
      container.read(orgIdStateProvider.notifier).state = '';
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      // Transition from '' to 'org-1'
      container.read(orgIdStateProvider.notifier).state = 'org-1';
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));
    });
  });
}
