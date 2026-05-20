import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  final String arg;
  final Ref ref;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool hasMore = true;
  int page = 1;

  ChatHistoryNotifier(this.arg, this.ref) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final repository = ref.read(dmRepositoryProvider);
      messages = await repository.getMessages(arg, page: 1);
      hasMore = messages.length >= DmRepository.pageSize;
      page = 1;
    } catch (e) {
      // Ignore
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      final nextPage = page + 1;
      final newMessages = await repository.getMessages(arg, page: nextPage);

      messages = [...messages, ...newMessages];
      hasMore = newMessages.length >= DmRepository.pageSize;
      page = nextPage;
    } catch (e) {
      // Ignore
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
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

    messages = [optimisticMessage, ...messages];
    notifyListeners();

    try {
      final repository = ref.read(dmRepositoryProvider);
      await repository.sendMessage(
        arg,
        content,
        media: media,
        mentions: mentions,
      );

      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg.remove('status');
          return newMsg;
        }
        return m;
      }).toList();
    } catch (e) {
      messages = messages.map((m) {
        if (m['id'] == tempId) {
          final newMsg = Map<String, dynamic>.from(m);
          newMsg['status'] = 'failed';
          return newMsg;
        }
        return m;
      }).toList();
    } finally {
      notifyListeners();
    }
  }
}

final chatHistoryProvider =
    ChangeNotifierProvider.family<ChatHistoryNotifier, String>(
  (ref, arg) => ChatHistoryNotifier(arg, ref),
);
