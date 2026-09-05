import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isOnline =
        ref.watch(authNotifierProvider).user?.status.online ?? true;

    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) => const UserMenuDialog(),
        );
      },
      child: Stack(
        children: [
          const UserAvatar(size: 36, borderRadius: 8),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 16,
              height: 16,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: colors.sidebar,
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? colors.success : colors.sidebar,
                  border: isOnline
                      ? null
                      : Border.all(color: colors.textHint, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
