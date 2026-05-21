class MagicLinkDeepLinkParser {
  const MagicLinkDeepLinkParser._();

  static String? extractToken(Uri uri) {
    if (!_isSupportedMagicLinkUri(uri)) return null;

    // Prefer explicit `token` query parameter
    final token = uri.queryParameters['token']?.trim();
    if (token != null && token.isNotEmpty) return token;

    // Some providers put data in the fragment (after #)
    if (uri.fragment.isNotEmpty) {
      try {
        final params = Uri.splitQueryString(uri.fragment);
        final fragToken = params['token']?.trim();
        if (fragToken != null && fragToken.isNotEmpty) return fragToken;
      } catch (_) {
        // ignore
      }
    }

    // Support /verify/{token} path style: look for 'verify' segment then next is token
    final segments = uri.pathSegments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    for (var i = 0; i < segments.length; i++) {
      if (segments[i].toLowerCase() == 'verify' && i + 1 < segments.length) {
        final pathToken = segments[i + 1].trim();
        if (pathToken.isNotEmpty) return pathToken;
      }
    }

    return null;
  }

  static bool _isSupportedMagicLinkUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.map((s) => s.toLowerCase()).toList();

    bool segmentsContainAuthMagic() {
      for (var i = 0; i < segments.length; i++) {
        if (segments[i] == 'auth') {
          if (i + 1 < segments.length) {
            final next = segments[i + 1];
            if (next.contains('magic')) return true;
          }
          if (i + 2 < segments.length) {
            final next2 = segments[i + 2];
            if (next2.contains('magic')) return true;
          }
        }
      }
      return false;
    }

    bool anySegmentContainsMagic() {
      for (final s in segments) {
        if (s.contains('magic')) return true;
      }
      return false;
    }

    if (scheme == 'zedu' && (host == 'auth' || host.isEmpty)) {
      // For custom scheme the host is usually 'auth', but some URI forms
      // may omit an authority component while still carrying the path.
      return anySegmentContainsMagic();
    }

    if (scheme == 'https' || scheme == 'http') {
      // Accept wrapped viewers (e.g., temp-mail) where '/auth/..' may appear later in path
      return segmentsContainAuthMagic();
    }

    return false;
  }
}
