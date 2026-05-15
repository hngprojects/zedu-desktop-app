import 'package:zedu/core/core.dart';

class WorkspaceTopBar extends StatelessWidget {
  const WorkspaceTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: context.s(52),
      color: colors.primary,
      padding: context.symmetric(horizontal: 12),
      child: Row(
        children: [
          const _WorkspaceSwitcherButton(),
          const Spacer(),
          SizedBox(width: context.s(420), child: const _SearchBox()),
          const Spacer(),
        ],
      ),
    );
  }
}

class _WorkspaceSwitcherButton extends StatefulWidget {
  const _WorkspaceSwitcherButton();

  @override
  State<_WorkspaceSwitcherButton> createState() =>
      _WorkspaceSwitcherButtonState();
}

class _WorkspaceSwitcherButtonState extends State<_WorkspaceSwitcherButton> {
  String selectedWorkspace = 'HNG Workspace';

  final List<String> workspaces = [
    'HNG Workspace',
    'Design Team',
    'Dev Cohort',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          selectedWorkspace = value;
        });
      },
      offset: Offset(0, context.s(36)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.s(6)),
      ),
      color: colors.background,
      itemBuilder: (context) => workspaces
          .map(
            (workspace) => PopupMenuItem<String>(
              value: workspace,
              child: Text(
                workspace,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: context.s(32),
        padding: context.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(context.s(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: context.s(18),
              height: context.s(18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.background,
                  width: context.s(2),
                ),
                borderRadius: BorderRadius.circular(context.s(3)),
              ),
              child: Text(
                '[]',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.background,
                  fontWeight: FontWeight.w700,
                  fontSize: context.s(9),
                  height: 1,
                ),
              ),
            ),
            context.gapH(6),
            Text(
              selectedWorkspace,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.background,
                fontWeight: FontWeight.w600,
              ),
            ),
            context.gapH(4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.s(16),
              color: colors.background.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: context.s(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.s(6)),
      ),
      child: TextField(
        cursorColor: colors.background,
        style: context.textTheme.labelMedium?.copyWith(
          color: colors.background,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Search messages...',
          hintStyle: context.textTheme.labelMedium?.copyWith(
            color: colors.background.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: context.s(16),
            color: colors.background.withValues(alpha: 0.85),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: context.s(32)),
          contentPadding: context.symmetric(horizontal: 8, vertical: 6),
        ),
      ),
    );
  }
}
