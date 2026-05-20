import 'package:riverpod/riverpod.dart';

/// State for user menu UI
class UserMenuState {
  final bool isAway;
  final bool notificationsPaused;

  UserMenuState({this.isAway = false, this.notificationsPaused = false});

  UserMenuState copyWith({bool? isAway, bool? notificationsPaused}) {
    return UserMenuState(
      isAway: isAway ?? this.isAway,
      notificationsPaused: notificationsPaused ?? this.notificationsPaused,
    );
  }
}

/// Provider for managing user menu state (away status, notifications paused, etc)
final userMenuStateProvider = NotifierProvider<UserMenuNotifier, UserMenuState>(
  UserMenuNotifier.new,
);

class UserMenuNotifier extends Notifier<UserMenuState> {
  @override
  UserMenuState build() {
    return UserMenuState();
  }

  void toggleAwayStatus() {
    state = state.copyWith(isAway: !state.isAway);
  }

  void toggleNotifications() {
    state = state.copyWith(notificationsPaused: !state.notificationsPaused);
  }

  void reset() {
    state = UserMenuState();
  }
}
