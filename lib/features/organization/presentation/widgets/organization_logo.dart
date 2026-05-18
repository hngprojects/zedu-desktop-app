import 'dart:io';

import 'package:zedu/core/core.dart';

class OrganizationLogo extends StatelessWidget {
  const OrganizationLogo({
    super.key,
    required this.logoUrl,
    required this.name,
    this.logoFile,
    this.size = 72,
    this.borderRadius = 6,
  });

  final String logoUrl;
  final String name;
  final XFile? logoFile;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (logoFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(logoFile!.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (logoUrl.isNotEmpty) {
      if (logoUrl.startsWith('http') || logoUrl.startsWith('https')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.network(
            logoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(context),
          ),
        );
      } else {
        final file = File(logoUrl);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
      }
    }

    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.colors.borderOutline),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
