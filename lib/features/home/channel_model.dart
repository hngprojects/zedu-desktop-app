enum ChannelVisibility { public, private }

enum ChannelCategory { general, classGroup, team }

class WorkspaceChannel {
  const WorkspaceChannel({
    required this.name,
    required this.visibility,
    required this.category,
    this.id,
    this.description = '',
    this.topic = '',
    this.membersCount = 1,
  });

  final String? id;
  final String name;
  final String description;
  final String topic;
  final ChannelVisibility visibility;
  final ChannelCategory category;
  final int membersCount;

  bool get isPrivate => visibility == ChannelVisibility.private;

  WorkspaceChannel copyWith({
    String? id,
    String? name,
    String? description,
    String? topic,
    ChannelVisibility? visibility,
    ChannelCategory? category,
    int? membersCount,
  }) {
    return WorkspaceChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      topic: topic ?? this.topic,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      membersCount: membersCount ?? this.membersCount,
    );
  }

  factory WorkspaceChannel.fromJson(Map<String, dynamic> json) {
    return WorkspaceChannel(
      id: json['channels_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      visibility: (json['is_private'] as bool? ?? false)
          ? ChannelVisibility.private
          : ChannelVisibility.public,
      category: ChannelCategory.general,
      membersCount: json['user_count'] as int? ?? 1,
    );
  }
}
