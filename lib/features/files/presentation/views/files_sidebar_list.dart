import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilesSidebarList extends ConsumerWidget {
  const FilesSidebarList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filterState = ref.watch(filesFilterProvider);

    return Container(
      width: 250,
      color: colors.background,
      child: Column(
        children: [
          _SidebarItem(
            icon: Icons.copy, 
            label: 'All files', 
            isSelected: filterState.category == 'all',
            onTap: () => ref.read(filesFilterProvider.notifier).updateCategory('all'),
          ),
          _SidebarItem(
            icon: Icons.insert_drive_file_outlined, 
            label: 'My files', 
            isSelected: filterState.category == 'my_files',
            onTap: () => ref.read(filesFilterProvider.notifier).updateCategory('my_files'),
          ),
          _SidebarItem(
            icon: Icons.people_outline, 
            label: 'Shared with me', 
            isSelected: filterState.category == 'shared',
            onTap: () => ref.read(filesFilterProvider.notifier).updateCategory('shared'),
          ),
          _SidebarItem(
            icon: Icons.delete_outline, 
            label: 'Deleted files', 
            isSelected: filterState.category == 'deleted',
            onTap: () => ref.read(filesFilterProvider.notifier).updateCategory('deleted'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    final bgColor = widget.isSelected
        ? colors.primary.withValues(alpha: 0.1)
        : (_isHovered ? colors.divider.withValues(alpha: 0.5) : Colors.transparent);
        
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon, 
                color: widget.isSelected ? colors.primary : colors.textHint, 
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected ? colors.primary : colors.textPrimary,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
