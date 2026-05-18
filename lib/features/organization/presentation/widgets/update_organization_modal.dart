import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Shown via [showDialog] from [OrganizationGeneralSettingsPage] when the user
/// taps the edit (pencil) icon.
///
/// Usage:
///   showDialog(
///     context: context,
///     builder: (_) => UpdateOrganizationModal(organization: org),
///   );
class UpdateOrganizationModal extends ConsumerStatefulWidget {
  const UpdateOrganizationModal({super.key, required this.organization});

  final Organization organization;

  @override
  ConsumerState<UpdateOrganizationModal> createState() =>
      _UpdateOrganizationModalState();
}

class _UpdateOrganizationModalState
    extends ConsumerState<UpdateOrganizationModal> {
  static const _countryItemHeight = 48.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  final List<Country> _countries = CountryService().getAll();
  Country? _selectedCountry;

  XFile? _pickedImage;
  bool _isImageRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.organization.name);
    _typeController =
        TextEditingController(text: widget.organization.industry);
    _selectedCountry = _countries
        .where((c) => c.name == widget.organization.country)
        .firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _isImageRemoved = false;
        });
      }
    } catch (e) {
      AppLogger.e('Failed to pick image: $e');
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Failed to select image',
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _isImageRemoved = true;
    });
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

    ref
        .read(updateOrganizationControllerProvider.notifier)
        .updateOrganization(
          UpdateOrganizationRequest(
            orgId: widget.organization.id,
            name: _nameController.text.trim(),
            type: _typeController.text.trim(),
            country: _selectedCountry!.name,
            logoFile: _pickedImage,
            removeLogo: _isImageRemoved,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateOrganizationControllerProvider, (previous, next) {
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
            message: 'Organization updated successfully',
          );
          Navigator.of(context).pop();
        }
      }
    });

    final state = ref.watch(updateOrganizationControllerProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update organisation details',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Divider(color: context.colors.divider, height: 24),

             
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextField(
                                controller: _nameController,
                                label: 'Organisation Name',
                                hint: 'Enter your organisation name',
                                validator: (val) =>
                                    val == null || val.isEmpty
                                        ? 'Organisation name is required'
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              AppTextField(
                                controller: _typeController,
                                label: 'Nature of Business',
                                hint: 'What does your organisation do',
                                validator: (val) =>
                                    val == null || val.isEmpty
                                        ? 'Nature of business is required'
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
                              DropdownButtonFormField<Country>(
                                key: const Key('modal_country_dropdown'),
                                initialValue: _selectedCountry,
                                isExpanded: true,
                                itemHeight: _countryItemHeight,
                                menuMaxHeight: _countryItemHeight * 7,
                                style: context.textTheme.bodyLarge?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontFamily: FontFamily.roboto,
                                ),
                                hint: Text(
                                  'Select an option...',
                                  style:
                                      context.textTheme.bodyLarge?.copyWith(
                                    color: context.colors.textHint,
                                    fontFamily: FontFamily.roboto,
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.colors.textHint,
                                ),
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.fieldRadius,
                                    ),
                                    borderSide: BorderSide(
                                      color: context.colors.borderOutline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.fieldRadius,
                                    ),
                                    borderSide: BorderSide(
                                      color: context.colors.borderOutline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.fieldRadius,
                                    ),
                                    borderSide: BorderSide(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ),
                                items: _countries
                                    .map(
                                      (c) => DropdownMenuItem<Country>(
                                        value: c,
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (c) =>
                                    setState(() => _selectedCountry = c),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 32),

                
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organisation Logo',
                              style: context.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Center(
                              child: OrganizationLogo(
                                logoUrl: _isImageRemoved ? '' : widget.organization.logoUrl,
                                logoFile: _pickedImage,
                                name: widget.organization.name,
                                size: 100,
                                borderRadius: 8,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.upload_outlined,
                                        size: 16,
                                        color: context.colors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Text(
                                          'Upload photo',
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                            color: context.colors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_pickedImage != null ||
                                      (!_isImageRemoved &&
                                          widget.organization.logoUrl.isNotEmpty)) ...[
                                    const SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: _removeImage,
                                      child: Text(
                                        'Remove photo',
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: context.colors.error,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer buttons ──────────────────────────────────────────
              Divider(color: context.colors.divider, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outlined(
                    label: 'Cancel',
                    expand: false,
                    height: 44,
                    onPressed: state.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Save Changes',
                    expand: false,
                    height: 44,
                    loading: state.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
