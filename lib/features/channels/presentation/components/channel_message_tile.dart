import 'package:flutter_html/flutter_html.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ChannelMessageTile extends StatelessWidget {
  const ChannelMessageTile({
    super.key,
    required this.message,
    required this.isMine,
  });

  final ChannelMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryBg,
            child: Text(
              _initials(message.fullName, message.username),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.fullName.isEmpty ? message.username : message.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeLabel(message.createdAt.toLocal()),
                      style: TextStyle(color: colors.textHint, fontSize: 12),
                    ),
                    if (isMine && message.edited)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'edited',
                          style: TextStyle(color: colors.textHint, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Html(
                  data: message.messageHtml,
                  shrinkWrap: true,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      color: colors.textPrimary,
                      fontSize: FontSize(14),
                    ),
                    'p': Style(margin: Margins.zero),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName, String username) {
    final source = fullName.trim().isNotEmpty ? fullName.trim() : username.trim();
    if (source.isEmpty) return '?';

    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  String _timeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
