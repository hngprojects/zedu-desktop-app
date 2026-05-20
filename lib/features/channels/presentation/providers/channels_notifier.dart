import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelsNotifier extends Notifier<ChannelsState> {
  late final ChannelsRepository _repository;
  Timer? _pollingTimer;

  static const _pollingInterval = Duration(seconds: 5);

  @override
  ChannelsState build() {
    _repository = ref.read(channelsRepositoryProvider);
    ref.onDispose(_stopPolling);

    return const ChannelsState(
      selectedChannelId: ChannelsDevDefaults.mockChannelId,
    );
  }

  Future<void> openChannel(String channelId) async {
    final cleanId = channelId.trim();
    if (cleanId.isEmpty) {
      _stopPolling();
      state = state.copyWith(
        clearChannel: true,
        clearMessages: true,
        isLoading: false,
        isRefreshing: false,
        isPolling: false,
        error: 'Select a channel',
      );
      return;
    }

    final changedChannel = state.selectedChannelId != cleanId;
    state = state.copyWith(
      selectedChannelId: cleanId,
      isLoading: true,
      isRefreshing: false,
      clearError: true,
      messages: changedChannel ? const [] : state.messages,
    );

    await _fetchMessages(page: 1, limit: 20, replace: true);
    _startPolling();
  }

  Future<void> refreshCurrentChannel() async {
    if (!state.hasSelectedChannel) {
      state = state.copyWith(error: 'Select a channel');
      return;
    }

    state = state.copyWith(isRefreshing: true, clearError: true);
    await _fetchMessages(page: 1, limit: 20, replace: true);
  }

  Future<void> sendMessage({
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  }) async {
    final channelId = state.selectedChannelId?.trim() ?? '';
    if (channelId.isEmpty) {
      state = state.copyWith(error: 'Select a channel');
      return;
    }

    final plain = contentHtml.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (plain.isEmpty) return;

    state = state.copyWith(isSending: true, clearError: true);

    final result = await _repository.sendChannelMessage(
      channelId: channelId,
      contentHtml: contentHtml,
      threadId: threadId,
      media: media,
      mentions: mentions,
    );

    switch (result) {
      case Success<ChannelMessage>():
        final deduped = _mergeByThreadId([result.value, ...state.messages]);
        state = state.copyWith(messages: deduped, isSending: false);
      case Failure<ChannelMessage>():
        state = state.copyWith(
          isSending: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(_pollLatest());
    });
    state = state.copyWith(isPolling: true);
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isPolling: false);
  }

  Future<void> _pollLatest() async {
    if (!state.hasSelectedChannel || state.isSending || state.isLoading) return;
    await _fetchMessages(page: 1, limit: 20, replace: false);
  }

  Future<void> _fetchMessages({
    required int page,
    required int limit,
    required bool replace,
  }) async {
    final channelId = state.selectedChannelId?.trim() ?? '';
    if (channelId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Select a channel',
      );
      return;
    }

    final result = await _repository.fetchChannelMessages(
      channelId: channelId,
      page: page,
      limit: limit,
    );

    switch (result) {
      case Success<PaginatedChannelMessages>():
        final incoming = result.value.messages;
        final merged = replace
            ? _mergeByThreadId(incoming)
            : _mergeByThreadId([...incoming, ...state.messages]);

        state = state.copyWith(
          messages: merged,
          pagination: result.value.pagination,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
        );
      case Failure<PaginatedChannelMessages>():
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: result.error.friendlyMessage,
        );
    }
  }

  List<ChannelMessage> _mergeByThreadId(List<ChannelMessage> input) {
    final byId = <String, ChannelMessage>{};
    for (final message in input) {
      byId[message.threadId] = message;
    }

    final merged = byId.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}
