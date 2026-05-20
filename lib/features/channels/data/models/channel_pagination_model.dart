import 'package:zedu/features/features.dart';

class ChannelPaginationModel {
  const ChannelPaginationModel({
    required this.currentPage,
    required this.pageCount,
    required this.totalPagesCount,
  });

  final int currentPage;
  final int pageCount;
  final int totalPagesCount;

  factory ChannelPaginationModel.fromJson(Map<String, dynamic> json) {
    return ChannelPaginationModel(
      currentPage: json['current_page'] as int? ?? 1,
      pageCount: json['page_count'] as int? ?? 1,
      totalPagesCount: json['total_pages_count'] as int? ?? 1,
    );
  }

  ChannelPagination toEntity() => ChannelPagination(
    currentPage: currentPage,
    pageCount: pageCount,
    totalPagesCount: totalPagesCount,
  );
}
