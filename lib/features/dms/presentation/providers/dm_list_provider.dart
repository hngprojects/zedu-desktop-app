import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/dms/domain/domain.dart';
import 'package:zedu/features/dms/data/data.dart';

final dmListProvider =
    AsyncNotifierProvider<DmListNotifier, List<DmConversation>>(() {
  return DmListNotifier();
});

final selectedDmProvider = StateProvider<DmConversation?>((ref) => null);

class DmListNotifier extends AsyncNotifier<List<DmConversation>> {
  int _currentPage = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<DmConversation>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _fetchPage(1);
  }

  Future<List<DmConversation>> _fetchPage(int page) async {
    final repository = ref.read(dmRepositoryProvider);
    final results = await repository.getConversations(page: page);
    if (results.length < DmRepository.pageSize) {
      _hasMore = false;
    }
    return results;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    _currentPage++;
    final next = await _fetchPage(_currentPage);
    state = AsyncValue.data([...current, ...next]);
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }
}
