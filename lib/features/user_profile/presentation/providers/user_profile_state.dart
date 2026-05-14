import 'package:zedu/features/features.dart';

enum UserProfileSection {
  account,
  notifications,
  security,
  organization,
  userManagement,
}

class UserProfileState {
  const UserProfileState({
    this.section = UserProfileSection.account,
    this.account,
    this.notifications,
    this.organization,
    this.securitySessions = const [],
    this.teamMembers = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final UserProfileSection section;
  final ProfileAccount? account;
  final NotificationPreferences? notifications;
  final OrganizationProfile? organization;
  final List<SecuritySession> securitySessions;
  final List<TeamMember> teamMembers;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  UserProfileState copyWith({
    UserProfileSection? section,
    ProfileAccount? account,
    NotificationPreferences? notifications,
    OrganizationProfile? organization,
    List<SecuritySession>? securitySessions,
    List<TeamMember>? teamMembers,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return UserProfileState(
      section: section ?? this.section,
      account: account ?? this.account,
      notifications: notifications ?? this.notifications,
      organization: organization ?? this.organization,
      securitySessions: securitySessions ?? this.securitySessions,
      teamMembers: teamMembers ?? this.teamMembers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
