import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GeneralBuzzView extends ConsumerStatefulWidget {
  const GeneralBuzzView({super.key});

  @override
  ConsumerState<GeneralBuzzView> createState() => _GeneralBuzzViewState();
}

class _GeneralBuzzViewState extends ConsumerState<GeneralBuzzView> {
  final _codeController = TextEditingController();
  bool _showNewMeetingMenu = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleJoin() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      ref.read(orgBuzzProvider.notifier).joinByCodeOrLink(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buzz = ref.watch(orgBuzzProvider);
    final isLoading =
        buzz.status == OrgBuzzStatus.creating ||
        buzz.status == OrgBuzzStatus.joining;

    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'General Buzz',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main content ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Seamless video calls and meetings\nfor every learning community.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Connect classrooms, cohorts, and teams in one shared space',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NewMeetingButton(
                            isOpen: _showNewMeetingMenu,
                            isLoading: isLoading,
                            onToggle: () => setState(
                              () =>
                                  _showNewMeetingMenu = !_showNewMeetingMenu,
                            ),
                            onInstant: () {
                              setState(() => _showNewMeetingMenu = false);
                              ref
                                  .read(orgBuzzProvider.notifier)
                                  .startInstantMeeting();
                            },
                            onGetLink: () {
                              setState(() => _showNewMeetingMenu = false);
                              ref
                                  .read(orgBuzzProvider.notifier)
                                  .createForLater();
                            },
                          ),
                          const SizedBox(width: 12),
                          _CodeInput(
                            controller: _codeController,
                            onSubmit: _handleJoin,
                          ),
                          const SizedBox(width: 8),
                          _JoinButton(
                            isLoading:
                                buzz.status == OrgBuzzStatus.joining,
                            onPressed: _handleJoin,
                          ),
                        ],
                      ),

                      // Error banner
                      if (buzz.status == OrgBuzzStatus.error &&
                          buzz.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(
                          message: buzz.errorMessage!,
                          onDismiss: () =>
                              ref
                                  .read(orgBuzzProvider.notifier)
                                  .dismissError(),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Illustration — always at the bottom
                      Image.asset(
                        'assets/pngs/buzz.png',
                        width: 320,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => SizedBox(
                          width: 320,
                          height: 220,
                          child: Icon(
                            Icons.videocam_rounded,
                            size: 80,
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay
        if (isLoading) const _LoadingOverlay(),
      ],
    );
  }
}

// ── New Meeting Button + dropdown ─────────────────────────────────────────────

class _NewMeetingButton extends StatefulWidget {
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onToggle;
  final VoidCallback onInstant;
  final VoidCallback onGetLink;

  const _NewMeetingButton({
    required this.isOpen,
    required this.isLoading,
    required this.onToggle,
    required this.onInstant,
    required this.onGetLink,
  });

  @override
  State<_NewMeetingButton> createState() => _NewMeetingButtonState();
}

class _NewMeetingButtonState extends State<_NewMeetingButton> {
  bool _hovered = false;
  final GlobalKey _buttonKey = GlobalKey();

  void _showMenu() async {
    if (widget.isLoading) return;
    
    widget.onToggle();
    
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final result = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 4,
        position.dx + size.width,
        position.dy + size.height + 100,
      ),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 18, color: Color(0xFF6458F5)),
              const SizedBox(width: 10),
              Text(
                'Get a link',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF6458F5)),
              const SizedBox(width: 10),
              Text(
                'Start an instant meeting',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    widget.onToggle();

    if (result == 0) {
      widget.onGetLink();
    } else if (result == 1) {
      widget.onInstant();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _buttonKey,
        onTap: _showMenu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF5A4DE0) : const Color(0xFF6458F5),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6458F5).withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'New meeting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                widget.isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Code input ────────────────────────────────────────────────────────────────

class _CodeInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CodeInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 44,
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Enter a code or link',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: Icon(
            Icons.keyboard_rounded,
            size: 18,
            color: Colors.grey.shade500,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF6458F5),
              width: 1.5,
            ),
          ),
        ),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

// ── Join button ───────────────────────────────────────────────────────────────

class _JoinButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _JoinButton({required this.isLoading, required this.onPressed});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? Colors.grey.shade300 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Join',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading overlay ───────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF6458F5),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preparing your meeting…',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
