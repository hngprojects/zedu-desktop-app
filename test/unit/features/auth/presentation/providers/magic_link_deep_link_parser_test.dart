import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('MagicLinkDeepLinkParser', () {
    test('extracts token from custom zedu scheme link', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('extracts token from https auth link', () {
      final uri = Uri.parse(
        'https://api.staging.zedu.chat/auth/magick-link/verify?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('returns null for missing token query parameter', () {
      final uri = Uri.parse('zedu://auth/magick-link/verify');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('accepts zedu login/magic-link variant', () {
      final uri = Uri.parse('zedu://auth/login/magic-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('accepts zedu magic-link path without verify segment', () {
      final uri = Uri.parse('zedu://auth/magic-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('accepts zedu scheme without explicit host authority', () {
      final uri = Uri.parse('zedu:auth/login/magic-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('accepts temp-mail wrapped viewer path', () {
      final uri = Uri.parse(
        'https://temp-mail.org/en/view/auth/login/magic-link?token=abc123',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, 'abc123');
    });

    test('accepts staging https auth login magic-link URL', () {
      final uri = Uri.parse(
        'https://zedu.chat/auth/login/magic-link?token=755095',
      );

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, '755095');
    });

    test('accepts token as path segment after magic-link', () {
      final uri = Uri.parse('https://zedu.chat/auth/login/magic-link/755095');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, '755095');
    });

    test('returns null for non-auth path', () {
      final uri = Uri.parse('zedu://other/magick-link?token=abc123');

      final token = MagicLinkDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });
  });
}
