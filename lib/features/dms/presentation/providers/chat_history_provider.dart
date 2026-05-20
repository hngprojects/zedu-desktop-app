import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/dms/data/data.dart';

class ChatHistoryState {
  final List<dynamic> messages;
  final bool isLoading;
  final bool hasMore;
  final int page;

  ChatHistoryState({
    required this.messages,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
  });

  ChatHistoryState copyWith({
    List<dynamic>? messages,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return ChatHistoryState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class ChatHistoryNotifier extends FamilyNotifier<ChatHistoryState, String> {
  @override
  ChatHistoryState build(String arg) {
    _loadInitial();
    return ChatHistoryState(messages: [], isLoading: true);
  }

  Future<void> _loadInitial() async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      final messages = await repository.getMessages(arg, page: 1);
      
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMore: messages.length >= DmRepository.pageSize,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final repository = ref.read(dmRepositoryProvider);
      final nextPage = state.page + 1;
      final newMessages = await repository.getMessages(arg, page: nextPage);

      state = state.copyWith(
        messages: [...state.messages, ...newMessages],
        isLoading: false,
        hasMore: newMessages.length >= DmRepository.pageSize,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> sendMessage(String content, {List<dynamic>? media, List<dynamic>? mentions}) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = {
      "id": tempId,
      "content": content,
      "channel_id": arg,
      "userId": "me",
      "type": "user",
      "created_at": DateTime.now().toIso8601String(),
      "status": "sending",
    };

    state = state.copyWith(messages: [optimisticMessage, ...state.messages]);

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(arg, content, media: media, mentions: mentions);
      
      final updatedMessages = state.messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m as Map);
          newMsg.remove('status');
          return newMsg;
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);

    } catch (e) {
      final failedMessages = state.messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m as Map);
          newMsg['status'] = 'failed';
          return newMsg;
        }
        return m;
      }).toList();
      state = state.copyWith(messages: failedMessages);
    }
  }
}

final chatHistoryProvider = NotifierProviderFamily<ChatHistoryNotifier, ChatHistoryState, String>(
  ChatHistoryNotifier.new,
);
