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
    // 1. Process Magic Link
    final magicToken = MagicLinkDeepLinkParser.extractToken(uri);
    if (magicToken != null) {
      if (magicToken == _lastProcessedToken) return;
      _lastProcessedToken = magicToken;
      await _handleMagicLink(magicToken);
      return;
    }

    // 2. Process Invitation Link
    final inviteToken = InvitationDeepLinkParser.extractToken(uri);
    if (inviteToken != null) {
      if (inviteToken == _lastProcessedToken) return;
      _lastProcessedToken = inviteToken;
      await _handleInvitationLink(inviteToken);
      return;
    }
  }

  Future<void> _handleMagicLink(String token) async {
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

  Future<void> _handleInvitationLink(String token) async {
    final authState = ref.read(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated) {
      await _acceptInvite(token);
    } else {
      ref.read(pendingInviteTokenProvider.notifier).state = token;
      AppToastService.show(
        context,
        type: AppToastType.info,
        message: 'Please log in or sign up to accept the invitation.',
      );
      context.go(AppRouter.login);
    }
  }

  Future<void> _acceptInvite(String token) async {
    AppLogger.i('Accepting invitation link', tag: _tag);
    ref.read(pendingInviteTokenProvider.notifier).state = null;

    await ref
        .read(userProfileNotifierProvider.notifier)
        .acceptInvitation(token);

    if (!mounted) return;

    final profileState = ref.read(userProfileNotifierProvider);
    if (profileState.error != null) {
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: profileState.error!,
      );
    } else if (profileState.successMessage != null) {
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: profileState.successMessage!,
      );
      context.go(AppRouter.home);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        final inviteToken = ref.read(pendingInviteTokenProvider);
        if (inviteToken != null) {
          unawaited(_acceptInvite(inviteToken));
        }
      }
    });

    return widget.child;
  }
}
