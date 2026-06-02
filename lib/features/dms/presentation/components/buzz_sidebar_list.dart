import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BuzzSidebarList extends ConsumerWidget {
  const BuzzSidebarList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final logState = ref.watch(buzzLogProvider);

    return Container(
      width: 320,
      color: colors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceSwitcherHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Buzz Call Logs',
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: logState.logs.isEmpty
                ? Center(
                    child: Text(
                      'No call logs',
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: logState.logs.length,
                    itemBuilder: (context, index) {
                      final log = logState.logs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary,
                          child: const Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          log.callerName,
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(log.timestamp),
                          style: TextStyle(
                            color: colors.onPrimary.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        trailing: Icon(
                          log.isIncoming
                              ? (log.isMissed
                                    ? Icons.call_missed
                                    : Icons.call_received)
                              : Icons.call_made,
                          color: log.isMissed
                              ? colors.error
                              : colors.onPrimary.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} $hour:$minute $period';
  }
}
