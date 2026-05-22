
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class DeleteOrganizationModal extends ConsumerStatefulWidget {
  const DeleteOrganizationModal({
    super.key,
    required this.organization,
    required this.onConfirm,
  });

  final Organization organization;
  final Future<void> Function() onConfirm;

  @override
  ConsumerState<DeleteOrganizationModal> createState() =>
      _DeleteOrganizationModalState();
}

class _DeleteOrganizationModalState
    extends ConsumerState<DeleteOrganizationModal> {
  int _step = 1;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _step = 2);
  }

  Future<void> _handleDelete() async {
    if (_passwordController.text.isEmpty) {
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: 'Please enter your password.',
      );
      return;
    }
    if (!_agreedToTerms) {
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: 'You must agree to the terms to proceed.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delete Organisation',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_step == 1) _buildStep1() else _buildStep2(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Are you sure you want to delete this organisation ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
            ),
            children: [
              TextSpan(
                text: widget.organization.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action will:'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: context.colors.success, size: 18),
            const SizedBox(width: 8),
            Text(
              'delete the organization, all associated data and members.',
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: context.colors.success, size: 18),
            const SizedBox(width: 8),
            Text(
              'remove the rest of your organisational perks',
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Note: This action cannot be undone. Consider waiting till the end of your billing cycle for the month',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: context.colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: context.colors.divider),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: context.colors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (value) =>
                    setState(() => _agreedToTerms = value ?? false),
                activeColor: context.colors.primary,
                side: BorderSide(color: context.colors.divider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'I agree to add my name and image to the deletion confirmation mail sent to the entire organisation.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleDelete,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ],
    );
  }
}
