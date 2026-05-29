import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('API Diagnostics Test', () async {

    final dioStaging = Dio(BaseOptions(
      baseUrl: 'https://api.staging.zedu.chat/api/v1/',
      validateStatus: (status) => true,
    ));

    final dioProd = Dio(BaseOptions(
      baseUrl: 'https://api.zedu.chat/api/v1/',
      validateStatus: (status) => true,
    ));

    // ignore: avoid_print
    print('----------------------------------------');
    // ignore: avoid_print
    print('Testing STAGING GET /auth/google/callback');
    final responseStaging = await dioStaging.get<dynamic>('auth/google/callback');
    // ignore: avoid_print
    print('Staging Status: ${responseStaging.statusCode}');
    // ignore: avoid_print
    print('Staging Headers: ${responseStaging.headers}');

    // ignore: avoid_print
    print('----------------------------------------');
    // ignore: avoid_print
    print('Testing PRODUCTION GET /auth/google/callback');
    final responseProd = await dioProd.get<dynamic>('auth/google/callback');
    // ignore: avoid_print
    print('Production Status: ${responseProd.statusCode}');
    // ignore: avoid_print
    print('Production Headers: ${responseProd.headers}');
  });
}
