import 'dart:io';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Shows a confirmation dialog and calls [onConfirm] if user agrees.
Future<void> showProfileConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function() onConfirm,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(message, style: context.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: confirmLabel,
          expand: false,
          height: 40,
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? const Color(0xFFEF4444) : null,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (confirmed == true) await onConfirm();
}

/// Dialog for editing account information.
Future<void> showEditAccountDialog(
  BuildContext context,
  ProfileAccount account,
  ValueChanged<ProfileAccount> onSave,
) async {
  final nameCtrl = TextEditingController(text: account.name);
  final emailCtrl = TextEditingController(text: account.email);
  final timezoneCtrl = TextEditingController(text: account.timezone);
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Edit Account',
        style: ctx.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Name',
                controller: nameCtrl,
                hint: 'Enter your full name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                controller: emailCtrl,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Timezone',
                controller: timezoneCtrl,
                hint: 'e.g. Africa/Lagos',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save changes',
          expand: false,
          height: 40,
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              onSave(
                account.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  timezone: timezoneCtrl.text.trim(),
                ),
              );
              Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );

  nameCtrl.dispose();
  emailCtrl.dispose();
  timezoneCtrl.dispose();
}

/// Dialog for changing password.
Future<void> showChangePasswordDialog(
  BuildContext context,
  Future<bool> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSave,
) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: !isLoading,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Change Password',
          style: ctx.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Current Password',
                  controller: currentCtrl,
                  hint: 'Enter current password',
                  isPassword: true,
                  readOnly: isLoading,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New Password',
                  controller: newCtrl,
                  hint: 'Enter new password',
                  isPassword: true,
                  readOnly: isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: confirmCtrl,
                  hint: 'Re-enter new password',
                  isPassword: true,
                  readOnly: isLoading,
                  validator: (v) =>
                      v != newCtrl.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Update Password',
            expand: false,
            height: 40,
            loading: isLoading,
            onPressed: isLoading
                ? null
                : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      setState(() => isLoading = true);
                      final success = await onSave(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      if (ctx.mounted) {
                        setState(() => isLoading = false);
                        if (success) {
                          Navigator.pop(ctx);
                        }
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );

  currentCtrl.dispose();
  newCtrl.dispose();
  confirmCtrl.dispose();
}

Future<void> showEditOrganizationDialog(
  BuildContext context,
  OrganizationProfile organization,
  ValueChanged<OrganizationProfile> onSave,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) =>
        _EditOrganizationDialog(organization: organization, onSave: onSave),
  );
}

class _EditOrganizationDialog extends ConsumerStatefulWidget {
  const _EditOrganizationDialog({
    required this.organization,
    required this.onSave,
  });

  final OrganizationProfile organization;
  final ValueChanged<OrganizationProfile> onSave;

  @override
  ConsumerState<_EditOrganizationDialog> createState() =>
      _EditOrganizationDialogState();
}

class _EditOrganizationDialogState
    extends ConsumerState<_EditOrganizationDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController businessCtrl;
  late final TextEditingController countryCtrl;
  late final FocusNode countryFocusNode;
  final formKey = GlobalKey<FormState>();

  String? localImagePath;
  String? remoteImageUrl;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.organization.name);
    businessCtrl = TextEditingController(
      text: widget.organization.natureOfBusiness,
    );
    countryCtrl = TextEditingController(text: widget.organization.country);
    countryFocusNode = FocusNode();
    remoteImageUrl = widget.organization.logoUrl;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    businessCtrl.dispose();
    countryCtrl.dispose();
    countryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        localImagePath = path;
        isUploading = true;
      });

      try {
        final xfile = XFile(path);
        final fileRepo = ref.read(fileRepositoryProvider);
        final uploadedFiles = await fileRepo.uploadFiles([xfile]);
        if (uploadedFiles.isNotEmpty) {
          final fileUrl =
              uploadedFiles.first['file_url'] as String? ??
              uploadedFiles.first['url'] as String? ??
              uploadedFiles.first['file_link'] as String?;

          if (fileUrl != null && mounted) {
            setState(() {
              remoteImageUrl = fileUrl;
              isUploading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isUploading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload logo: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Update organisation details',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 600,
        child: Form(
          key: formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Organisation Name',
                      controller: nameCtrl,
                      hint: 'Enter organisation name',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Nature of Business',
                      controller: businessCtrl,
                      hint: 'e.g. Design agency',
                    ),
                    const SizedBox(height: 16),
                    ProfileFieldLabel('Country'),
                    const SizedBox(height: 6),
                    RawAutocomplete<String>(
                      textEditingController: countryCtrl,
                      focusNode: countryFocusNode,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) return kCountries;
                        return kCountries.where(
                          (country) => country.toLowerCase().contains(query),
                        );
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Search country',
                                suffixIcon: const Icon(Icons.expand_more),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              validator: (value) {
                                final country = value?.trim() ?? '';
                                if (country.isEmpty) {
                                  return 'Country is required';
                                }
                                if (!kCountries.contains(country)) {
                                  return 'Select a country from the list';
                                }
                                return null;
                              },
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 240,
                                maxWidth: 340,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Organisation Logo',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : (localImagePath != null
                                ? Image.file(
                                    File(localImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : (remoteImageUrl != null &&
                                          remoteImageUrl!.isNotEmpty
                                      ? Image.network(
                                          remoteImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(Icons.error),
                                        )
                                      : Center(
                                          child: Text(
                                            widget.organization.initials,
                                            style: context
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ))),
                    ),
                    const SizedBox(height: 16),
                    AppButton.outlined(
                      label: 'Upload photo',
                      onPressed: _pickAvatar,
                      expand: true,
                    ),
                    if (localImagePath != null ||
                        (remoteImageUrl != null && remoteImageUrl!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              localImagePath = null;
                              remoteImageUrl = '';
                            });
                          },
                          child: Text(
                            'Remove photo',
                            style: TextStyle(color: colors.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save Changes',
          expand: false,
          height: 40,
          loading: isUploading,
          onPressed: isUploading
              ? null
              : () {
                  if (formKey.currentState?.validate() ?? false) {
                    widget.onSave(
                      widget.organization.copyWith(
                        name: nameCtrl.text.trim(),
                        natureOfBusiness: businessCtrl.text.trim(),
                        country: countryCtrl.text.trim(),
                        logoUrl: remoteImageUrl,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
        ),
      ],
    );
  }
}

/// Dialog for inviting a team member.
Future<void> showInviteMemberDialog(
  BuildContext context,
  Future<void> Function({required String email, required String role}) onInvite,
) async {
  final emailCtrl = TextEditingController();
  String role = 'User';
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Invite Team Member',
          style: ctx.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Email Address',
                  controller: emailCtrl,
                  hint: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ProfileFieldLabel('Role'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Administrator',
                      child: Text('Administrator'),
                    ),
                    DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'User', child: Text('User')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v ?? 'User'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Send Invite',
            expand: false,
            height: 40,
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                await onInvite(email: emailCtrl.text.trim(), role: role);
              }
            },
          ),
        ],
      ),
    ),
  );

  emailCtrl.dispose();
}

/// Dialog for editing a team member's role.
Future<void> showEditMemberDialog(
  BuildContext context,
  TeamMember member,
  ValueChanged<TeamMember> onUpdate,
) async {
  String role = member.role;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Team Member',
          style: ctx.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.email,
                style: ctx.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ProfileFieldLabel('Role'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Administrator',
                    child: Text('Administrator'),
                  ),
                  DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'User', child: Text('User')),
                ],
                onChanged: (v) => setDialogState(() => role = v ?? member.role),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Save changes',
            expand: false,
            height: 40,
            onPressed: () {
              onUpdate(member.copyWith(role: role));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}
