class ApiEndpoints {
  // --- User Profile ---
  static const String updateProfile = '/profile';
  static String getProfile(String userId) => '/profile/$userId';
  static const String deleteProfileImage = '/profile/image';

  static const String uploadFiles = '/files/upload-files';

  static const String getAccount = '/profile';
  static const String updateAccount = '/profile';
  static const String deleteAccount = '/profile/account';

  static const String profileNotifications = '/users/notification-preferences';
  static String securitySessions(String userId) => '/users/$userId/login-audit';
  static const String securityPassword = '/auth/change-password';
  static const String profileOrganization = '/users/organisations';
  static const String organisations = '/organisations';
  static String organization(String orgId) => '/organisations/$orgId';
  static String organizationUsers(String orgId) =>
      '/organisations/$orgId/users';
  static const String invite = '/invite';
  static String organizationMember(String memberId) =>
      '/profile/organization/members/$memberId';
  static String organizationRoles(String orgId) =>
      '/organisations/$orgId/roles';
  static const String organizationBilling = '/profile/organization/billing';

  // --- DMS ---
  static String organizationDms(String orgId) => '/organisations/$orgId/dms';
  static String channelMessages(String channelId) =>
      '/channels/$channelId/messages';
  static String dmsMessages(String channelId) =>
      '/dms/channels/$channelId/threads';

  // --- Buzz (Group Video/Voice Calls) ---
  static const String createOrgBuzz = '/buzz/org/create';
  static const String getOrgBuzzList = '/buzz/org';
  static const String searchBuzzMembers = '/buzz/search-members';
  static const String inviteUsersToBuzz = '/buzz/invite';
  static const String respondBuzzInvitation = '/buzz/invitation/respond';
  static const String getPendingBuzzInvitations = '/buzz/invitations/pending';
  static const String getBuzzToken = '/buzz/token';
  static String joinBuzz(String buzzId) => '/buzz/$buzzId/join';
  static String endBuzz(String buzzId) => '/buzz/$buzzId/end';
  static String endBuzzByChannel(String channelId) =>
      '/buzz/channel/$channelId/end';
  // Legacy — used only by DM direct-call flow (BuzzRepository)
  static String joinBuzzByCode(String codeOrId) => '/buzz/$codeOrId/join';
}
