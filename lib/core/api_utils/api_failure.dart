import 'package:zedu/core/core.dart';

// core/network/api_failure.dart

class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.path,
    this.kind = ApiFailureKind.unknown,
  });

  factory ApiFailure.fromDioException(DioException error) {
    return ApiFailure(
      message: _resolveMessage(error),
      statusCode: error.response?.statusCode,
      path: error.requestOptions.path,
      kind: _kindFromDio(error),
    );
  }

  factory ApiFailure.fromParsingError(Object error, {String? path}) {
    return ApiFailure(
      message: 'Could not parse response: $error',
      path: path,
      kind: ApiFailureKind.parsing,
    );
  }

  factory ApiFailure.unknown(Object error) {
    return ApiFailure(message: error.toString(), kind: ApiFailureKind.unknown);
  }

  final String message;
  final int? statusCode;
  final String? path;
  final ApiFailureKind kind;

  String get friendlyMessage {
    final messageLower = message.toLowerCase();

    // 1. Network / offline error
    if (kind == ApiFailureKind.network) {
      return 'no internet connection check your network and try again';
    }

    // 2. Duplicate registration email
    if (statusCode == 409 ||
        messageLower.contains('already exists') ||
        messageLower.contains('duplicate') ||
        messageLower.contains('already registered')) {
      return 'email address already exists, use another email to sign in';
    }

    // 3. Unregistered email (404 / resource not found) on auth endpoints
    if (kind == ApiFailureKind.notFound ||
        statusCode == 404 ||
        messageLower.contains('resource not found')) {
      final isAuthPath =
          path == null ||
          path!.contains('auth') ||
          path!.contains('login') ||
          path!.contains('password') ||
          path!.contains('register');
      if (isAuthPath) {
        return 'This email address could not be found.';
      }
    }

    return switch (kind) {
      ApiFailureKind.network =>
        'no internet connection check your network and try again',
      ApiFailureKind.timeout => 'The request timed out. Please try again.',
      ApiFailureKind.unauthorized =>
        'Your session has expired. Please log in again.',
      ApiFailureKind.forbidden => 'You don\'t have permission to do that.',
      ApiFailureKind.notFound => 'The resource was not found.',
      ApiFailureKind.server =>
        'Something went wrong on our end. Please try again later.',
      ApiFailureKind.parsing => 'Parsing error: $message',
      ApiFailureKind.unknown => 'Unknown error: $message',
      ApiFailureKind.client => message,
    };
  }

  @override
  String toString() => message;

  static String _resolveMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['errors'] is List) {
        final errorsList = data['errors'] as List;
        final details = <String>[];
        for (final err in errorsList) {
          if (err is Map) {
            final field = err['field'] ?? err['key'];
            final msg = err['message'] ?? err['value'] ?? err['error'];
            if (field != null && msg != null) {
              details.add('$field: $msg');
            } else if (msg != null) {
              details.add(msg.toString());
            } else if (field != null) {
              details.add('$field is invalid');
            }
          } else {
            details.add(err.toString());
          }
        }
        if (details.isNotEmpty) {
          return details.join('\n');
        }
      } else if (data['errors'] is Map) {
        final errorsMap = data['errors'] as Map;
        final details = <String>[];
        for (final entry in errorsMap.entries) {
          final field = entry.key;
          final msgs = entry.value;
          if (msgs is List && msgs.isNotEmpty) {
            details.add('$field: ${msgs.first}');
          } else {
            details.add('$field: $msgs');
          }
        }
        if (details.isNotEmpty) {
          return details.join('\n');
        }
      }
      if (data['message'] is String) {
        final msg = data['message'] as String;
        if (msg == 'Validation failed' || msg == 'error') {
          return '$msg. Raw data: $data';
        }
        return msg;
      }
      if (data['error'] is String) return data['error'] as String;
    }
    if (data is String) {
      return data;
    }
    if (error.response?.statusCode == 307) {
      final redirectUrl = error.response?.headers.value('location');
      return '307 Redirect! Server wants us to use this exact URL: $redirectUrl';
    }
    if (error.message case final message?) return message;
    return 'Request failed. Raw data: $data';
  }

  static ApiFailureKind _kindFromDio(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.connectionError => ApiFailureKind.network,
      DioExceptionType.badResponse => switch (error.response?.statusCode) {
        401 => ApiFailureKind.unauthorized,
        403 => ApiFailureKind.forbidden,
        404 => ApiFailureKind.notFound,
        final code? when code >= 500 => ApiFailureKind.server,
        _ => ApiFailureKind.client,
      },
      _ => ApiFailureKind.unknown,
    };
  }
}

enum ApiFailureKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  client,
  server,
  parsing,
  unknown,
}
