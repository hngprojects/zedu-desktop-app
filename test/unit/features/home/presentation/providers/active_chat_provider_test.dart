import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('ActiveChatNotifier Tests', () {
    test('initial state is generalChannel', () {
      final container = ProviderContainer(
        overrides: [currentOrgIdProvider.overrideWithValue('org-1')],
      );
      addTearDown(container.dispose);

      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.channel));
      expect(activeChat.id, equals('general'));
    });

    test('selectChannel updates state correctly', () {
      final container = ProviderContainer(
        overrides: [currentOrgIdProvider.overrideWithValue('org-1')],
      );
      addTearDown(container.dispose);

      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.channel));
      expect(activeChat.id, equals('channel-123'));
    });

    test('selectDirectMessage updates state correctly', () {
      final container = ProviderContainer(
        overrides: [currentOrgIdProvider.overrideWithValue('org-1')],
      );
      addTearDown(container.dispose);

      container
          .read(activeChatProvider.notifier)
          .selectDirectMessage('user-123');
      final activeChat = container.read(activeChatProvider);
      expect(activeChat.type, equals(ActiveChatType.directMessage));
      expect(activeChat.id, equals('user-123'));
    });

    test(
      'changing orgId resets to generalChannel if lastOrgId and newOrgId are both non-empty and different',
      () {
        final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

        final container = ProviderContainer(
          overrides: [
            currentOrgIdProvider.overrideWith(
              (ref) => ref.watch(orgIdStateProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        var activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('general'));

        container
            .read(activeChatProvider.notifier)
            .selectChannel('channel-123');
        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));

        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));

        container.read(orgIdStateProvider.notifier).state = 'org-2';

        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('general'));
      },
    );

    test('rebuilding with same orgId does not reset to generalChannel', () {
      final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

      final container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith(
            (ref) => ref.watch(orgIdStateProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      var activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('general'));

      container.read(activeChatProvider.notifier).selectChannel('channel-123');
      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));

      container.read(orgIdStateProvider.notifier).state = 'org-1';

      activeChat = container.read(activeChatProvider);
      expect(activeChat.id, equals('channel-123'));
    });

    test(
      'rebuilding with transition from empty to non-empty orgId does not reset to generalChannel if a channel was selected',
      () {
        final orgIdStateProvider = StateProvider<String>((ref) => '');

        final container = ProviderContainer(
          overrides: [
            currentOrgIdProvider.overrideWith(
              (ref) => ref.watch(orgIdStateProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        var activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('general'));

        container
            .read(activeChatProvider.notifier)
            .selectChannel('channel-123');
        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));

        container.read(orgIdStateProvider.notifier).state = 'org-1';

        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));
      },
    );

    test(
      'rebuilding with transition from non-empty to empty to same non-empty orgId does not reset to generalChannel',
      () {
        final orgIdStateProvider = StateProvider<String>((ref) => 'org-1');

        final container = ProviderContainer(
          overrides: [
            currentOrgIdProvider.overrideWith(
              (ref) => ref.watch(orgIdStateProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        var activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('general'));

        container
            .read(activeChatProvider.notifier)
            .selectChannel('channel-123');
        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));

        container.read(orgIdStateProvider.notifier).state = '';
        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));

        container.read(orgIdStateProvider.notifier).state = 'org-1';
        activeChat = container.read(activeChatProvider);
        expect(activeChat.id, equals('channel-123'));
      },
    );
  });
}
