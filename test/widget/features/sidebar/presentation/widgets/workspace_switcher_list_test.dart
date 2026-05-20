// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// ---------------------------------------------------------------------------
// Helpers: random data generators
// ---------------------------------------------------------------------------

/// Returns a random non-empty string of safe ASCII characters.
String _randomNonEmptyString(Random rng, {int maxLen = 20}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
  final len = rng.nextInt(maxLen) + 1;
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Builds a minimal [Organization] with the given [id] and [name].
Organization _makeOrg({
  required String id,
  required String name,
  String logoUrl = '',
}) {
  final now = DateTime(2024);
  return Organization(
    id: id,
    name: name,
    description: '',
    email: '',
    country: '',
    industry: '',
    location: '',
    ownerId: '',
    logoUrl: logoUrl,
    channelsCount: 0,
    totalMessagesCount: 0,
    userRole: '',
    organizationPlan: OrganizationPlan(
      id: '',
      organizationId: id,
      planId: '',
      startedAt: now,
      endedAt: now,
      status: '',
      sessionId: '',
      invoicePdfUrl: '',
      createdAt: now,
      updatedAt: now,
      planDetails: PlanDetails(
        id: '',
        name: '',
        description: '',
        benefits: [],
        fee: 0,
        credits: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ),
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

/// Pumps [WorkspaceSwitcherList] inside a [ProviderScope] that overrides
/// [activeOrganizationProvider] with [org], using a plain [MaterialApp].
Future<ProviderContainer> _pumpList(
  WidgetTester tester,
  Organization? org,
) async {
  final container = ProviderContainer();
  container.read(activeOrganizationProvider.notifier).active = org;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: WorkspaceSwitcherList(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(container.dispose);
  return container;
}

/// Pumps a home scaffold with a button that opens [WorkspaceSwitcherList] as
/// a [showGeneralDialog] overlay — matching real usage from
/// [WorkspaceSwitcherHeader._showWorkspaceSwitcher].
///
/// The router has a base `/` route and the org-settings / create-org routes so
/// that [context.go] calls inside the list succeed.
///
/// Returns the [GoRouter] so tests can inspect the current location.
Future<GoRouter> _pumpListAsDialog(
  WidgetTester tester,
  Organization org,
) async {
  final container = ProviderContainer();
  container.read(activeOrganizationProvider.notifier).active = org;

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () {
                showGeneralDialog(
                  context: ctx,
                  barrierDismissible: true,
                  barrierLabel: 'WorkspaceSwitcher',
                  barrierColor: Colors.black26,
                  transitionDuration: Duration.zero,
                  pageBuilder: (context, _, _) => const Align(
                    alignment: Alignment.topLeft,
                    child: WorkspaceSwitcherList(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/organization-settings/:orgId',
        builder: (context, state) => Scaffold(
          body: Text('settings-${state.pathParameters['orgId']}'),
        ),
      ),
      GoRoute(
        path: '/create-organization',
        builder: (context, state) =>
            const Scaffold(body: Text('create-org')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Open the dialog.
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  addTearDown(container.dispose);
  addTearDown(router.dispose);

  return router;
}

// ---------------------------------------------------------------------------
// Property 7: WorkspaceSwitcherList renders org name and avatar when non-null
// ---------------------------------------------------------------------------

void main() {
  const iterations = 100;

  // Feature: post-login-organization-flow, Property 7: List renders org name and avatar when org is non-null
  group(
    'Property 7: WorkspaceSwitcherList renders org name and avatar when org is non-null',
    () {
      testWidgets(
        'widget tree contains organization.name and OrganizationLogo '
        'for any non-null Organization',
        (tester) async {
          // Validates: Requirements 4.2
          final rng = Random(700);

          // 800 wide gives the 320-wide list plenty of room.
          await tester.binding.setSurfaceSize(const Size(800, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonEmptyString(rng, maxLen: 36);
            final orgName = _randomNonEmptyString(rng, maxLen: 30);
            final org = _makeOrg(id: orgId, name: orgName);

            await _pumpList(tester, org);

            // The org name must appear at least once in the widget tree.
            // It appears in both the header section and the list item.
            expect(
              find.text(orgName),
              findsWidgets,
              reason:
                  'iteration $i: WorkspaceSwitcherList should display '
                  '"$orgName" when activeOrganizationProvider holds an org '
                  'with that name (id=$orgId)',
            );

            // OrganizationLogo must be present in the header section.
            expect(
              find.byType(OrganizationLogo),
              findsOneWidget,
              reason:
                  'iteration $i: WorkspaceSwitcherList should render an '
                  'OrganizationLogo widget for org (id=$orgId, name=$orgName)',
            );
          }
        },
      );

      testWidgets(
        'widget renders SizedBox.shrink (nothing visible) when org is null',
        (tester) async {
          // Validates: Requirements 4.1
          await tester.binding.setSurfaceSize(const Size(800, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await _pumpList(tester, null);

          expect(find.byType(Container), findsNothing);
          expect(find.byType(Text), findsNothing);
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Property 8: Settings button navigates to the correct org settings route
  // ---------------------------------------------------------------------------

  // Feature: post-login-organization-flow, Property 8: Settings button navigates to the correct org settings route
  group(
    'Property 8: Settings button navigates to the correct org settings route',
    () {
      testWidgets(
        'tapping Settings navigates to AppRouter.organizationSettings(org.id) '
        'for any Organization with a random id',
        (tester) async {
          // Validates: Requirements 6.1
          final rng = Random(800);

          await tester.binding.setSurfaceSize(const Size(800, 700));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonEmptyString(rng, maxLen: 36);
            final orgName = _randomNonEmptyString(rng, maxLen: 30);
            final org = _makeOrg(id: orgId, name: orgName);

            final router = await _pumpListAsDialog(tester, org);

            // Tap the Settings button inside the dialog.
            final settingsButton = find.widgetWithText(OutlinedButton, 'Settings');
            expect(
              settingsButton,
              findsOneWidget,
              reason:
                  'iteration $i: Settings button should be present when '
                  'activeOrg is non-null (id=$orgId)',
            );
            await tester.tap(settingsButton);
            await tester.pumpAndSettle();

            // The router should have navigated to the org settings route.
            final expectedPath = AppRouter.organizationSettings(orgId);
            final currentLocation =
                router.routerDelegate.currentConfiguration.uri.toString();

            expect(
              currentLocation,
              equals(expectedPath),
              reason:
                  'iteration $i: after tapping Settings, navigation target '
                  'should be "$expectedPath" but was "$currentLocation" '
                  '(orgId=$orgId)',
            );
          }
        },
      );
    },
  );
}
