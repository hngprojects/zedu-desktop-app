import 'package:zedu/features/features.dart';

class PaginatedChannelMessages {
  const PaginatedChannelMessages({
    required this.messages,
    required this.pagination,
  });

  final List<ChannelMessage> messages;
  final ChannelPagination pagination;
}
