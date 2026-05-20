import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/domain/domain.dart';

/// Profile card shown at the top of a DM thread, matching Figma design.
class DmProfileCard extends StatelessWidget {
  final DmConversation conversation;

  const DmProfileCard({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF6458F5),
            backgroundImage: conversation.participantAvatarUrl != null
                ? NetworkImage(conversation.participantAvatarUrl!)
                : null,
            child: conversation.participantAvatarUrl == null
                ? Text(
                    conversation.participantName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            conversation.participantName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Bio / description
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              children: [
                const TextSpan(
                  text: 'This conversation is just between you and ',
                ),
                TextSpan(
                  text: '@${conversation.participantName.split(' ').first}_${conversation.participantName.split(' ').last}',
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
          // View Profile button
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to profile detail
            },
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
