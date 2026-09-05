class InvitationDeepLinkParser {
  const InvitationDeepLinkParser._();

  static String? extractToken(Uri uri) {
    if (!_isSupportedInvitationUri(uri)) return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static bool _isSupportedInvitationUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = _normalizePath(uri.path);

    if (scheme == 'zedu' && (host == 'invite' || path.startsWith('/invite'))) {
      return true;
    }

    if ((scheme == 'https' || scheme == 'http') &&
        (path.contains('/invite/accept') ||
            path.contains('/accept-invite') ||
            path.contains('/invite'))) {
      return true;
    }

    return false;
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '/';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
