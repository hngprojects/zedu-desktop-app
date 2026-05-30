import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('test thread creation', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1')); // wait, what is the base url?
  });
}
