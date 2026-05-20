class ChannelMedia {
  const ChannelMedia({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileLink,
  });

  final String id;
  final String fileName;
  final String fileType;
  final String fileLink;

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'file_type': fileType,
    'file_link': fileLink,
  };
}
