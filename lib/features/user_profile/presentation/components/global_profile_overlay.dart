import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class GlobalProfileOverlay extends ConsumerWidget {
  const GlobalProfileOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProfile = ref.watch(personalProfilePanelProvider);

    return Stack(
      children: [
        child,
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
