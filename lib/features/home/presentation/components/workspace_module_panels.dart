import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Copy and sidebar metadata for a workspace module that is not built yet.
class WorkspacePlaceholderConfig {
  const WorkspacePlaceholderConfig({
    required this.sectionTitle,
    required this.searchHint,
    required this.emptySidebarMessage,
    required this.icon,
    required this.title,
    required this.message,
  });

  final String sectionTitle;
  final String searchHint;
  final String emptySidebarMessage;
  final IconData icon;
  final String title;
  final String message;
}

/// Placeholder definitions keyed by [HomeSidebarType].
abstract final class WorkspacePlaceholders {
  static const people = WorkspacePlaceholderConfig(
    sectionTitle: 'Members',
    searchHint: 'Find people',
    emptySidebarMessage: 'No members to show yet',
    icon: Icons.people_outline,
    title: 'People',
    message:
        'Browse organization members here. Member search and profiles are coming soon.',
  );

  static const files = WorkspacePlaceholderConfig(
    sectionTitle: 'Shared files',
    searchHint: 'Search files',
    emptySidebarMessage: 'No shared files yet',
    icon: Icons.folder_open_outlined,
    title: 'Files',
    message:
        'Shared workspace files will show up here with search and filters soon.',
  );

  static const buzz = WorkspacePlaceholderConfig(
    sectionTitle: 'Recent buzz',
    searchHint: 'Find a call',
    emptySidebarMessage: 'No recent buzz calls',
    icon: Icons.phone_outlined,
    title: 'Buzz',
    message:
        'Start an audio or video call from a DM or channel. Your active calls will appear here.',
  );

  static const notifications = WorkspacePlaceholderConfig(
    sectionTitle: 'All notifications',
    searchHint: 'Search notifications',
    emptySidebarMessage: 'No notifications yet',
    icon: Icons.notifications_none_outlined,
    title: 'Notifications',
    message:
        'Mentions, replies, and workspace activity will show up here soon.',
  );

  static WorkspacePlaceholderConfig forType(HomeSidebarType type) {
    return switch (type) {
      HomeSidebarType.people => people,
      HomeSidebarType.files => files,
      HomeSidebarType.buzz => buzz,
      HomeSidebarType.notifications => notifications,
      _ => throw ArgumentError('$type is not a placeholder module'),
    };
  }
}

class WorkspacePlaceholderSidebar extends ConsumerWidget {
  const WorkspacePlaceholderSidebar({super.key, required this.config});

  final WorkspacePlaceholderConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: colors.onPrimary.withValues(alpha: 0.68),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          Icons.search,
                          color: colors.onPrimary.withValues(alpha: 0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.searchHint,
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              config.sectionTitle,
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  config.emptySidebarMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspacePlaceholderContent extends StatelessWidget {
  const WorkspacePlaceholderContent({super.key, required this.config});

  final WorkspacePlaceholderConfig config;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      color: colors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.s(420)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  config.icon,
                  size: context.s(56),
                  color: colors.primary.withValues(alpha: 0.85),
                ),
                context.gapV(20),
                Text(
                  config.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                context.gapV(12),
                Text(
                  config.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textHint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
