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
Organization _makeOrg({required String id, required String name}) {
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
    logoUrl: '',
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

/// Pumps [WorkspaceSwitcherHeader] inside a [ProviderScope] that overrides
/// [activeOrganizationProvider] with [org].
Future<void> _pumpHeader(
  WidgetTester tester,
  Organization? org,
) async {
  // Use a ProviderContainer to pre-seed the state, then pass it to
  // UncontrolledProviderScope so the widget reads the already-set value.
  final container = ProviderContainer();
  container.read(activeOrganizationProvider.notifier).active = org;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: WorkspaceSwitcherHeader(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(container.dispose);
}

// ---------------------------------------------------------------------------
// Property 6: WorkspaceSwitcherHeader renders org name when org is non-null
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  // Feature: post-login-organization-flow, Property 6: Header renders org name when org is non-null
  group(
    'Property 6: WorkspaceSwitcherHeader renders org name when org is non-null',
    () {
      testWidgets(
        'widget tree contains organization.name as visible text '
        'for any non-null Organization',
        (tester) async {
          // Validates: Requirements 3.2
          final rng = Random(600);

          await tester.binding.setSurfaceSize(const Size(400, 200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonEmptyString(rng, maxLen: 36);
            final orgName = _randomNonEmptyString(rng, maxLen: 30);
            final org = _makeOrg(id: orgId, name: orgName);

            await _pumpHeader(tester, org);

            expect(
              find.text(orgName),
              findsOneWidget,
              reason:
                  'iteration $i: WorkspaceSwitcherHeader should display '
                  '"$orgName" when activeOrganizationProvider holds an org '
                  'with that name (id=$orgId)',
            );
          }
        },
      );

      testWidgets(
        'widget renders SizedBox.shrink (nothing visible) when org is null',
        (tester) async {
          // Validates: Requirements 3.3
          await tester.binding.setSurfaceSize(const Size(400, 200));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await _pumpHeader(tester, null);

          // No Container or Text should be rendered — only the empty SizedBox
          expect(find.byType(Container), findsNothing);
          expect(find.byType(Text), findsNothing);
        },
      );
    },
  );
}
