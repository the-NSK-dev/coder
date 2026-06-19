import 'dart:io';

enum PreviewProjectType {
  staticHtml,
  npmDev,
  unknown,
}

/// Detects how a project should be previewed.
class PreviewDetector {
  Future<PreviewProjectType> detect(String projectPath) async {
    final dir = Directory(projectPath);
    if (!await dir.exists()) return PreviewProjectType.unknown;

    final packageJson = File('$projectPath${Platform.pathSeparator}package.json');
    if (await packageJson.exists()) {
      return PreviewProjectType.npmDev;
    }

    final indexHtml = File('$projectPath${Platform.pathSeparator}index.html');
    if (await indexHtml.exists()) {
      return PreviewProjectType.staticHtml;
    }

    // Search for index.html in subdirs (e.g. public/)
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('index.html')) {
        return PreviewProjectType.staticHtml;
      }
    }

    return PreviewProjectType.unknown;
  }

  /// Returns the directory to serve statically (project root or subfolder with index.html).
  Future<String> staticServePath(String projectPath) async {
    final indexAtRoot = File('$projectPath${Platform.pathSeparator}index.html');
    if (await indexAtRoot.exists()) return projectPath;

    final dir = Directory(projectPath);
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.toLowerCase().endsWith('index.html')) {
        return entity.parent.path;
      }
    }
    return projectPath;
  }
}
