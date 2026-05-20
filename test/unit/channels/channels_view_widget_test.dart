import '../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeChannelsNotifier extends ChannelsNotifier {
  FakeChannelsNotifier(this.initialState);

  final ChannelsState initialState;

  @override
  ChannelsState build() => initialState;

  @override
  Future<void> openChannel(String channelId) async {}
}

void main() {
  group('ChannelsView', () {
    testWidgets('shows select channel empty state when channel is missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelsNotifierProvider.overrideWith(
              () => FakeChannelsNotifier(const ChannelsState()),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChannelsView())),
        ),
      );

      await tester.pump();

      expect(find.text('Select a channel'), findsOneWidget);
    });

    testWidgets('renders html message content', (tester) async {
      final state = ChannelsState(
        selectedChannelId: ChannelsDevDefaults.mockChannelId,
        messages: [
          ChannelMessage(
            threadId: 'thread-1',
            channelId: ChannelsDevDefaults.mockChannelId,
            orgId: ChannelsDevDefaults.mockOrgId,
            username: 'alameen',
            status: 'success',
            createdAt: DateTime.utc(2026, 5, 20, 10),
            updatedAt: DateTime.utc(2026, 5, 20, 10),
            messageCount: 0,
            lastReply: null,
            avatarUrl: '',
            defaultAvatarUrl: '',
            userType: 'user',
            type: 'message',
            messageHtml: '<p><strong>Hello team</strong></p>',
            channelName: 'general',
            channelType: 'public',
            currentStatus: 'pending',
            fullName: 'alameen',
            email: 'alameensad6@gmail.com',
            userId: 'user-1',
            edited: false,
            isPinned: false,
            pinnedDetails: const <String, dynamic>{},
            reactions: null,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            channelsNotifierProvider.overrideWith(
              () => FakeChannelsNotifier(state),
            ),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(
                initial: const AuthState(status: AuthStatus.unauthenticated),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: ChannelsView())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Hello team'), findsOneWidget);
    });
  });
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
  }) : _initial = initial;

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}
