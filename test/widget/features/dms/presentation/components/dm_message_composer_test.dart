import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FakeChatHistoryNotifier extends ChatHistoryNotifier {
  FakeChatHistoryNotifier(super.channelId, super.ref);

  @override
  Future<void> sendMessage(
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {}
}

Widget buildComposerUnderTest({required String channelId}) {
  return ProviderScope(
    overrides: [
      chatHistoryProvider.overrideWith(
        (ref, arg) => FakeChatHistoryNotifier(arg, ref),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DmMessageComposer(
          recipientName: 'TestRecipient',
          channelId: channelId,
        ),
      ),
    ),
  );
}

void main() {
  group('DmMessageComposer Tests', () {
    testWidgets('renders all toolbar and action buttons', (tester) async {
      await tester.pumpWidget(
        buildComposerUnderTest(channelId: 'test-channel'),
      );
      await tester.pump();

      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.strikethrough_s), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tag), findsOneWidget);
      expect(find.byIcon(Icons.horizontal_rule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('formatting buttons insert correct markdown formatting', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildComposerUnderTest(channelId: 'test-channel'),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();
      expect(find.text('****'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();
      expect(find.text('**'), findsOneWidget);
    });

    testWidgets(
      'keyboard shortcuts Ctrl+B and Ctrl+I insert correct markdown formatting',
      (tester) async {
        await tester.pumpWidget(
          buildComposerUnderTest(channelId: 'test-channel'),
        );
        await tester.pump();

        final textFieldFinder = find.byType(TextField);
        await tester.tap(textFieldFinder);
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();

        expect(find.text('****'), findsOneWidget);

        await tester.enterText(textFieldFinder, '');
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pump();

        expect(find.text('**'), findsOneWidget);
      },
    );

    testWidgets('emoji button toggles emoji picker inline', (tester) async {
      await tester.pumpWidget(
        buildComposerUnderTest(channelId: 'test-channel'),
      );
      await tester.pump();

      expect(find.byType(DmEmojiPicker), findsNothing);

      await tester.tap(find.byIcon(Icons.emoji_emotions_outlined).first);
      await tester.pump();

      expect(find.byType(DmEmojiPicker), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.byType(DmEmojiPicker), findsNothing);
    });
  });
}
