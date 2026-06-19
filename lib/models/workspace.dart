import 'project.dart';

class Workspace {
  final List<Project> recentProjects;
  final Project? currentProject;

  Workspace({
    this.recentProjects = const [],
    this.currentProject,
  });
}
