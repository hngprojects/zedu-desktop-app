import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class SidebarRail extends ConsumerWidget {
  const SidebarRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selectedSection = ref.watch(menuProvider);

    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(
          right: BorderSide(color: colors.onPrimary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          RailNavItem(
            icon: Icons.home_filled,
            label: 'Home',
            section: MenuSection.home,
            isActive: selectedSection == MenuSection.home,
          ),
          RailNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'DMs',
            section: MenuSection.dms,
            isActive: selectedSection == MenuSection.dms,
          ),
          RailNavItem(
            icon: Icons.people_outline,
            label: 'People',
            section: MenuSection.people,
            isActive: selectedSection == MenuSection.people,
          ),
          RailNavItem(
            icon: Icons.folder_open_outlined,
            label: 'Files',
            section: MenuSection.files,
            isActive: selectedSection == MenuSection.files,
          ),
          RailNavItem(
            icon: Icons.phone_outlined,
            label: 'Buzz',
            section: MenuSection.buzz,
            isActive: selectedSection == MenuSection.buzz,
          ),
          const Spacer(),
          const RailBottomIcon(
            icon: Icons.notifications_none_outlined,
            hasNotification: true,
          ),
          const RailBottomIcon(icon: Icons.settings_outlined),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    color: colors.divider,
                    child: Icon(Icons.person, color: colors.onPrimary),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.sidebar, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RailNavItem extends ConsumerWidget {
  const RailNavItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.isActive,
    super.key,
  });

  final IconData icon;
  final String label;
  final MenuSection section;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return InkWell(
      onTap: () => ref.read(menuProvider.notifier).select(section),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.onPrimary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.onPrimary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RailBottomIcon extends StatelessWidget {
  const RailBottomIcon({
    required this.icon,
    this.hasNotification = false,
    super.key,
  });

  final IconData icon;
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          Icon(icon, color: colors.onPrimary, size: 24),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
