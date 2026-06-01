import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

enum ActiveChatType {
  channel,
  groupDm,
  newGroupChat,
  directMessage,
  channelDirectory,
  none,
}

class ActiveChatState {
  final ActiveChatType type;
  final String? id;

  const ActiveChatState({required this.type, this.id});

  static const generalChannel = ActiveChatState(
    type: ActiveChatType.channel,
    id: 'general',
  );
  static const newGroupChat = ActiveChatState(
    type: ActiveChatType.newGroupChat,
  );
  static const channelDirectory = ActiveChatState(
    type: ActiveChatType.channelDirectory,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveChatState &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

class ActiveChatNotifier extends Notifier<ActiveChatState> {
  String? _lastOrgId;
  ActiveChatState? _currentState;

  @override
  ActiveChatState build() {
    final orgId = ref.watch(currentOrgIdProvider);

    AppLogger.i(
      'ActiveChatNotifier.build: orgId=$orgId, _lastOrgId=$_lastOrgId, _currentState=${_currentState?.id}',
    );

    if (_lastOrgId != null &&
        _lastOrgId!.isNotEmpty &&
        orgId.isNotEmpty &&
        _lastOrgId != orgId) {
      AppLogger.i(
        'ActiveChatNotifier.build: Organization changed from $_lastOrgId to $orgId. Resetting active chat to general.',
      );
      _lastOrgId = orgId;
      _currentState = ActiveChatState.generalChannel;
      return ActiveChatState.generalChannel;
    }

    if (orgId.isNotEmpty) {
      _lastOrgId = orgId;
    }
    final result = _currentState ?? ActiveChatState.generalChannel;

    AppLogger.i('ActiveChatNotifier.build: returning active chat ${result.id}');
    return result;
  }

  void selectChannel(String channelId) {
    AppLogger.i(
      'ActiveChatNotifier.selectChannel: selecting channel $channelId',
    );
    state = ActiveChatState(type: ActiveChatType.channel, id: channelId);
    _currentState = state;
  }

  void selectGroupDm(String groupDmId) {
    state = ActiveChatState(type: ActiveChatType.groupDm, id: groupDmId);
    _currentState = state;
  }

  void selectDirectMessage(String userId) {
    state = ActiveChatState(type: ActiveChatType.directMessage, id: userId);
    _currentState = state;
  }

  void selectChannelDirectory() {
    state = ActiveChatState.channelDirectory;
    _currentState = state;
  }

  void selectNewGroupChat() {
    state = ActiveChatState.newGroupChat;
    _currentState = state;
  }
}

final activeChatProvider =
    NotifierProvider<ActiveChatNotifier, ActiveChatState>(
      ActiveChatNotifier.new,
    );
