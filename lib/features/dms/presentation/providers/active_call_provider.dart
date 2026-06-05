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
  final String? buzzCode;
  final bool isFullPage;
  final DateTime? lastCallAt;
  final String? invitationId;
  final bool isOrgBuzz;
  final bool isRemoteJoined; // Tracks if the remote user has joined the meeting

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
    this.buzzCode,
    this.invitationId,
    this.isOrgBuzz = false,
    this.isRemoteJoined = false,
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
    String? buzzCode,
    String? invitationId,
    bool? isOrgBuzz,
    bool? isRemoteJoined,
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
      buzzCode: buzzCode ?? this.buzzCode,
      invitationId: invitationId ?? this.invitationId,
      isOrgBuzz: isOrgBuzz ?? this.isOrgBuzz,
      isRemoteJoined: isRemoteJoined ?? this.isRemoteJoined,
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
        buzzCode: res['buzzCode'] as String?,
        token: token,
        appId: appId,
        channelName: channelName,
      );
      notifyListeners();

      if (buzzId != null && token != null) {
        _state = _state.copyWith(
          status: CallStatus.active,
          isRemoteJoined: false, // Caller enters, waiting for remote
        );
        notifyListeners();
        
        _ref.read(buzzLogProvider.notifier).addLog(BuzzLogEntry(
          id: buzzId,
          callerName: remoteUserName,
          timestamp: DateTime.now(),
          isMissed: false,
          isIncoming: false,
        ));
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

      final res = await _ref
          .read(buzzRepositoryProvider)
          .joinBuzz(_state.buzzId!);
      if (res['success'] == true) {
        _state = _state.copyWith(
          status: CallStatus.active,
          token: res['token'] as String?,
          appId: res['appId'] as String?,
          channelName: res['channelName'] as String?,
        );
        notifyListeners();
        
        _ref.read(buzzLogProvider.notifier).addLog(BuzzLogEntry(
          id: _state.buzzId ?? DateTime.now().toString(),
          callerName: _state.remoteUserName ?? 'Unknown',
          timestamp: DateTime.now(),
          isMissed: false,
          isIncoming: true,
        ));
      } else {
        await leaveCall();
      }
    }
  }

  Future<void> declineCall() async {
    if (_state.status != CallStatus.incoming) return;

    if (_state.buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(_state.buzzId!, false);
          
      _ref.read(buzzLogProvider.notifier).addLog(BuzzLogEntry(
        id: _state.buzzId!,
        callerName: _state.remoteUserName ?? 'Unknown',
        timestamp: DateTime.now(),
        isMissed: true,
        isIncoming: true,
      ));
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
        await _ref
            .read(buzzRepositoryProvider)
            .leaveBuzz(
              buzzId: buzzId,
              buzzCode: _state.buzzCode ?? '',
              participantId: user.id.toString(),
              buzzEnded: false,
            );
      }
    }
    _state = ActiveCallState(lastCallAt: _state.lastCallAt);
    notifyListeners();
  }

  void handleRemoteJoined() {
    _state = _state.copyWith(isRemoteJoined: true);
    notifyListeners();
  }

  void handleRemoteDecline() {
    // Show a toast or notification if we were waiting
    if (_state.status == CallStatus.active && !_state.isRemoteJoined) {
      // Remote declined while we were waiting in the room
      _ref.read(buzzLogProvider.notifier).addLog(BuzzLogEntry(
        id: _state.buzzId ?? DateTime.now().toString(),
        callerName: _state.remoteUserName ?? 'Unknown',
        timestamp: DateTime.now(),
        isMissed: false,
        isIncoming: false,
      ));
    }
    leaveCall();
  }

  /// Activates an org buzz session after createOrgBuzz() or joinBuzzByCode().
  /// Called by OrgBuzzNotifier once Agora token data is available.
  void activateOrgBuzz({
    required String buzzId,
    required String channelId,
    required String token,
    required String appId,
    required String channelName,
    String? buzzCode,
    String? hostName,
  }) {
    _state = ActiveCallState(
      status: CallStatus.active,
      buzzId: buzzId,
      channelId: channelId,
      token: token,
      appId: appId,
      channelName: channelName,
      buzzCode: buzzCode,
      remoteUserName: hostName,
      isOrgBuzz: true,
      isFullPage: true,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Called by NotificationService when a buzz_invitation Centrifugo event arrives.
  void receiveOrgBuzzInvitation({
    required String invitationId,
    required String buzzId,
    required String inviterName,
    required String channelId,
  }) {
    if (_state.status != CallStatus.none) return;
    _state = ActiveCallState(
      status: CallStatus.incoming,
      buzzId: buzzId,
      channelId: channelId,
      remoteUserName: inviterName,
      invitationId: invitationId,
      isOrgBuzz: true,
      isFullPage: false,
      lastCallAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> declineOrgBuzzInvitation() async {
    final invId = _state.invitationId;
    final buzzId = _state.buzzId;
    if (invId != null) {
      await _ref
          .read(orgBuzzRepositoryProvider)
          .respondToOrgBuzzInvitation(invId, false);
    } else if (buzzId != null) {
      await _ref
          .read(buzzRepositoryProvider)
          .respondToInvitation(buzzId, false);
    }
    _ref.read(buzzLogProvider.notifier).addLog(BuzzLogEntry(
      id: buzzId ?? DateTime.now().toString(),
      callerName: _state.remoteUserName ?? 'Unknown',
      timestamp: DateTime.now(),
      isMissed: true,
      isIncoming: true,
    ));
    _state = ActiveCallState(lastCallAt: _state.lastCallAt);
    notifyListeners();
  }
}

final activeCallProvider = ChangeNotifierProvider<ActiveCallNotifier>((ref) {
  return ActiveCallNotifier(ref);
});
