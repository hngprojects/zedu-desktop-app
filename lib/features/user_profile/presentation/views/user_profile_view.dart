import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserProfileView extends ConsumerWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: state.isLoading
            ? CircularProgressIndicator(color: context.colors.primary)
            : Text(
                'User profile settings',
                style: context.textTheme.headlineMedium,
              ),
      ),
    );
  }
}
