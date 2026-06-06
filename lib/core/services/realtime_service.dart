import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:zedu/core/core.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class RealtimeService {
  RealtimeService(Ref ref);

  centrifuge.Client? _client;
  Completer<void>? _connectCompleter;
  centrifuge.Subscription? _orgSubscription;
  final Map<String, centrifuge.Subscription?> _dmSubscriptions = {};

  final _profileUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _dmMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get profileUpdateStream =>
      _profileUpdateController.stream;

  /// Stream of incoming DM messages {channelId, message}
  Stream<Map<String, dynamic>> get dmMessageStream =>
      _dmMessageController.stream;

  Future<void> connect() async {
    if (_client != null) return;

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      await _connectCompleter!.future;
      return;
    }

    final completer = Completer<void>();
    _connectCompleter = completer;
    try {
      final api = locator<ApiBaseService>();
      final response = await api.get<Map<String, dynamic>>(
        path: '/centrifugo/connection',
      );
      final token = response.data['data'] is Map<String, dynamic>
          ? (response.data['data'] as Map<String, dynamic>)['token'] as String?
          : response.data['token'] as String?;
      if (token == null || token.isEmpty) {
        AppLogger.w(
          'Centrifugo: no connection token received',
          tag: 'RealtimeService',
        );
        _connectCompleter = null;
        completer.complete();
        return;
      }

      final config = locator<AppConfig>();
      final baseUri = Uri.tryParse(config.apiBaseUrl);
      final host = baseUri?.host ?? 'api.example.com';
      final websocketScheme = baseUri?.scheme == 'https' ? 'wss' : 'ws';
      final defaultUrl =
          '$websocketScheme://$host/centrifugo/connection/websocket';

      final url = dotenv.env['CENTRIFUGO_WEBSOCKET_URL'] ?? defaultUrl;
      AppLogger.i('Centrifugo connecting to $url', tag: 'RealtimeService');

      _client = centrifuge.createClient(url);
      _client?.setToken(token);

      _client?.connected.listen((event) {
        AppLogger.i('Centrifugo connected', tag: 'RealtimeService');
      });

      _client?.disconnected.listen((event) {
        AppLogger.w('Centrifugo disconnected', tag: 'RealtimeService');
      });

      await _client?.connect();
      completer.complete();
    } catch (e) {
      _connectCompleter = null;
      _client = null;
      completer.completeError(e);
      AppLogger.e('Centrifugo connect failed: $e', tag: 'RealtimeService');
    }
  }

  /// Subscribe to a DM channel for real-time message updates.
  /// Messages are streamed via [dmMessageStream].
  Future<void> subscribeToDmChannel(String channelId) async {
    if (_client == null) await connect();

    // Don't re-subscribe if already subscribed
    if (_dmSubscriptions.containsKey(channelId)) {
      final existing = _dmSubscriptions[channelId];
      if (existing != null) {
        AppLogger.d(
          'Already subscribed to DM channel: $channelId',
          tag: 'RealtimeService',
        );
        return;
      }
    }

    final api = locator<ApiBaseService>();
    try {
      // Get subscription token from backend
      final response = await api.post<Map<String, dynamic>>(
        path: '/centrifugo/subscription',
        data: {'channel': channelId},
      );

      final subToken = response.data['data'] is Map<String, dynamic>
          ? (response.data['data'] as Map<String, dynamic>)['token'] as String?
          : response.data['token'] as String?;
      if (subToken == null) {
        throw Exception('No subscription token received');
      }

      final sub =
          _client?.getSubscription(channelId) ??
          _client?.newSubscription(
            channelId,
            centrifuge.SubscriptionConfig(token: subToken),
          );

      // Listen for incoming messages
      sub?.publication.listen((event) {
        try {
          final message =
              jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
          AppLogger.i('New DM received on $channelId', tag: 'RealtimeService');
          // Emit message with channel context
          _dmMessageController.add({
            'channelId': channelId,
            'message': message,
          });
        } catch (e) {
          AppLogger.e(
            'Error parsing DM message',
            tag: 'RealtimeService',
            error: e,
          );
        }
      });

      sub?.error.listen((event) {
        AppLogger.w(
          'DM subscription error: ${event.error}',
          tag: 'RealtimeService',
        );
      });

      // Subscribe to channel
      await sub?.subscribe();
      _dmSubscriptions[channelId] = sub;
      AppLogger.i(
        'Subscribed to DM channel: $channelId',
        tag: 'RealtimeService',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to subscribe to DM channel: $channelId',
        tag: 'RealtimeService',
        error: e,
      );
    }
  }

  /// Unsubscribe from a DM channel.
  Future<void> unsubscribeFromDmChannel(String channelId) async {
    try {
      final sub = _dmSubscriptions[channelId];
      if (sub != null) {
        await sub.unsubscribe();
        _dmSubscriptions.remove(channelId);
        AppLogger.i(
          'Unsubscribed from DM channel: $channelId',
          tag: 'RealtimeService',
        );
      }
    } catch (e) {
      AppLogger.e(
        'Error unsubscribing from DM channel',
        tag: 'RealtimeService',
        error: e,
      );
    }
  }

  Future<void> subscribeToOrg(String orgId) async {
    if (_client == null) await connect();

    final channelName = orgId;

    if (_orgSubscription != null) {
      if (_orgSubscription!.channel == channelName) return;
      await _orgSubscription!.unsubscribe();
    }

    try {
      final api = locator<ApiBaseService>();
      final response = await api.post<Map<String, dynamic>>(
        path: '/centrifugo/subscription',
        data: {'channel': channelName},
      );
      final subToken = response.data['data'] is Map<String, dynamic>
          ? (response.data['data'] as Map<String, dynamic>)['token'] as String?
          : response.data['token'] as String?;
      if (subToken == null || subToken.isEmpty) {
        throw Exception('No org subscription token received');
      }

      _orgSubscription =
          _client?.getSubscription(channelName) ??
          _client?.newSubscription(
            channelName,
            centrifuge.SubscriptionConfig(token: subToken),
          );
    } catch (e) {
      AppLogger.e(
        'Failed to create org subscription',
        tag: 'RealtimeService',
        error: e,
      );
      return;
    }

    _orgSubscription?.publication.listen((event) {
      try {
        final data = jsonDecode(utf8.decode(event.data));
        final eventName = data['event'];
        if (eventName == 'USER_PROFILE_UPDATED') {
          _profileUpdateController.add(data['payload'] as Map<String, dynamic>);
        }
      } catch (e) {
        AppLogger.e(
          'Error parsing realtime event',
          tag: 'RealtimeService',
          error: e,
        );
      }
    });

    _orgSubscription?.error.listen((event) {
      AppLogger.e('Subscription error: ${event.error}', tag: 'RealtimeService');
    });

    await _orgSubscription?.subscribe();
  }

  void dispose() {
    _orgSubscription?.unsubscribe();
    for (final subscription in _dmSubscriptions.values) {
      subscription?.unsubscribe();
    }
    _client?.disconnect();
    _profileUpdateController.close();
    _dmMessageController.close();
  }
}
