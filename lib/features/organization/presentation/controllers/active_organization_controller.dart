import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class ActiveOrganizationNotifier extends Notifier<Organization?> {
  @override
  Organization? build() => null;
  set active(Organization? org) => state = org;
}