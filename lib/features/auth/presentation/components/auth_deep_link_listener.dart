import 'dart:async';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class AuthDeepLinkListener extends ConsumerStatefulWidget {
  const AuthDeepLinkListener({super.key, required this.child, this.appLinks});

  final Widget child;
  final AppLinks? appLinks;

  @override
  ConsumerState<AuthDeepLinkListener> createState() =>
      _AuthDeepLinkListenerState();
}

class _AuthDeepLinkListenerState extends ConsumerState<AuthDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastProcessedToken;

  static const _tag = 'AuthDeepLinkListener';

  @override
  void initState() {
    super.initState();
    _appLinks = widget.appLinks ?? AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (error) {
      AppLogger.w('Failed to read initial deep link', tag: _tag);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(_handleUri(uri));
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.w('Deep link stream error: $error', tag: _tag);
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    final invitationToken = _extractInvitationToken(uri);
    if (invitationToken != null) {
      await _handleInvitationToken(invitationToken);
      return;
    }

    final token = MagicLinkDeepLinkParser.extractToken(uri);
    if (token == null || token == _lastProcessedToken) return;
    _lastProcessedToken = token;

    AppLogger.i('Processing magic link deep link', tag: _tag);
    await ref.read(authNotifierProvider.notifier).verifyMagicLink(token: token);

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated) {
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: 'Logged in successfully!',
      );
      context.go(AppRouter.home);
      return;
    }

    if (authState.error != null) {
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: authState.error!,
      );
    }
  }

  String? _extractInvitationToken(Uri uri) {
    final token =
        uri.queryParameters['invitation_token'] ?? uri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) return null;

    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    final looksLikeInvite =
        path.contains('accept_org_invitation') ||
        path.contains('/invite/general/verify') ||
        host.contains('invite');
    return looksLikeInvite ? token.trim() : null;
  }

  Future<void> _handleInvitationToken(String token) async {
    final authState = ref.read(authNotifierProvider);
    if (authState.status != AuthStatus.authenticated) {
      await locator<SecureStorageService>().writeData(
        'pending_invitation_token',
        token,
      );
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.info,
          message: 'Sign in to join the workspace.',
        );
        context.go(AppRouter.login);
      }
      return;
    }

    try {
      final api = locator<ApiBaseService>();
      await api.post<Map<String, dynamic>>(
        path: '/invite/general/verify',
        data: {'token': token},
      );
      ref.invalidate(workspaceProvider);
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.success,
          message: 'Workspace joined successfully.',
        );
        context.go(AppRouter.home);
      }
    } catch (error) {
      AppLogger.w('Invite verification failed: $error', tag: _tag);
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Could not join workspace from this invite.',
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
