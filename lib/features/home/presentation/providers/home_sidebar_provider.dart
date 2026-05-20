import 'package:zedu/core/core.dart';

enum HomeSidebarType { home, dms, people, files, buzz }

final homeSidebarProvider = StateProvider<HomeSidebarType>((ref) {
  return HomeSidebarType.home;
});
