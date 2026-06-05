// import 'package:flutter/services.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class BuzzReadyCard extends ConsumerWidget {
  final String meetingLink;
  final String buzzId;
  final VoidCallback onJoin;
  final VoidCallback onDismiss;

  const BuzzReadyCard({
    super.key,
    required this.meetingLink,
    required this.buzzId,
    required this.onJoin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final displayName = user?.fullname ?? user?.username ?? 'You';

    return Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your buzz is ready',
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add Others button
          _AddOthersButton(buzzId: buzzId),
          const SizedBox(height: 14),

          // Meeting link row
          if (meetingLink.isNotEmpty) ...[
            Text(
              'Or share this meeting link with others that you want in the meeting',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _MeetingLinkRow(link: meetingLink),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'People who use this buzz link must get your permission before they can join.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Joined as
          Text(
            'Joined as $displayName',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Join now button
          SizedBox(
            width: double.infinity,
            child: _JoinNowButton(onPressed: onJoin),
          ),
        ],
      ),
    );
  }
}

class _AddOthersButton extends ConsumerStatefulWidget {
  final String buzzId;

  const _AddOthersButton({required this.buzzId});

  @override
  ConsumerState<_AddOthersButton> createState() => _AddOthersButtonState();
}

class _AddOthersButtonState extends ConsumerState<_AddOthersButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) => BuzzAddPeopleDialog(buzzId: widget.buzzId),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF5A4DE0) : const Color(0xFF6458F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_add_outlined,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Add Others',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingLinkRow extends StatefulWidget {
  final String link;

  const _MeetingLinkRow({required this.link});

  @override
  State<_MeetingLinkRow> createState() => _MeetingLinkRowState();
}

class _MeetingLinkRowState extends State<_MeetingLinkRow> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.link,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _copy,
              child: Tooltip(
                message: _copied ? 'Copied!' : 'Copy link',
                child: Icon(
                  _copied ? Icons.check_circle_outline : Icons.copy_rounded,
                  size: 18,
                  color: _copied ? Colors.green.shade600 : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinNowButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _JoinNowButton({required this.onPressed});

  @override
  State<_JoinNowButton> createState() => _JoinNowButtonState();
}

class _JoinNowButtonState extends State<_JoinNowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.grey.shade800 : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Join now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
