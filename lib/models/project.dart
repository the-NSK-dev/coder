import 'project_folder.dart';

class Project {
  final String id;
  final String name;
  final String path;
  final String version;
  final DateTime createdAt;
  final DateTime lastModified;
  final ProjectFolder rootFolder;

  Project({
    required this.id,
    required this.name,
    required this.path,
    required this.version,
    required this.createdAt,
    required this.lastModified,
    required this.rootFolder,
  });
}
