import 'package:zedu/features/features.dart';

class PaginatedChannelMessagesModel {
  const PaginatedChannelMessagesModel({
    required this.messages,
    required this.pagination,
  });

  final List<ChannelMessageModel> messages;
  final ChannelPaginationModel pagination;

  factory PaginatedChannelMessagesModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = (json['data'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    final rawPagination =
        (json['pagination'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};

    return PaginatedChannelMessagesModel(
      messages: rawMessages.map(ChannelMessageModel.fromJson).toList(),
      pagination: ChannelPaginationModel.fromJson(rawPagination),
    );
  }

  PaginatedChannelMessages toEntity() => PaginatedChannelMessages(
    messages: messages.map((e) => e.toEntity()).toList(),
    pagination: pagination.toEntity(),
  );
}
