import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: '"https://api.staging.zedu.chat/api/v1"'));
  try {
    await dio.post('auth/login', data: {"email": "test@test.com", "password": "123"});
  } catch (e) {
    print(e);
    if (e is DioException) {
      print(e.response?.data);
    }
  }
}
