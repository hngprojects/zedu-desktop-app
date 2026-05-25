import 'dart:async';
import 'dart:convert';
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
  centrifuge.Subscription? _orgSubscription;
  final _profileUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get profileUpdateStream => _profileUpdateController.stream;

  Future<void> connect() async {
    if (_client != null) return; // already connected or connecting
    
    final token = await locator<SecureStorageService>().getAccessToken();
    if (token == null) return;
    
    // Adjusting to standard wss url for Centrifugo
    final url = 'wss://api.zedu.chat/centrifugo/connection/websocket';
    
    _client = centrifuge.createClient(url);
    _client?.setToken(token); // Set token

    _client?.connected.listen((event) {
      AppLogger.i('Centrifugo connected', tag: 'RealtimeService');
    });

    _client?.disconnected.listen((event) {
      AppLogger.w('Centrifugo disconnected', tag: 'RealtimeService');
    });

    await _client?.connect();
  }

  Future<void> subscribeToOrg(String orgId) async {
    if (_client == null) await connect();
    
    final channelName = 'org-$orgId';
    
    if (_orgSubscription != null) {
      if (_orgSubscription!.channel == channelName) return;
      await _orgSubscription!.unsubscribe();
    }
    
    _orgSubscription = _client?.getSubscription(channelName);
    
    _orgSubscription?.publication.listen((event) {
      try {
        final data = jsonDecode(utf8.decode(event.data));
        final eventName = data['event'];
        if (eventName == 'USER_PROFILE_UPDATED') {
           _profileUpdateController.add(data['payload'] as Map<String, dynamic>);
        }
      } catch (e) {
        AppLogger.e('Error parsing realtime event', tag: 'RealtimeService', error: e);
      }
    });

    _orgSubscription?.error.listen((event) {
      AppLogger.e('Subscription error: ${event.error}', tag: 'RealtimeService');
    });

    await _orgSubscription?.subscribe();
  }
  
  void dispose() {
    _orgSubscription?.unsubscribe();
    _client?.disconnect();
    _profileUpdateController.close();
  }
}
