import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';


class CreateOrganizationPage extends ConsumerStatefulWidget {
  const CreateOrganizationPage({super.key});

  @override
  ConsumerState<CreateOrganizationPage> createState() =>
      _CreateOrganizationPageState();
}

class _CreateOrganizationPageState
    extends ConsumerState<CreateOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _orgTypeController = TextEditingController();
  String? _selectedCountry;

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgTypeController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      AppToastService.show(
        context,
        type: AppToastType.error,
        message: 'Please select a country',
      );
      return;
    }

    ref.read(createOrganizationControllerProvider.notifier).create(
          CreateOrganizationRequest(
            name: _orgNameController.text.trim(),
            type: _orgTypeController.text.trim(),
            country: _selectedCountry!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createOrganizationControllerProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.hasError) {
          AppToastService.show(
            context,
            type: AppToastType.error,
            message: next.error.toString(),
          );
        } else if (next.hasValue) {
          AppToastService.show(
            context,
            type: AppToastType.success,
            message: 'Organization created successfully',
          );
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              context.go(AppRouter.organizationHome);
            }
          });
        }
      }
    });

    final state = ref.watch(createOrganizationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Your Organization',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input the details of your organization below',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    AppTextField(
                      controller: _orgNameController,
                      label: 'Organization Name',
                      hint: 'Enter your organization Name',
                      validator: (val) => val == null || val.isEmpty
                          ? 'Organization name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _orgTypeController,
                      label: 'Organization Type',
                      hint: 'What does your organization do',
                      validator: (val) => val == null || val.isEmpty
                          ? 'Organization type is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Country',
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.borderOutline),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCountry ?? 'Select an option...',
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: _selectedCountry == null
                                    ? context.colors.textHint
                                    : context.colors.textPrimary,
                                fontFamily: FontFamily.roboto,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: context.colors.borderOutline,
                                  margin: const EdgeInsets.only(right: 8),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.colors.textHint,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Submit',
                      loading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
