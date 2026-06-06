import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GlobalCallOverlay extends ConsumerWidget {
  const GlobalCallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCall = ref.watch(activeCallProvider);
    final sidebar = ref.watch(homeSidebarProvider);
    final colors = context.colors;

    if (activeCall.state.status == CallStatus.none) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // ── Full-page call view ────────────────────────────────────────
        if (activeCall.state.status == CallStatus.active && activeCall.state.isFullPage)
          const Positioned.fill(child: BuzzMeetingView()),

        // ── Floating / PIP call view ───────────────────────────────────
        if (activeCall.state.status == CallStatus.active && !activeCall.state.isFullPage)
          const BuzzMeetingView(),

        // ── Incoming call modal ────────────────────────────────────────
        if (activeCall.state.status == CallStatus.incoming)
          const IncomingCallModal(),

        if (activeCall.state.status == CallStatus.calling &&
            sidebar != HomeSidebarType.buzz)
          Positioned(
            top: 60, // Avoid overlapping with top app bar
            right: 24,
            child: Material(
              color: Colors.transparent,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Calling...',
                            style: TextStyle(
                              color: colors.textHint,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            activeCall.state.remoteUserName ?? 'Unknown',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_end),
                      color: Colors.red,
                      onPressed: () =>
                          ref.read(activeCallProvider.notifier).cancelCall(),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
