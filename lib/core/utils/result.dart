import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

// core/utils/result.dart

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final ApiFailure error;
}
