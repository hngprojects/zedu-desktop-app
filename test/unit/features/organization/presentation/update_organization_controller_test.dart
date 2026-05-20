// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
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
// Property 10: UpdateOrganizationController updates activeOrganizationProvider on success
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  setUpAll(() {
    registerFallbackValue(
      const UpdateOrganizationRequest(orgId: 'fallback-id'),
    );
  });

  // Feature: post-login-organization-flow, Property 10: UpdateOrganizationController updates activeOrganizationProvider on success
  group(
    'Property 10: UpdateOrganizationController updates activeOrganizationProvider on success',
    () {
      test(
        'activeOrganizationProvider.state == updatedOrganization after '
        'updateOrganization() succeeds for any random Organization',
        () async {
          // Validates: Requirements 7.2
          final rng = Random(1000);
          final mockRepo = MockOrganizationRepository();

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonEmptyString(rng, maxLen: 36);
            final orgName = _randomNonEmptyString(rng, maxLen: 30);
            final updatedOrg = _makeOrg(id: orgId, name: orgName);

            when(
              () => mockRepo.updateOrganization(any()),
            ).thenAnswer((_) async => updatedOrg);

            final container = ProviderContainer(
              overrides: [
                organizationRepositoryProvider.overrideWithValue(mockRepo),
              ],
            );
            addTearDown(container.dispose);

            final request = UpdateOrganizationRequest(
              orgId: orgId,
              name: orgName,
            );

            await container
                .read(updateOrganizationControllerProvider.notifier)
                .updateOrganization(request);

            final activeOrg = container.read(activeOrganizationProvider);
            expect(
              activeOrg,
              equals(updatedOrg),
              reason:
                  'iteration $i: after updateOrganization() succeeds, '
                  'activeOrganizationProvider should equal the updated org '
                  '(id=$orgId, name=$orgName) but got $activeOrg',
            );
          }
        },
      );
    },
  );
}
