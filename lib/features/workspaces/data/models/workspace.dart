class Workspace {
  final String id;
  final String name;
  final String avatar;
  final int unreadCount;
  final int membersCount;
  final String? ownerId;

  const Workspace({
    required this.id,
    required this.name,
    required this.avatar,
    this.unreadCount = 0,
    this.membersCount = 0,
    this.ownerId,
  });

  Workspace copyWith({
    String? id,
    String? name,
    String? avatar,
    int? unreadCount,
    int? membersCount,
    String? ownerId,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      unreadCount: unreadCount ?? this.unreadCount,
      membersCount: membersCount ?? this.membersCount,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
