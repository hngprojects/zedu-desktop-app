import 'package:zedu/core/core.dart';

import 'package:zedu/features/features.dart';

void main() {
  group('InvitationDeepLinkParser', () {
    test('extracts token from custom zedu scheme link', () {
      final uri = Uri.parse('zedu://invite/accept?token=invite123');

      final token = InvitationDeepLinkParser.extractToken(uri);

      expect(token, 'invite123');
    });

    test('extracts token from https invite accept link', () {
      final uri = Uri.parse(
        'https://example.com/invite/accept?token=invite123',
      );

      final token = InvitationDeepLinkParser.extractToken(uri);

      expect(token, 'invite123');
    });

    test('extracts token from https accept-invite link', () {
      final uri = Uri.parse(
        'https://example.com/accept-invite?token=invite123',
      );

      final token = InvitationDeepLinkParser.extractToken(uri);

      expect(token, 'invite123');
    });

    test('returns null for missing token parameter', () {
      final uri = Uri.parse('zedu://invite/accept');

      final token = InvitationDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });

    test('returns null for unsupported paths', () {
      final uri = Uri.parse('https://example.com/other-path?token=invite123');

      final token = InvitationDeepLinkParser.extractToken(uri);

      expect(token, isNull);
    });
  });
}
