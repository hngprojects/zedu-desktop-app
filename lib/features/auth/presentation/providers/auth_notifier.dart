import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final SecureStorageService _storage;
  late final AuthInterceptor _interceptor;

  static const _tag = 'AuthNotifier';

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _storage = locator<SecureStorageService>();
    _interceptor = locator<AuthInterceptor>();

    _interceptor.onUnauthorized = () {
      AppLogger.w('Unauthorized — clearing session', tag: _tag);
      state = const AuthState(status: AuthStatus.unauthenticated);
    };
    _restoreSession();
    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _restoreSession() async {
    AppLogger.d('Restoring session from storage', tag: _tag);
    final token = await _storage.getAccessToken();
    if (token == null) {
      AppLogger.i('No stored token — unauthenticated', tag: _tag);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final result = await _repository.getCurrentUser();
    switch (result) {
      case Success<User>():
        AppLogger.i('Session restored — ${result.value.email}', tag: _tag);
        state = AuthState(status: AuthStatus.authenticated, user: result.value);
      case Failure<User>():
        AppLogger.w('Session restore failed — clearing token', tag: _tag);
        await _storage.clearAll();
        state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    AppLogger.d('Login attempt — $email', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.login(email: email, password: password);
    switch (result) {
      case Success<AuthSession>():
        AppLogger.i('Login succeeded — token persisted', tag: _tag);
        await _storage.saveAccessToken(result.value.accessToken);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.value.user,
        );
      case Failure<AuthSession>():
        AppLogger.w('Login rejected — ${result.error.message}', tag: _tag);
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> verifyMagicLink({required String token}) async {
    AppLogger.d('Magic link verification attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.verifyMagicLink(token: token);
    switch (result) {
      case Success<AuthSession>():
        AppLogger.i('Magic link verification succeeded — token persisted', tag: _tag);
        await _storage.saveAccessToken(result.value.accessToken);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: result.value.user,
        );
      case Failure<AuthSession>():
        AppLogger.w('Magic link verification failed — ${result.error.message}', tag: _tag);
        state = state.copyWith(
          isLoading: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  Future<void> logout() async {
    AppLogger.i('Logout — clearing session', tag: _tag);
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<String?> get accessToken => _storage.getAccessToken();

  Future<void> loginWithGoogle() async {
    AppLogger.d('Google Sign-In attempt', tag: _tag);
    state = state.copyWith(isLoading: true, clearError: true);

    HttpServer? server;
    try {
      final config = locator<AppConfig>();
      const port = 8000; // Standard redirect port for desktop

      // 1. Bind to localhost port to intercept the redirect
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      AppLogger.d('Local loopback server listening on port $port', tag: _tag);

      // 2. Launch Google Auth URL in external browser
      final redirectUri = 'http://localhost:$port';
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': config.googleClientId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': 'openid profile email',
        'access_type': 'offline',
        'prompt': 'consent',
      });

      AppLogger.d('Launching Google Auth URL in browser', tag: _tag);
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      // 3. Wait for Google's redirect containing the authorization code
      String? grantCode;
      await for (final request in server) {
        grantCode = request.uri.queryParameters['code'];

        // Return a clean success page to the user in their browser
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('''
            <!DOCTYPE html>
            <html>
            <head>
              <title>Authentication Successful</title>
              <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 50px; background-color: #f9f9f9; }
                .card { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); display: inline-block; max-width: 400px; }
                h1 { color: #4CAF50; margin-top: 0; }
                p { color: #666; font-size: 16px; }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>Sign In Successful!</h1>
                <p>You have successfully authenticated with Zedu. You can now close this tab and return to the application.</p>
              </div>
            </body>
            </html>
          ''');
        await request.response.close();
        break; 
      }

      await server.close();
      server = null;

      if (grantCode == null) {
        AppLogger.w('Google Sign-In aborted or code not found', tag: _tag);
        state = state.copyWith(isLoading: false);
        return;
      }

      AppLogger.i('Raw authorization code retrieved successfully', tag: _tag);

      // --- NEW CODE: Exchange code for ID token on the frontend ---
      AppLogger.d('Exchanging authorization code for ID token locally', tag: _tag);
      final tokenRequestUrl = Uri.parse('https://oauth2.googleapis.com/token');
      
      final httpClient = HttpClient();
      final tokenRequest = await httpClient.postUrl(tokenRequestUrl);
      tokenRequest.headers.contentType = ContentType('application', 'x-www-form-urlencoded');
      
      final body = 'client_id=${Uri.encodeComponent(config.googleClientId)}'
          '&client_secret=${Uri.encodeComponent(config.googleClientSecret)}'
          '&code=${Uri.encodeComponent(grantCode)}'
          '&grant_type=authorization_code'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}';
          
      tokenRequest.write(body);
      final tokenResponse = await tokenRequest.close();
      final responseBody = await tokenResponse.transform(utf8.decoder).join();
      
      if (tokenResponse.statusCode != 200) {
        AppLogger.e('Local token exchange failed: $responseBody', tag: _tag);
        state = state.copyWith(isLoading: false, error: 'Local token exchange failed');
        return;
      }
      
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final idToken = jsonResponse['id_token'] as String?;
      
      if (idToken == null) {
        AppLogger.e('No ID token in response', tag: _tag);
        state = state.copyWith(isLoading: false, error: 'No ID token received');
        return;
      }

      AppLogger.i('ID token retrieved successfully, sending to backend', tag: _tag);

      // --- OLD CODE (Commented Out) ---
      // // 4. Send the raw authorization code to the backend
      // final result = await _repository.signInWithGoogle(grantCode: grantCode);
      
      // We now pass the idToken instead of the raw grantCode
      final result = await _repository.signInWithGoogle(grantCode: idToken);
      switch (result) {
        case Success<AuthSession>():
          AppLogger.i('Google Sign-In succeeded — token persisted', tag: _tag);
          await _storage.saveAccessToken(result.value.accessToken);
          state = AuthState(
            status: AuthStatus.authenticated,
            user: result.value.user,
          );
        case Failure<AuthSession>():
          AppLogger.w('Google Sign-In rejected — ${result.error.message}', tag: _tag);
          state = state.copyWith(
            isLoading: false,
            error: result.error.friendlyMessage,
          );
      }
    } catch (e) {
      AppLogger.e('Google Sign-In failed', tag: _tag, error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Google Sign-In failed',
      );
    } finally {
      await server?.close();
    }
  }
}
