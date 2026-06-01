import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 40, this.borderRadius = 8});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileNotifierProvider);
    final localPath = profileState.localAvatarPath;
    final avatarUrl = profileState.account?.avatarUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildImage(localPath, avatarUrl),
      ),
    );
  }

  Widget _buildImage(String? localPath, String? avatarUrl) {
    // 1. Local preview takes priority — instant feedback on file pick
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _networkOrDefault(avatarUrl),
      );
    }
    return _networkOrDefault(avatarUrl);
  }

  Widget _networkOrDefault(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final separator = avatarUrl.contains('?') ? '&' : '?';
      final urlWithCacheBuster = '$avatarUrl${separator}v=$cacheBuster';

      return Image.network(
        urlWithCacheBuster,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _defaultAvatar(),
      );
    }
    // 3. Default asset
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Image.asset('assets/pngs/default_avatar.png', fit: BoxFit.cover);
  }
}
