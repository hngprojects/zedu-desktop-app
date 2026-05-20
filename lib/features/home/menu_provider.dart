import 'package:zedu/core/core.dart';

import 'menu_section.dart';

final menuProvider = NotifierProvider<MenuNotifier, MenuSection>(
  MenuNotifier.new,
);

class MenuNotifier extends Notifier<MenuSection> {
  @override
  MenuSection build() {
    return MenuSection.home;
  }

  void select(MenuSection section) {
    state = section;
  }
}
