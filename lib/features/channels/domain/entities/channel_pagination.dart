class ChannelPagination {
  const ChannelPagination({
    required this.currentPage,
    required this.pageCount,
    required this.totalPagesCount,
  });

  final int currentPage;
  final int pageCount;
  final int totalPagesCount;
}
