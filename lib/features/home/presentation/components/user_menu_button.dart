import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final menuState = ref.watch<UserMenuState>(userMenuStateProvider);
    final isAway = menuState.isAway;

    return GestureDetector(
      onTap: () {
        context.go(AppRouter.profile);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar using the global reactive widget
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const UserAvatar(size: 32, borderRadius: 8),
          ),
          // Presence dot — bottom-left of the avatar, matching the design spec
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isAway ? colors.textHint : colors.success,
                shape: BoxShape.circle,
                border: Border.all(color: colors.sidebar, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
