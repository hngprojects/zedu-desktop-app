import re

def replace_endpoints(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    for old, new in replacements:
        content = content.replace(old, new)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

user_profile_replacements = [
    ("path: '/profile/organization'", "path: ApiEndpoints.profileOrganization"),
    ("path: '/profile/organization/roles'", "path: ApiEndpoints.organizationRoles"),
    ("path: '/profile/organization/billing'", "path: ApiEndpoints.organizationBilling"),
    ("path: '/organisations/$orgId/users'", "path: ApiEndpoints.organizationUsers(orgId)"),
    ("path: '/invite'", "path: ApiEndpoints.invite"),
    ("path: '/profile/organization/members/${member.id}'", "path: ApiEndpoints.organizationMember(member.id)"),
    ("path: '/profile/organization/members/$memberId'", "path: ApiEndpoints.organizationMember(memberId)"),
]

dm_replacements = [
    ("path: '/organisations/$orgId/dms'", "path: ApiEndpoints.organizationDms(orgId)"),
    ("path: '/channels/$channelId/messages'", "path: ApiEndpoints.channelMessages(channelId)"),
    ("path: '/dms/messages/$channelId'", "path: ApiEndpoints.dmsMessages(channelId)"),
]

replace_endpoints(r'lib\features\user_profile\data\datasource\user_profile_remote_datasource.dart', user_profile_replacements)
replace_endpoints(r'lib\features\dms\data\dm_repository.dart', dm_replacements)
