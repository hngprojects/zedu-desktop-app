import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum CallStatus { none, calling, incoming, active }

class ActiveCallState {
  final CallStatus status;
  final String? buzzId;
  final String? channelId;
  final String? remoteUserName;
  final String? remoteUserId;
  final String? remoteAvatarUrl;
  final String? token;
  final String? appId;
  final String? channelName;
  final bool isFullPage;
  final DateTime? lastCallAt;

  const ActiveCallState({
    this.status = CallStatus.none,
    this.buzzId,
    this.channelId,
    this.remoteUserName,
    this.remoteUserId,
    this.remoteAvatarUrl,
    this.token,
    this.appId,
    this.channelName,
    this.isFullPage = false,
    this.lastCallAt,
  });

  ActiveCallState copyWith({
    CallStatus? status,
    String? buzzId,
    String? channelId,
    String? remoteUserName,
    String? remoteUserId,
    String? remoteAvatarUrl,
    String? token,
    String? appId,
    String? channelName,
    bool? isFullPage,
    DateTime? lastCallAt,
  }) {
    return ActiveCallState(
      status: status ?? this.status,
      buzzId: buzzId ?? this.buzzId,
      channelId: channelId ?? this.channelId,
      remoteUserName: remoteUserName ?? this.remoteUserName,
      remoteUserId: remoteUserId ?? this.remoteUserId,
      remoteAvatarUrl: remoteAvatarUrl ?? this.remoteAvatarUrl,
      token: token ?? this.token,
      appId: appId ?? this.appId,
      channelName: channelName ?? this.channelName,
      isFullPage: isFullPage ?? this.isFullPage,
      lastCallAt: lastCallAt ?? this.lastCallAt,
    );
  }
}

class ActiveCallNotifier extends ChangeNotifier {
  final Ref _ref;
  ActiveCallState _state = const ActiveCallState();

  ActiveCallNotifier(this._ref);

  ActiveCallState get state => _state;

  void setFullPage(bool isFullPage) {
    _state = _state.copyWith(isFullPage: isFullPage);
    notifyListeners();
  }

  Future<void> initiateCall({
    required String remoteUserId,
    required String remoteUserName,
    required String channelId,
    String? remoteAvatarUrl,
  }) async {
    _state = ActiveCallState(
      status: CallStatus.calling,
      channelId: channelId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      remoteAvatarUrl: remoteAvatarUrl,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final repo = _ref.read(buzzRepositoryProvider);
      final res = await repo.initiateDirectCall(channelId);
      
      if (res['success'] == false) {
        await leaveCall();
        return;
      }

      final buzzId = res['buzzId'] as String?;
      final token = res['token'] as String?;
      final appId = res['appId'] as String?;
      final channelName = res['channelName'] as String?;

      _state = _state.copyWith(
        buzzId: buzzId,
        token: token,
        appId: appId,
        channelName: channelName,
      );
      notifyListeners();

      if (buzzId != null && token != null) {
        _state = _state.copyWith(status: CallStatus.active);
        notifyListeners();
      } else {
        await leaveCall();
      }
    } catch (e) {
      await leaveCall();
    }
  }

  void receiveIncomingCall({
    required String buzzId,
    required String remoteUserId,
    required String remoteUserName,
    required String channelId,
    String? remoteAvatarUrl,
  }) {
    if (_state.status != CallStatus.none) {
      _ref.read(buzzRepositoryProvider).respondToInvitation(buzzId, false);
      return;
    }

    _state = ActiveCallState(
      status: CallStatus.incoming,
      buzzId: buzzId,
      channelId: channelId,
      remoteUserId: remoteUserId,
      remoteUserName: remoteUserName,
      remoteAvatarUrl: remoteAvatarUrl,
      isFullPage: false,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (_state.status != CallStatus.incoming) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(_state.buzzId!, true);
      _state = _state.copyWith(status: CallStatus.active);
      notifyListeners();
    }
  }

  Future<void> declineCall() async {
    if (_state.status != CallStatus.incoming) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(_state.buzzId!, false);
    }
    await leaveCall();
  }

  Future<void> cancelCall() async {
    if (_state.status != CallStatus.calling) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToDirectCall(_state.buzzId!, false);
    }
    await leaveCall();
  }

  Future<void> leaveCall() async {
    final buzzId = _state.buzzId;
    if (buzzId != null && _state.status == CallStatus.active) {
      final user = _ref.read(authNotifierProvider).user;
      if (user != null) {
        await _ref.read(buzzRepositoryProvider).leaveBuzz(
              buzzId: buzzId,
              participantId: user.id.toString(),
              buzzEnded: false,
            );
      }
    }
    _state = ActiveCallState(lastCallAt: _state.lastCallAt);
    notifyListeners();
  }
}

final activeCallProvider = ChangeNotifierProvider<ActiveCallNotifier>((ref) {
  return ActiveCallNotifier(ref);
});
