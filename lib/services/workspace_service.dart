import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/project_folder.dart';
import '../models/project_file.dart';

class WorkspaceService {
  /// Create a new project folder
  Future<Project> createProject(String name, String parentPath) async {
    if (kIsWeb) {
      throw UnsupportedError('File system operations are not supported on the Web.');
    }
    
    final sanitizedName = name.toLowerCase().replaceAll(' ', '-');
    final dir = Directory('$parentPath/$sanitizedName');
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final rootFolder = ProjectFolder(
      name: sanitizedName,
      path: dir.path,
    );

    return Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      path: dir.path,
      version: 'v1.0',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      rootFolder: rootFolder,
    );
  }

  /// Open an existing project
  Future<Project> openProject(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('File system operations are not supported on the Web.');
    }
    
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception('Directory does not exist');
    }
    
    final rootFolder = await _buildFolderTree(dir);
    
    return Project(
      id: dir.path.hashCode.toString(),
      name: dir.path.split(Platform.pathSeparator).last,
      path: dir.path,
      version: 'v1.0',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      rootFolder: rootFolder,
    );
  }

  Future<ProjectFolder> _buildFolderTree(Directory dir) async {
    final List<ProjectFolder> subfolders = [];
    final List<ProjectFile> files = [];

    await for (final entity in dir.list()) {
      if (entity is Directory) {
        subfolders.add(await _buildFolderTree(entity));
      } else if (entity is File) {
        final stat = await entity.stat();
        final content = await entity.readAsString();
        files.add(ProjectFile(
          name: entity.path.split(Platform.pathSeparator).last,
          path: entity.path,
          extension: entity.path.split('.').last,
          content: content,
          lastModified: stat.modified,
        ));
      }
    }

    return ProjectFolder(
      name: dir.path.split(Platform.pathSeparator).last,
      path: dir.path,
      subfolders: subfolders,
      files: files,
    );
  }
}
