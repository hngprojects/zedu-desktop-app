import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final menuState = ref.watch<UserMenuState>(userMenuStateProvider);

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.3),
          builder: (context) => const UserMenuDialog(),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: () {
              final avatarUrl = ref.watch(userProfileNotifierProvider).account?.avatarUrl;
              return Container(
                width: 32,
                height: 32,
                color: colors.sidebar,
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/pngs/default_avatar.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/pngs/default_avatar.png',
                        fit: BoxFit.cover,
                      ),
              );
            }(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: menuState.isAway ? colors.textHint : colors.success,
                shape: BoxShape.circle,
                border: Border.all(color: colors.sidebar, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
