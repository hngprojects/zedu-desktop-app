import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// import 'package:zedu/core/core.dart';
class ApiResponseModel<T> {
  const ApiResponseModel({
    required this.data,
    required this.statusCode,
    this.message,
  });

  final T data;
  final int statusCode;
  final String? message;
}
