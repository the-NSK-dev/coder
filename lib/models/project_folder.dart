import 'project_file.dart';

class ProjectFolder {
  final String name;
  final String path;
  final List<ProjectFolder> subfolders;
  final List<ProjectFile> files;

  ProjectFolder({
    required this.name,
    required this.path,
    this.subfolders = const [],
    this.files = const [],
  });
}
