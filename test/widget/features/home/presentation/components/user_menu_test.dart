import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  testWidgets('UserMenuButton renders successfully without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(bottomNavigationBar: Center(child: UserMenuButton())),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UserMenuButton), findsOneWidget);
  });
}
