import re

with open('lib/core/widgets/app_toast.dart', 'r') as f:
    content = f.read()

new_toast = """class _AppToastWidget extends StatefulWidget {
  const _AppToastWidget({
    required this.type,
    required this.message,
    required this.scale,
    required this.onDismiss,
  });

  final AppToastType type;
  final String message;
  final double scale;
  final VoidCallback onDismiss;

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (accentColor, bgColor, icon) = switch (widget.type) {
      AppToastType.success => (
        colors.success,
        const Color(0xFFD4F7D4), // Light green matching the screenshot
        Icons.check_circle,
      ),
      AppToastType.error => (
        colors.error,
        colors.errorBg,
        Icons.error,
      ),
      AppToastType.info => (
        colors.primary,
        colors.primaryBg,
        Icons.info,
      ),
    };

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
"""

pattern = re.compile(r'class _AppToastWidget extends StatefulWidget \{.*', re.MULTILINE | re.DOTALL)
new_content = pattern.sub(new_toast, content)

with open('lib/core/widgets/app_toast.dart', 'w') as f:
    f.write(new_content)
