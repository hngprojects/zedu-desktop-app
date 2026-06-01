import 'package:zedu/core/core.dart';

Future<void> showDeleteAccountDialog(
  BuildContext context,
  String email,
  Future<void> Function(String password) onConfirm,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) =>
        _DeleteAccountDialog(email: email, onConfirm: onConfirm),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.email, required this.onConfirm});

  final String email;
  final Future<void> Function(String password) onConfirm;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _step = 1;
  final _passwordCtrl = TextEditingController();
  bool _consentChecked = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    await widget.onConfirm(_passwordCtrl.text);
    if (mounted) {
      setState(() => _isLoading = false);
      // Close the dialog on success
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delete Account',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textHint),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_step == 1) ...[
              Text(
                'Are you sure you want to delete your account with ${widget.email}? You will lose:',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLossItem(context, 'Access to this workspace.'),
              const SizedBox(height: 8),
              _buildLossItem(context, 'All your chats history.'),
              const SizedBox(height: 32),
              Text(
                'Note: This action cannot be undone.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textHint,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outlined(
                    label: 'Cancel',
                    expand: false,
                    height: 40,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Continue',
                    expand: false,
                    height: 40,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF6B46C1,
                      ), // Purple from screenshot
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _step = 2);
                    },
                  ),
                ],
              ),
            ] else ...[
              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordCtrl,
                isPassword: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _consentChecked,
                      onChanged: (val) {
                        setState(() => _consentChecked = val ?? false);
                      },
                      activeColor: colors.primary,
                      side: BorderSide(color: colors.textHint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I absolve Zedu of any responsibility in this account deletion.',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outlined(
                    label: 'Cancel',
                    expand: false,
                    height: 40,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Delete Account',
                    expand: false,
                    height: 40,
                    loading: _isLoading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFEF4444,
                      ), // Red from screenshot
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        (_passwordCtrl.text.isNotEmpty &&
                            _consentChecked &&
                            !_isLoading)
                        ? _handleConfirm
                        : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLossItem(BuildContext context, String text) {
    final colors = context.colors;
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
