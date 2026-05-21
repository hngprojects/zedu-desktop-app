import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/domain/domain.dart';

class DmProfileCard extends StatelessWidget {
  final DmConversation conversation;

  const DmProfileCard({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = conversation.displayName;
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final handle = nameParts.length > 1
        ? '@${nameParts.first}_${nameParts.last}'
        : '@${nameParts.first}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF6458F5),
            backgroundImage: conversation.effectiveAvatarUrl != null
                ? NetworkImage(conversation.effectiveAvatarUrl!)
                : null,
            child: conversation.effectiveAvatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              children: [
                const TextSpan(
                  text: 'This conversation is just between you and ',
                ),
                TextSpan(
                  text: handle,
                  style: const TextStyle(
                    color: Color(0xFF6458F5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: '. Check out their profile to learn about them.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'View Profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
