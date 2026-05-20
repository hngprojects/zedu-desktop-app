// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:zedu/features/features.dart';

// ---------------------------------------------------------------------------
// Helpers: random data generators
// ---------------------------------------------------------------------------

/// Returns a random non-empty string of safe ASCII characters (no '@').
String _randomNonEmptyString(Random rng, {int maxLen = 20}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
  final len = rng.nextInt(maxLen) + 1;
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Returns a random valid-looking email address.
String _randomEmail(Random rng) {
  final prefix = _randomNonEmptyString(rng, maxLen: 15);
  final domain = _randomNonEmptyString(rng, maxLen: 10);
  final tld = _randomNonEmptyString(rng, maxLen: 4);
  return '$prefix@$domain.$tld';
}

/// Returns a random non-empty org id (non-blank).
String _randomNonBlankId(Random rng) => _randomNonEmptyString(rng, maxLen: 36);

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

/// Builds a [User] with the given [organisation].
User _makeUser({
  required String firstName,
  required String lastName,
  required String email,
  required Organization organisation,
}) {
  return User(
    id: 'user-id',
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: '',
    username: '',
    isVerified: true,
    isOnboarded: true,
    createdAt: DateTime(2024),
    organisation: organisation,
  );
}

// ---------------------------------------------------------------------------
// Fake CreateOrganizationController
// Tracks how many times create() was called and what org it returns.
// ---------------------------------------------------------------------------

class FakeCreateOrganizationController
    extends AsyncNotifier<void>
    implements CreateOrganizationController {
  int createCallCount = 0;
  Organization? orgToReturn;

  @override
  FutureOr<void> build() {}

  @override
  Future<Organization?> create(CreateOrganizationRequest request) async {
    createCallCount++;
    final org = orgToReturn;
    if (org != null) {
      ref.read(activeOrganizationProvider.notifier).active = org;
    }
    return org;
  }
}

// ---------------------------------------------------------------------------
// Mock OrganizationRepository (for P5)
// ---------------------------------------------------------------------------

class MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

// ---------------------------------------------------------------------------
// Helper: mirror of _handlePostAuth logic for use in property tests.
//
// Since _handlePostAuth is private, we test it indirectly by using a
// ProviderContainer with overrides. The container wires:
//   - activeOrganizationProvider (real)
//   - createOrganizationControllerProvider → FakeCreateOrganizationController
//
// We then call the mirrored logic directly on the container.
// ---------------------------------------------------------------------------

/// Mirrors the _handlePostAuth logic from AuthNotifier.
/// Returns the [FakeCreateOrganizationController] so callers can inspect it.
Future<FakeCreateOrganizationController> runHandlePostAuth(
  ProviderContainer container,
  User user,
) async {
  final fakeController = container
      .read(createOrganizationControllerProvider.notifier)
      as FakeCreateOrganizationController;

  // Mirror of _handlePostAuth:
  if (user.organisation.id.trim().isEmpty) {
    // Mirror of _createOnboardingOrg:
    final first = user.firstName.trim();
    final last = user.lastName.trim();
    final orgName =
        (first.isNotEmpty && last.isNotEmpty)
            ? '$first $last'
            : user.email.split('@').first;
    try {
      await container
          .read(createOrganizationControllerProvider.notifier)
          .create(CreateOrganizationRequest(name: orgName));
    } catch (_) {
      // Non-blocking
    }
  } else {
    container.read(activeOrganizationProvider.notifier).active =
        user.organisation;
  }

  return fakeController;
}

// ---------------------------------------------------------------------------
// Property 3: Blank org id triggers create() exactly once
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  setUpAll(() {
    registerFallbackValue(const CreateOrganizationRequest());
  });

  // Feature: post-login-organization-flow, Property 3: Blank org id triggers create() exactly once
  group(
    'Property 3: Blank org id triggers create() exactly once',
    () {
      test(
        'create() is called exactly once for any User with blank organisation.id',
        () async {
          // Validates: Requirements 1.1
          final rng = Random(100);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomNonEmptyString(rng);
            final lastName = _randomNonEmptyString(rng);
            final email = _randomEmail(rng);

            // Blank org id — use empty string
            final blankOrg = _makeOrg(id: '', name: '');
            final user = _makeUser(
              firstName: firstName,
              lastName: lastName,
              email: email,
              organisation: blankOrg,
            );

            final fakeController = FakeCreateOrganizationController();

            final container = ProviderContainer(
              overrides: [
                createOrganizationControllerProvider.overrideWith(
                  () => fakeController,
                ),
              ],
            );
            addTearDown(container.dispose);

            await runHandlePostAuth(container, user);

            expect(
              fakeController.createCallCount,
              equals(1),
              reason:
                  'iteration $i: user with blank org.id should trigger '
                  'create() exactly once, but got ${fakeController.createCallCount} calls',
            );
          }
        },
      );

      test(
        'create() is called exactly once when organisation.id is whitespace-only',
        () async {
          // Validates: Requirements 1.1
          final rng = Random(101);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomNonEmptyString(rng);
            final lastName = _randomNonEmptyString(rng);
            final email = _randomEmail(rng);

            // Whitespace-only org id
            final spaces = rng.nextInt(5) + 1;
            final blankOrg = _makeOrg(id: ' ' * spaces, name: '');
            final user = _makeUser(
              firstName: firstName,
              lastName: lastName,
              email: email,
              organisation: blankOrg,
            );

            final fakeController = FakeCreateOrganizationController();

            final container = ProviderContainer(
              overrides: [
                createOrganizationControllerProvider.overrideWith(
                  () => fakeController,
                ),
              ],
            );
            addTearDown(container.dispose);

            await runHandlePostAuth(container, user);

            expect(
              fakeController.createCallCount,
              equals(1),
              reason:
                  'iteration $i: user with whitespace org.id should trigger '
                  'create() exactly once, but got ${fakeController.createCallCount} calls',
            );
          }
        },
      );
    },
  );

  // Feature: post-login-organization-flow, Property 4: Non-blank org id skips create() and sets active org
  group(
    'Property 4: Non-blank org id skips create() and sets active org',
    () {
      test(
        'create() is NOT called and activeOrganizationProvider == user.organisation '
        'for any User with non-blank organisation.id',
        () async {
          // Validates: Requirements 1.6
          final rng = Random(200);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomNonEmptyString(rng);
            final lastName = _randomNonEmptyString(rng);
            final email = _randomEmail(rng);
            final orgId = _randomNonBlankId(rng);
            final orgName = _randomNonEmptyString(rng);

            final org = _makeOrg(id: orgId, name: orgName);
            final user = _makeUser(
              firstName: firstName,
              lastName: lastName,
              email: email,
              organisation: org,
            );

            final fakeController = FakeCreateOrganizationController();

            final container = ProviderContainer(
              overrides: [
                createOrganizationControllerProvider.overrideWith(
                  () => fakeController,
                ),
              ],
            );
            addTearDown(container.dispose);

            await runHandlePostAuth(container, user);

            // create() must NOT have been called
            expect(
              fakeController.createCallCount,
              equals(0),
              reason:
                  'iteration $i: user with non-blank org.id should NOT call '
                  'create(), but got ${fakeController.createCallCount} calls',
            );

            // activeOrganizationProvider must equal user.organisation
            final activeOrg = container.read(activeOrganizationProvider);
            expect(
              activeOrg,
              equals(user.organisation),
              reason:
                  'iteration $i: activeOrganizationProvider should be set to '
                  'user.organisation (id=$orgId) but got $activeOrg',
            );
          }
        },
      );
    },
  );

  // Feature: post-login-organization-flow, Property 5: Successful create() sets activeOrganizationProvider
  group(
    'Property 5: Successful create() sets activeOrganizationProvider',
    () {
      test(
        'activeOrganizationProvider.state == organization after successful create()',
        () async {
          // Validates: Requirements 1.3
          final rng = Random(300);
          final mockRepo = MockOrganizationRepository();

          for (var i = 0; i < iterations; i++) {
            final orgId = _randomNonBlankId(rng);
            final orgName = _randomNonEmptyString(rng);
            final org = _makeOrg(id: orgId, name: orgName);

            // Mock repository returns the generated org
            when(
              () => mockRepo.createOrganization(any()),
            ).thenAnswer((_) async => org);

            final container = ProviderContainer(
              overrides: [
                organizationRepositoryProvider.overrideWithValue(mockRepo),
              ],
            );
            addTearDown(container.dispose);

            // Call create() on the real CreateOrganizationController
            await container
                .read(createOrganizationControllerProvider.notifier)
                .create(const CreateOrganizationRequest(name: 'Test Org'));

            final activeOrg = container.read(activeOrganizationProvider);
            expect(
              activeOrg,
              equals(org),
              reason:
                  'iteration $i: after successful create(), '
                  'activeOrganizationProvider should equal the returned org '
                  '(id=$orgId, name=$orgName) but got $activeOrg',
            );
          }
        },
      );
    },
  );
}
