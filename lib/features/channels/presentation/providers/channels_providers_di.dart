import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

final channelsRemoteDataSourceProvider = Provider<ChannelsRemoteDataSource>(
  (ref) => ChannelsRemoteDataSourceImpl(
    config: locator<AppConfig>(),
    apiBaseService: locator<ApiBaseService>(),
  ),
);

final channelsRepositoryProvider = Provider<ChannelsRepository>(
  (ref) =>
      ChannelsRepositoryImpl(remote: ref.watch(channelsRemoteDataSourceProvider)),
);

final channelsNotifierProvider =
    NotifierProvider<ChannelsNotifier, ChannelsState>(ChannelsNotifier.new);
