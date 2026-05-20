import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

abstract interface class ChannelsRepository {
  Future<Result<PaginatedChannelMessages>> fetchChannelMessages({
    required String channelId,
    int page = 1,
    int limit = 20,
  });

  Future<Result<ChannelMessage>> sendChannelMessage({
    required String channelId,
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  });
}
