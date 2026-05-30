import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  test('API Diagnostics Test', () async {
    final dioStaging = Dio(
      BaseOptions(
        baseUrl: 'https://api.staging.zedu.chat/api/v1/',
        validateStatus: (status) => true,
      ),
    );

    final dioProd = Dio(
      BaseOptions(
        baseUrl: 'https://api.zedu.chat/api/v1/',
        validateStatus: (status) => true,
      ),
    );

    print('----------------------------------------');

    print('Testing STAGING GET /auth/google/callback');
    final responseStaging = await dioStaging.get<dynamic>(
      'auth/google/callback',
    );

    print('Staging Status: ${responseStaging.statusCode}');

    print('Staging Headers: ${responseStaging.headers}');

    print('----------------------------------------');

    print('Testing PRODUCTION GET /auth/google/callback');
    final responseProd = await dioProd.get<dynamic>('auth/google/callback');

    print('Production Status: ${responseProd.statusCode}');

    print('Production Headers: ${responseProd.headers}');
  });
}
