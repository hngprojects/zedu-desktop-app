import 'package:zedu/core/core.dart';

class ChatWebsocketMessage {
  final String id;
  final String userId;
  final String groupDmId;
  final String text;
  final String authorName;
  final DateTime timestamp;

  const ChatWebsocketMessage({
    required this.id,
    required this.userId,
    required this.groupDmId,
    required this.text,
    required this.authorName,
    required this.timestamp,
  });
}

class ChatWebsocketService {
  final _messageController = StreamController<ChatWebsocketMessage>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _connectCommandId = 1;

  final Set<String> _activeChannelIds = {};
  final Set<String> _subscribedChannels = {};
  Timer? _reconnectTimer;
  Timer? _mockTimer;

  Stream<ChatWebsocketMessage> get messageStream => _messageController.stream;

  void connect(List<String> channelIds) {
    final validChannelIds = channelIds
        .where((id) => id.trim().isNotEmpty)
        .toList();
    if (validChannelIds.isEmpty) return;
    _activeChannelIds.addAll(validChannelIds);
    _connectSocket(validChannelIds);
  }

  void disconnect() {
    _mockTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _isConnecting = false;
    _subscribedChannels.clear();
    debugPrint('WebSocket Disconnected');
  }

  Future<void> _connectSocket(List<String> channelIds) async {
    final config = locator<AppConfig>();
    if (config.usesMockData) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        debugPrint('Mock WebSocket Connected');
        _startMockingMessages(channelIds);
      });
      return;
    }

    if (_isConnected || _isConnecting) {
      _subscribeToActiveChannels();
      return;
    }

    _isConnecting = true;
    final wsUrl = config.websocketUrl;
    final token = await locator<SecureStorageService>().getAccessToken();

    if (token == null) {
      _isConnecting = false;
      debugPrint('WebSocket: No access token available. Cannot connect.');
      return;
    }

    try {
      debugPrint('WebSocket: Connecting to $wsUrl');
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.ready
          .then((_) {
            debugPrint('WebSocket: Connection handshaked successfully.');
          })
          .catchError((Object error) {
            debugPrint('WebSocket: Connection ready error: $error');
          });

      _isConnecting = false;
      _isConnected = true;
      _subscribedChannels.clear();

      _sendConnectCommand(token);

      _socketSubscription = _channel!.stream.listen(
        (event) {
          _handleIncomingMessage(event);
        },
        onError: (Object error) {
          debugPrint('WebSocket: Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket: Connection closed by server');
          _handleDisconnect();
        },
      );

      _subscribeToActiveChannels();
    } catch (e) {
      _isConnecting = false;
      debugPrint('WebSocket: Connection exception: $e');
      _handleDisconnect();
    }
  }

  void _sendConnectCommand(String token) {
    final cmd = {
      "id": _connectCommandId++,
      "connect": {"token": token},
    };
    _sendJson(cmd);
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_channel != null && _isConnected) {
      final jsonStr = jsonEncode(data);
      debugPrint('WebSocket sending: $jsonStr');
      _channel!.sink.add(jsonStr);
    }
  }

  void _subscribeToActiveChannels() {
    if (!_isConnected) return;
    for (final channelId in _activeChannelIds) {
      if (channelId.trim().isEmpty) continue;
      if (!_subscribedChannels.contains(channelId)) {
        debugPrint('WebSocket subscribing to channel: $channelId');
        final cmd = {
          "id": _connectCommandId++,
          "subscribe": {"channel": channelId},
        };
        _sendJson(cmd);
        _subscribedChannels.add(channelId);
      }
    }
  }

  void _handleIncomingMessage(dynamic event) {
    debugPrint('WebSocket received: $event');
    if (event == null) return;

    final rawText = event.toString().trim();
    if (rawText.isEmpty) return;

    final lines = rawText.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine == '{}') {
        _channel?.sink.add('{}');
        continue;
      }

      try {
        final decoded = jsonDecode(trimmedLine);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('push')) {
            final push = decoded['push'] as Map<String, dynamic>?;
            if (push != null && push.containsKey('pub')) {
              final pub = push['pub'] as Map<String, dynamic>?;
              final channel = push['channel'] as String? ?? '';
              final data = pub?['data'] as Map<String, dynamic>?;
              if (data != null) {
                final id =
                    data['id'] as String? ??
                    'ws-${DateTime.now().millisecondsSinceEpoch}';
                final userId =
                    data['sender_id'] as String? ??
                    data['user_id'] as String? ??
                    data['userId'] as String? ??
                    '';
                final text =
                    data['content'] as String? ?? data['text'] as String? ?? '';
                final authorName =
                    data['sender_name'] as String? ??
                    data['username'] as String? ??
                    'Someone';
                final createdAtStr =
                    data['created_at'] as String? ??
                    data['timestamp'] as String? ??
                    '';
                final timestamp =
                    (DateTime.tryParse(createdAtStr) ?? DateTime.now())
                        .toLocal();

                _messageController.add(
                  ChatWebsocketMessage(
                    id: id,
                    userId: userId,
                    groupDmId: channel,
                    text: text,
                    authorName: authorName,
                    timestamp: timestamp,
                  ),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('WebSocket error parsing line: $trimmedLine, error: $e');
      }
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _subscribedChannels.clear();
    _socketSubscription?.cancel();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('WebSocket: Reconnecting...');
      _connectSocket(List<String>.from(_activeChannelIds));
    });
  }

  void _startMockingMessages(List<String> activeGroupDmIds) {
    if (activeGroupDmIds.isEmpty) return;

    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      final groupId = activeGroupDmIds[timer.tick % activeGroupDmIds.length];
      _messageController.add(
        ChatWebsocketMessage(
          id: 'mock-${timer.tick}',
          userId: 'mock-user',
          groupDmId: groupId,
          text:
              'This is a simulated real-time incoming message (#${timer.tick})',
          authorName: 'Mock Member',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void sendMessage(String groupDmId, String text) {}

  void dispose() {
    _reconnectTimer?.cancel();
    _mockTimer?.cancel();
    disconnect();
    _messageController.close();
  }
}

final chatWebsocketProvider = Provider<ChatWebsocketService>((ref) {
  final service = ChatWebsocketService();
  ref.onDispose(service.dispose);
  return service;
});
