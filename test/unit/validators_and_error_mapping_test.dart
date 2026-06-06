import '../helpers/helpers.dart';
import 'package:zedu/core/core.dart';

class MockBuildContext extends Mock implements BuildContext {}

void main() {
  final mockContext = MockBuildContext();

  group('Validators.validatePassword', () {
    test('should return required message if null or empty', () {
      expect(
        Validators.validatePassword(mockContext, null),
        'Password is required',
      );
      expect(
        Validators.validatePassword(mockContext, ''),
        'Password is required',
      );
    });

    test('should return length message if less than 8 characters', () {
      expect(
        Validators.validatePassword(mockContext, 'A1!a'),
        'Password must be at least 8 characters',
      );
    });

    test('should return uppercase message if missing uppercase letter', () {
      expect(
        Validators.validatePassword(mockContext, 'p@ssword1'),
        'Password must contain at least one uppercase letter',
      );
    });

    test('should return lowercase message if missing lowercase letter', () {
      expect(
        Validators.validatePassword(mockContext, 'P@SSWORD1'),
        'Password must contain at least one lowercase letter',
      );
    });

    test('should return number message if missing number', () {
      expect(
        Validators.validatePassword(mockContext, 'P@ssword'),
        'Password must contain at least one number',
      );
    });

    test('should return special character message if missing symbol', () {
      expect(
        Validators.validatePassword(mockContext, 'P1ssword'),
        'Password must contain at least one special character',
      );
    });

    test('should reject sequential ascending characters', () {
      expect(
        Validators.validatePassword(mockContext, 'P@ss1234'),
        'Password must not contain sequential or repeating characters',
      );
      expect(
        Validators.validatePassword(mockContext, 'P@1abcde'),
        'Password must not contain sequential or repeating characters',
      );
    });

    test('should reject sequential descending characters', () {
      expect(
        Validators.validatePassword(mockContext, 'P@ss4321'),
        'Password must not contain sequential or repeating characters',
      );
      expect(
        Validators.validatePassword(mockContext, 'P@1edcba'),
        'Password must not contain sequential or repeating characters',
      );
    });

    test('should reject repeating characters', () {
      expect(
        Validators.validatePassword(mockContext, 'P@ss1111'),
        'Password must not contain sequential or repeating characters',
      );
      expect(
        Validators.validatePassword(mockContext, 'P@1aaaaa'),
        'Password must not contain sequential or repeating characters',
      );
    });

    test('should accept strong mixed passwords', () {
      expect(Validators.validatePassword(mockContext, 'P@ssw0rd!'), isNull);
      expect(Validators.validatePassword(mockContext, 'Zedu#2026!'), isNull);
    });
  });

  group('ApiFailure Error Mapping', () {
    test('should map network failure kind to the exact string', () {
      const failure = ApiFailure(
        message: 'SocketException: connection failed',
        kind: ApiFailureKind.network,
      );
      expect(
        failure.friendlyMessage,
        'no internet connection check your network and try again',
      );
    });

    test(
      'should map duplicate registration errors based on statusCode 409',
      () {
        const failure = ApiFailure(
          message: 'Conflict',
          statusCode: 409,
          kind: ApiFailureKind.client,
        );
        expect(
          failure.friendlyMessage,
          'email address already exists, use another email to sign in',
        );
      },
    );

    test(
      'should map duplicate registration errors based on error message content',
      () {
        const failure1 = ApiFailure(
          message: 'email already exists',
          kind: ApiFailureKind.client,
        );
        const failure2 = ApiFailure(
          message: 'duplicate entry for key email',
          kind: ApiFailureKind.client,
        );
        expect(
          failure1.friendlyMessage,
          'email address already exists, use another email to sign in',
        );
        expect(
          failure2.friendlyMessage,
          'email address already exists, use another email to sign in',
        );
      },
    );

    test(
      'should map unregistered email 404 to correct string on auth endpoints',
      () {
        const failure1 = ApiFailure(
          message: 'Not Found',
          statusCode: 404,
          path: '/auth/login',
          kind: ApiFailureKind.notFound,
        );
        const failure2 = ApiFailure(
          message: 'resource not found',
          path: '/auth/password-reset',
          kind: ApiFailureKind.notFound,
        );
        expect(
          failure1.friendlyMessage,
          'This email address could not be found.',
        );
        expect(
          failure2.friendlyMessage,
          'This email address could not be found.',
        );
      },
    );

    test('should return default notFound message for non-auth endpoints', () {
      const failure = ApiFailure(
        message: 'Organization not found',
        statusCode: 404,
        path: '/orgs/123',
        kind: ApiFailureKind.notFound,
      );
      expect(failure.friendlyMessage, 'The resource was not found.');
    });
  });
}
