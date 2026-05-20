import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelsRepositoryImpl implements ChannelsRepository {
  const ChannelsRepositoryImpl({required ChannelsRemoteDataSource remote})
    : _remote = remote;

  final ChannelsRemoteDataSource _remote;

  static const _tag = 'ChannelsRepository';

  @override
  Future<Result<PaginatedChannelMessages>> fetchChannelMessages({
    required String channelId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _remote.fetchChannelMessages(
        channelId: channelId,
        page: page,
        limit: limit,
      );

      return Success(result.toEntity());
    } on ApiFailure catch (failure) {
      AppLogger.w('Fetch channel messages failed - ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected error fetching channel messages', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }

  @override
  Future<Result<ChannelMessage>> sendChannelMessage({
    required String channelId,
    required String contentHtml,
    String? threadId,
    List<ChannelMedia> media = const [],
    List<ChannelMention> mentions = const [],
  }) async {
    try {
      final result = await _remote.sendChannelMessage(
        channelId: channelId,
        contentHtml: contentHtml,
        threadId: threadId,
        media: media,
        mentions: mentions,
      );

      return Success(result.toEntity());
    } on ApiFailure catch (failure) {
      AppLogger.w('Send channel message failed - ${failure.message}', tag: _tag);
      return Failure(failure);
    } catch (error) {
      AppLogger.e('Unexpected error sending channel message', tag: _tag, error: error);
      return Failure(ApiFailure.unknown(error));
    }
  }
}
