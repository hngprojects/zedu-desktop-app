import 'package:zedu/core/core.dart';

final buzzRepositoryProvider = Provider<BuzzRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  final realtimeService = ref.watch(realtimeServiceProvider);
  return BuzzRepository(apiClient, realtimeService);
});

class BuzzRepository {
  final ApiBaseService _apiClient;
  final RealtimeService _realtimeService;

  BuzzRepository(this._apiClient, this._realtimeService);

  /// Initiates a direct call/buzz with a participant.
  /// Returns call token and channel info for Agora integration.
  Future<Map<String, dynamic>> initiateDirectCall(String channelId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        path: '/buzz/direct-call',
        data: {'channel_id': channelId},
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response from buzz initiate endpoint');
      }

      final buzzId = data['buzz_id'] as String?;
      final agoraTokenData = data['agora_token'] as Map<String, dynamic>?;
      final channelName =
          agoraTokenData?['channel_name'] as String? ??
          data['channel_name'] as String?;
      final agoraToken =
          agoraTokenData?['token'] as String? ?? data['agora_token'] as String?;

      if (buzzId == null || channelName == null || agoraToken == null) {
        throw Exception('Missing required fields in buzz response');
      }

      await _realtimeService.subscribeToDmChannel('buzz_$buzzId');

      return {
        'success': true,
        'buzzId': buzzId,
        'token': agoraToken,
        'channelName': channelName,
        'appId': agoraTokenData?['app_id'] as String?,
      };
    } catch (e) {
      debugPrint('Buzz Direct Call Error: $e');
      AppLogger.e(
        'Failed to initiate direct call',
        tag: 'BuzzRepository',
        error: e,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Responds to an incoming buzz invitation (accept/reject).
  Future<bool> respondToInvitation(String buzzId, bool accept) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        path: '/buzz/$buzzId/respond',
        data: {'action': accept ? 'accept' : 'decline'},
      );
      return true;
    } catch (e) {
      AppLogger.e(
        'Failed to respond to buzz invitation',
        tag: 'BuzzRepository',
        error: e,
      );
      return false;
    }
  }

  /// Responds to a direct call (accept/reject).
  Future<bool> respondToDirectCall(String buzzId, bool accept) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        path: '/buzz/$buzzId/respond',
        data: {'action': accept ? 'accept' : 'cancel'},
      );
      return true;
    } catch (e) {
      AppLogger.e(
        'Failed to respond to direct call',
        tag: 'BuzzRepository',
        error: e,
      );
      return false;
    }
  }

  /// Leaves an active buzz/call.
  Future<bool> leaveBuzz({
    required String buzzId,
    required String participantId,
    bool buzzEnded = false,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        path: '/buzz/$buzzId/leave',
        data: {
          'buzz_id': buzzId,
          'participant_id': participantId,
          'left_at': DateTime.now().toUtc().toIso8601String(),
          'buzz_ended': buzzEnded,
        },
      );
      return true;
    } catch (e) {
      AppLogger.e('Failed to leave buzz', tag: 'BuzzRepository', error: e);
      return false;
    }
  }

  /// Toggles camera status during an active buzz.
  Future<bool> toggleCamera({
    required String buzzId,
    required String userId,
    required bool status,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        path: '/buzz/$buzzId/camera',
        data: {
          'user_id': userId,
          'status': status,
        },
      );
      return true;
    } catch (e) {
      AppLogger.e('Failed to toggle camera', tag: 'BuzzRepository', error: e);
      return false;
    }
  }
}
