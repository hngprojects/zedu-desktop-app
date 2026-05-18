import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ResetPasswordView extends ConsumerStatefulWidget {
  const ResetPasswordView({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPasswordPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );

    if (success && mounted) {
      AppToastService.show(
        context,
        type: AppToastType.success,
        message: 'Password reset successfully!',
      );
      context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: next.error!,
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/pngs/zedu_logo.png', width: 83, height: 31),
              Text.rich(
                TextSpan(
                  text: 'Go back to login? ',
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.colors.textPrimary,
                    fontFamily: FontFamily.roboto,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colors.primary,
                        fontFamily: FontFamily.roboto,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.go(AppRouter.login),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                context.gapV(80),
                Text(
                  'Reset Password',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                context.gapV(12),
                Text(
                  'Choose a new password for your account',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                context.gapV(48),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        isPassword: true,
                        controller: _oldPasswordController,
                        label: 'Enter old password',
                        hint: 'Old Password',
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            Validators.validatePassword(context, value),
                      ),
                      context.gapV(16),
                      AppTextField(
                        isPassword: true,
                        controller: _newPasswordController,
                        label: 'Enter new password',
                        hint: 'New Password',
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            Validators.validatePassword(context, value),
                      ),
                      context.gapV(16),
                      AppTextField(
                        isPassword: true,
                        controller: _confirmPasswordController,
                        label: 'Confirm new password',
                        hint: 'Confirm new Password',
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      context.gapV(32),
                      AppButton(
                        label: 'Reset Password',
                        loading: authState.isLoading,
                        onPressed: _onResetPasswordPressed,
                      ),
                      context.gapV(16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => context.go(AppRouter.login),
                          child: Text(
                            'Back to Login',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                context.gapV(48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
