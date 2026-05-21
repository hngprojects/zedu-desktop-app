import 'package:flutter_riverpod/flutter_riverpod.dart';

final buzzRepositoryProvider = Provider<BuzzRepository>((ref) {
  return BuzzRepository();
});

class BuzzRepository {
  Future<Map<String, dynamic>> initiateDirectCall(String participantId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'success': true,
      'buzzId': 'mock-buzz-id-${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock-agora-token',
      'channelName': 'mock-channel-$participantId',
    };
  }

  /// POST /buzz/invitation/respond
  Future<bool> respondToInvitation(String buzzId, bool accept) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// POST /buzz/{buzzId}/respond
  Future<bool> respondToDirectCall(String buzzId, bool accept) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
