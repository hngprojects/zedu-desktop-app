
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';


Widget buildCreateOrganizationViewUnderTest() {
  return ProviderScope(
    child: MaterialApp(
      home: Theme(data: AppTheme.light, child: const CreateOrganizationPage()),
    ),
  );
}

void main() {
  group('CreateOrganizationPage country dropdown', () {
    testWidgets('displays country names only and updates selected value', (
      tester,
    ) async {
      final countries = CountryService().getAll();

      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildCreateOrganizationViewUnderTest());
      await tester.pumpAndSettle();

      final dropdown = find.byKey(const Key('country_dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      expect(find.text(countries[0].name), findsOneWidget);
      expect(find.text(countries[1].name), findsOneWidget);

      await tester.tap(find.text(countries[2].name));
      await tester.pumpAndSettle();

      expect(find.text(countries[2].name), findsOneWidget);
    });

    testWidgets('opens dropdown below field and shows 7 items at a time', (
      tester,
    ) async {
      final countries = CountryService().getAll();

      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildCreateOrganizationViewUnderTest());
      await tester.pumpAndSettle();

      final dropdown = find.byKey(const Key('country_dropdown'));
      final fieldBottom = tester.getBottomLeft(dropdown).dy;

      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final firstItemTop = tester.getTopLeft(find.text(countries[0].name)).dy;
      expect(firstItemTop, greaterThan(fieldBottom));

      for (var i = 0; i < 7; i++) {
        expect(find.text(countries[i].name), findsOneWidget);
      }
      expect(find.text(countries[7].name), findsNothing);
    });
  });
}
