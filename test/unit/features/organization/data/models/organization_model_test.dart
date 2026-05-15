import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('OrganizationModel.fromJson', () {
    Map<String, dynamic> baseJson() {
      return {
        'id': 'org-1',
        'name': 'Zedu',
        'description': 'Description',
        'email': 'org@zedu.com',
        'country': 'Nigeria',
        'industry': 'Education',
        'location': 'Lagos',
        'owner_id': 'owner-1',
        'logo_url': 'https://example.com/logo.png',
        'channels_count': 2,
        'total_messages_count': 10,
        'user_role': 'owner',
        'organisation_plan': {},
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      };
    }

    test('parses country when country is a string', () {
      final json = baseJson();
      final model = OrganizationModel.fromJson(json);

      expect(model.country, 'Nigeria');
    });

    test('parses country when country is a map', () {
      final json = baseJson()
        ..['country'] = {
          'name': 'Nigeria',
          'iso2_cc': 'NG',
        };
      final model = OrganizationModel.fromJson(json);

      expect(model.country, 'Nigeria');
    });

    test('parses user role when user_role is a string', () {
      final json = baseJson();
      final model = OrganizationModel.fromJson(json);

      expect(model.userRole, 'owner');
    });

    test('parses user role when user_role is a map', () {
      final json = baseJson()
        ..['user_role'] = {
          'name': 'admin',
          'id': 'role-1',
        };
      final model = OrganizationModel.fromJson(json);

      expect(model.userRole, 'admin');
    });
  });
}
