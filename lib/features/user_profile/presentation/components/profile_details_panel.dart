import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ProfileDetailsPanel extends ConsumerWidget {
  const ProfileDetailsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(profileDetailsPanelProvider);
    if (member == null) return const SizedBox.shrink();

    final colors = context.colors;
    final textTheme = context.textTheme;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                InkWell(
                  onTap: () {
                    ref.read(profileDetailsPanelProvider.notifier).state = null;
                  },
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: member.avatarUrl != null
                        ? Image.network(member.avatarUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Text(
                              (member.name ?? member.email)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    member.name ?? member.email,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: member.status == TeamMemberStatus.active
                              ? colors.success
                              : colors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.status == TeamMemberStatus.active
                            ? 'Active'
                            : 'Offline',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ActionButton(
                        icon: Icons.notifications_off_outlined,
                        label: 'Mute',
                        colors: colors,
                        onTap: () {
                          AppToastService.show(
                            context,
                            type: AppToastType.info,
                            message: 'Feature coming soon',
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      ActionButton(
                        icon: Icons.visibility_off_outlined,
                        label: 'Hide',
                        colors: colors,
                        onTap: () {
                          AppToastService.show(
                            context,
                            type: AppToastType.info,
                            message: 'Feature coming soon',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contact Information',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ContactInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: member.email,
                    colors: colors,
                    textTheme: textTheme,
                  ),
                  const SizedBox(height: 16),
                  ContactInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '(555) 012-3456',
                    colors: colors,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

