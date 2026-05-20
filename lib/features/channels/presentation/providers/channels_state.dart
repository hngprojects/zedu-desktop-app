import 'package:zedu/features/features.dart';

class ChannelsState {
  const ChannelsState({
    this.selectedChannelId,
    this.messages = const [],
    this.pagination,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSending = false,
    this.isPolling = false,
    this.error,
  });

  final String? selectedChannelId;
  final List<ChannelMessage> messages;
  final ChannelPagination? pagination;
  final bool isLoading;
  final bool isRefreshing;
  final bool isSending;
  final bool isPolling;
  final String? error;

  bool get hasSelectedChannel =>
      selectedChannelId != null && selectedChannelId!.trim().isNotEmpty;

  ChannelsState copyWith({
    String? selectedChannelId,
    List<ChannelMessage>? messages,
    ChannelPagination? pagination,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSending,
    bool? isPolling,
    String? error,
    bool clearError = false,
    bool clearChannel = false,
    bool clearMessages = false,
  }) {
    return ChannelsState(
      selectedChannelId: clearChannel
          ? null
          : selectedChannelId ?? this.selectedChannelId,
      messages: clearMessages ? const [] : (messages ?? this.messages),
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSending: isSending ?? this.isSending,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
