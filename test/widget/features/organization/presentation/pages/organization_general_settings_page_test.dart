// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

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

// ---------------------------------------------------------------------------
// Property 9: Settings page updates activeOrganizationProvider on load
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  setUpAll(() {
    registerFallbackValue('');
  });

  // Feature: post-login-organization-flow, Property 9: Settings page updates activeOrganizationProvider on load
  group(
    'Property 9: Settings page updates activeOrganizationProvider on load',
    () {
      testWidgets(
        'activeOrganizationProvider.state == organization after page loads '
        'for any random orgId',
        (tester) async {
          // Validates: Requirements 7.1
          final rng = Random(900);

          await tester.binding.setSurfaceSize(const Size(1024, 768));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonEmptyString(rng, maxLen: 36);
            final orgName = _randomNonEmptyString(rng, maxLen: 30);
            final org = _makeOrg(id: orgId, name: orgName);

            final mockRepo = MockOrganizationRepository();
            when(
              () => mockRepo.getOrganization(any()),
            ).thenAnswer((_) async => org);

            final container = ProviderContainer(
              overrides: [
                organizationRepositoryProvider.overrideWithValue(mockRepo),
              ],
            );

            // Pump the page under test.
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: OrganizationGeneralSettingsPage(orgId: orgId),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final activeOrg = container.read(activeOrganizationProvider);
            expect(
              activeOrg,
              equals(org),
              reason:
                  'iteration $i: after OrganizationGeneralSettingsPage loads '
                  'with orgId="$orgId", activeOrganizationProvider should '
                  'equal the org returned by the repository '
                  '(name=$orgName) but got $activeOrg',
            );

            // Pump an empty widget to tear down the current widget tree
            // before the next iteration so the old container can be disposed
            // cleanly without interfering with the next iteration.
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
          }
        },
      );
    },
  );
}
