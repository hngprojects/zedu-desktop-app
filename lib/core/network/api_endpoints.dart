class ApiEndpoints {
  // --- User Profile ---
  static const String updateProfile = '/profile';
  static String getProfile(String userId) => '/profile/$userId';
  static const String deleteProfileImage = '/profile/image';
  
  // Replace this link anytime you get the exact swagger doc for image upload
  static const String uploadProfileImage = '/profile/image'; 

  static const String uploadFiles = '/files/upload-files';
  
  static const String getAccount = '/profile/account';
  static const String updateAccount = '/profile';
  static const String deleteAccount = '/profile/account';
  
  static const String profileNotifications = '/profile/notifications';
  static const String securitySessions = '/profile/security/sessions';
  static const String securityPassword = '/profile/security/password';
  static const String profileOrganization = '/profile/organization';
  static const String organisations = '/organisations';
  static String organization(String orgId) => '/organisations/$orgId';
  static String organizationUsers(String orgId) => '/organisations/$orgId/users';
  static const String invite = '/invite';
  static String organizationMember(String memberId) => '/profile/organization/members/$memberId';
  static const String organizationRoles = '/profile/organization/roles';
  static const String organizationBilling = '/profile/organization/billing';

  // --- DMS ---
  static String organizationDms(String orgId) => '/organisations/$orgId/dms';
  static String channelMessages(String channelId) => '/channels/$channelId/messages';
  static String dmsMessages(String channelId) => '/dms/messages/$channelId';
}
