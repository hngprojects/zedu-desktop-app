import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';
import 'package:zedu/features/home/presentation/components/user_menu_button.dart';

void main() {
  testWidgets('UserMenuButton renders successfully without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: Center(
              child: UserMenuButton(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify UserMenuButton is shown
    expect(find.byType(UserMenuButton), findsOneWidget);
  });
}
