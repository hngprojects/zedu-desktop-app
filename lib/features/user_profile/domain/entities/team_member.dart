enum TeamMemberStatus { active, pending, inactive }

class TeamMember {
  const TeamMember({
    required this.id,
    required this.email,
    required this.role,
    required this.dateJoined,
    required this.status,
  });

  final String id;
  final String email;
  final String role;
  final String dateJoined;
  final TeamMemberStatus status;

  TeamMember copyWith({
    String? id,
    String? email,
    String? role,
    String? dateJoined,
    TeamMemberStatus? status,
  }) {
    return TeamMember(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      dateJoined: dateJoined ?? this.dateJoined,
      status: status ?? this.status,
    );
  }
}
