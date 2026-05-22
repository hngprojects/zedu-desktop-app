import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.zedu.chat/api/v1',
    headers: {
      'Authorization': 'Bearer DUMMY_TOKEN',
    },
  ));

  try {
    final response = await dio.post(
      '/organisations/019700db-4e22-7f90-a20e-f9116291ef24/users',
      data: {
        'user_id': '019700db-4e22-7f90-a20e-f9116291ef24',
        'role_id': '019700d8-9085-7f7b-839a-fcbd08b9e26d',
      },
    );
    print('Response: ' + response.data.toString());
  } on DioException catch (e) {
    print('Error code: ' + (e.response?.statusCode?.toString() ?? 'unknown'));
    print('Error data: ' + (e.response?.data?.toString() ?? 'unknown'));
  }
}
