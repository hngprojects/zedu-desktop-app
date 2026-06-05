import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GlobalProfileOverlay extends ConsumerStatefulWidget {
  const GlobalProfileOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GlobalProfileOverlay> createState() =>
      _GlobalProfileOverlayState();
}

class _GlobalProfileOverlayState extends ConsumerState<GlobalProfileOverlay> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(appRouterProvider);
    _router?.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    // When the route changes, if the profile is open, close it.
    if (ref.read(personalProfilePanelProvider)) {
      ref.read(personalProfilePanelProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProfile = ref.watch(personalProfilePanelProvider);

    return Stack(
      children: [
        widget.child,
        if (showProfile)
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: PersonalProfilePanel(),
          ),
      ],
    );
  }
}
