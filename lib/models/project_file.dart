class ProjectFile {
  final String name;
  final String path;
  final String extension;
  final String content;
  final DateTime lastModified;

  ProjectFile({
    required this.name,
    required this.path,
    required this.extension,
    required this.content,
    required this.lastModified,
  });
}
