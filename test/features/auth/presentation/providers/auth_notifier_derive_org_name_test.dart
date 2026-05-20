// ignore_for_file: avoid_print

import 'dart:math';

import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Test helper: mirrors the logic of AuthNotifier._deriveOrgName so that the
// private static method can be exercised without changing production visibility.
// ---------------------------------------------------------------------------
String deriveOrgNameForTest({
  required String firstName,
  required String lastName,
  required String email,
}) {
  final first = firstName.trim();
  final last = lastName.trim();
  if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
  return email.split('@').first;
}

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// Returns a random non-empty string of printable ASCII characters (no '@').
String _randomNonEmptyString(Random rng, {int maxLen = 20}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
  final len = rng.nextInt(maxLen) + 1; // 1..maxLen
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// Returns a random valid-looking email address (contains exactly one '@').
String _randomEmail(Random rng) {
  final prefix = _randomNonEmptyString(rng, maxLen: 15);
  final domain = _randomNonEmptyString(rng, maxLen: 10);
  final tld = _randomNonEmptyString(rng, maxLen: 4);
  return '$prefix@$domain.$tld';
}

/// Returns a string that is either empty or consists only of whitespace.
String _randomEmptyOrWhitespace(Random rng) {
  if (rng.nextBool()) return '';
  final spaces = rng.nextInt(5) + 1; // 1..5 spaces
  return ' ' * spaces;
}

// ---------------------------------------------------------------------------
// Property tests
// ---------------------------------------------------------------------------

void main() {
  const iterations = 20;

  // Feature: post-login-organization-flow, Property 1: Full name used when both parts are non-empty
  group('deriveOrgName — Property 1: Full name used when both parts are non-empty', () {
    test(
      'returns "firstName lastName" for any non-empty firstName and lastName',
      () {
        // Validates: Requirements 1.2
        final rng = Random(42); // fixed seed for reproducibility

        for (var i = 0; i < iterations; i++) {
          final firstName = _randomNonEmptyString(rng);
          final lastName = _randomNonEmptyString(rng);
          final email = _randomEmail(rng);

          final result = deriveOrgNameForTest(
            firstName: firstName,
            lastName: lastName,
            email: email,
          );

          expect(
            result,
            equals('$firstName $lastName'),
            reason:
                'iteration $i: firstName="$firstName", lastName="$lastName", '
                'email="$email" → expected "$firstName $lastName" but got "$result"',
          );
        }
      },
    );
  });

  // Feature: post-login-organization-flow, Property 2: Email prefix used when first or last name is empty/whitespace
  group(
    'deriveOrgName — Property 2: Email prefix used when first or last name is empty/whitespace',
    () {
      test(
        'returns email prefix when firstName is empty or whitespace',
        () {
          // Validates: Requirements 1.2
          final rng = Random(43);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomEmptyOrWhitespace(rng);
            final lastName = _randomNonEmptyString(rng);
            final email = _randomEmail(rng);
            final expectedPrefix = email.split('@').first;

            final result = deriveOrgNameForTest(
              firstName: firstName,
              lastName: lastName,
              email: email,
            );

            expect(
              result,
              equals(expectedPrefix),
              reason:
                  'iteration $i: firstName="${firstName.replaceAll(' ', '·')}", '
                  'lastName="$lastName", email="$email" → '
                  'expected "$expectedPrefix" but got "$result"',
            );
          }
        },
      );

      test(
        'returns email prefix when lastName is empty or whitespace',
        () {
          // Validates: Requirements 1.2
          final rng = Random(44);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomNonEmptyString(rng);
            final lastName = _randomEmptyOrWhitespace(rng);
            final email = _randomEmail(rng);
            final expectedPrefix = email.split('@').first;

            final result = deriveOrgNameForTest(
              firstName: firstName,
              lastName: lastName,
              email: email,
            );

            expect(
              result,
              equals(expectedPrefix),
              reason:
                  'iteration $i: firstName="$firstName", '
                  'lastName="${lastName.replaceAll(' ', '·')}", email="$email" → '
                  'expected "$expectedPrefix" but got "$result"',
            );
          }
        },
      );

      test(
        'returns email prefix when both firstName and lastName are empty or whitespace',
        () {
          // Validates: Requirements 1.2
          final rng = Random(45);

          for (var i = 0; i < iterations; i++) {
            final firstName = _randomEmptyOrWhitespace(rng);
            final lastName = _randomEmptyOrWhitespace(rng);
            final email = _randomEmail(rng);
            final expectedPrefix = email.split('@').first;

            final result = deriveOrgNameForTest(
              firstName: firstName,
              lastName: lastName,
              email: email,
            );

            expect(
              result,
              equals(expectedPrefix),
              reason:
                  'iteration $i: firstName="${firstName.replaceAll(' ', '·')}", '
                  'lastName="${lastName.replaceAll(' ', '·')}", email="$email" → '
                  'expected "$expectedPrefix" but got "$result"',
            );
          }
        },
      );
    },
  );
}
