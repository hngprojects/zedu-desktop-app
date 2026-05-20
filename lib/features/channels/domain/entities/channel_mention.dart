class ChannelMention {
  const ChannelMention({required this.type, required this.id});

  final String type;
  final String id;

  Map<String, dynamic> toJson() => {'type': type, 'id': id};
}
