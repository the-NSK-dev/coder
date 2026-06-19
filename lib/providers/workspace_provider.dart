import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../config/markdown_config.dart';
import '../models/project.dart';
import '../models/project_folder.dart';
import '../models/workspace.dart';
import '../services/workspace_service.dart';
import '../services/project_file_service.dart';
import '../services/persistence_service.dart';

/// Manages workspace state: current project, folder tree, project switching.
class WorkspaceProvider extends ChangeNotifier {
  final WorkspaceService _workspaceService = WorkspaceService();
  final ProjectFileService _projectFileService = ProjectFileService();
  final PersistenceService _persistence = PersistenceService();

  Workspace _workspace = Workspace();
  ProjectFolder? _projectTree;
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _recentProjects = [];
  VoidCallback? onProjectLoaded;

  // ── Getters ─────────────────────────────────────────────
  Workspace get workspace => _workspace;
  Project? get currentProject => _workspace.currentProject;
  ProjectFolder? get projectTree => _projectTree;
  bool get isLoading => _isLoading;
  bool get hasProject => _workspace.currentProject != null;
  String? get errorMessage => _errorMessage;
  String? get currentProjectPath => AppConfig.currentProjectDir;
  List<Map<String, String>> get recentProjects => _recentProjects;

  String get primaryLanguage => _detectPrimaryLanguage();
  bool get isSupportedLanguage => AppConfig.supportedLanguages.contains(primaryLanguage);

  // ── Ignored directories/files during indexing ───────────
  static const _ignoreDirs = {
    '.git', 'node_modules', 'build', '.dart_tool',
    '.idea', '.vscode', '__pycache__', '.gradle',
    'dist', '.next', '.cache', 'coverage',
  };

  static const _ignoreFiles = {
    '.DS_Store', 'Thumbs.db', '.gitkeep',
  };

  // ── Initialize — restore last project on startup ────────
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentProjects = await _persistence.getRecentProjects();

      final lastPath = await _persistence.getLastProjectPath();
      if (lastPath != null && lastPath.isNotEmpty) {
        if (!kIsWeb) {
          final dir = Directory(lastPath);
          if (await dir.exists()) {
            await _loadProject(lastPath);
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('WorkspaceProvider.initialize error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Open Local Folder ───────────────────────────────────
  Future<bool> openLocalFolder() async {
    if (kIsWeb) {
      _errorMessage =
          'Local folder access requires the desktop app. Try the sample project instead.';
      notifyListeners();
      return false;
    }

    try {
      final path = await FilePicker.getDirectoryPath();
      if (path == null) return false; // User cancelled

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _loadProject(path);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not open folder: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Load Sample Project ─────────────────────────────────
  Future<bool> loadSampleProject() async {
    if (kIsWeb) {
      _errorMessage =
          'Sample projects require the desktop app for full filesystem support.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supportDir = await getApplicationSupportDirectory();
      final projectPath =
          await _projectFileService.generateTestProject(supportDir.path);

      await _loadProject(projectPath);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not generate sample project: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Switch to a different project ───────────────────────
  Future<bool> switchProject(String path) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadProject(path);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not switch project: $e';
      notifyListeners();
      return false;
    }
  }

  // ── File Operations (delegated) ─────────────────────────
  Future<void> createFile(String filePath) async {
    await _projectFileService.createFile(filePath);
    await refreshTree();
  }

  Future<void> createFolder(String folderPath) async {
    await _projectFileService.createFolder(folderPath);
    await refreshTree();
  }

  Future<void> deleteItem(String path, bool isDirectory) async {
    await _projectFileService.deleteItem(path, isDirectory);
    await refreshTree();
  }

  Future<void> renameItem(String oldPath, String newPath, bool isDirectory) async {
    await _projectFileService.renameItem(oldPath, newPath, isDirectory);
    await refreshTree();
  }

  Future<void> moveItem(String oldPath, String newPath, bool isDirectory) async {
    await _projectFileService.renameItem(oldPath, newPath, isDirectory);
    await refreshTree();
  }

  Future<String> readFile(String filePath) async {
    return await _projectFileService.readFile(filePath);
  }

  Future<void> saveFile(String filePath, String content) async {
    await _projectFileService.updateFile(filePath, content);
  }

  /// Search for files by name in the current workspace.
  List<String> searchFiles(String query) {
    if (_projectTree == null || query.isEmpty) return [];
    final results = <String>[];
    _searchInFolder(_projectTree!, query.toLowerCase(), results);
    return results;
  }

  void _searchInFolder(ProjectFolder folder, String query, List<String> results) {
    for (final file in folder.files) {
      if (file.name.toLowerCase().contains(query)) {
        results.add(file.path);
      }
    }
    for (final sub in folder.subfolders) {
      _searchInFolder(sub, query, results);
    }
  }

  // ── Refresh folder tree ─────────────────────────────────
  Future<void> refreshTree() async {
    final path = AppConfig.currentProjectDir;
    if (path == null || kIsWeb) return;

    try {
      final project = await _workspaceService.openProject(path);
      _projectTree = _filterTree(project.rootFolder);
      _workspace = Workspace(
        currentProject: project,
        recentProjects: _workspace.recentProjects,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh tree error: $e');
    }
  }

  // ── Internal helpers ────────────────────────────────────
  Future<void> _loadProject(String path) async {
    AppConfig.currentProjectDir = path;

    final project = await _workspaceService.openProject(path);
    _projectTree = _filterTree(project.rootFolder);

    _workspace = Workspace(
      currentProject: project,
      recentProjects: _workspace.recentProjects,
    );

    // Persist
    await _persistence.saveLastProjectPath(path);
    await _persistence.addRecentProject(project.name, path);
    _recentProjects = await _persistence.getRecentProjects();

    // Auto-select .md files for verification
    final mdFiles = searchFiles('.md');
    MarkdownConfig.userMarkdownFiles.clear();
    for (final mdFile in mdFiles) {
      if (mdFile.toLowerCase().endsWith('.md')) {
        MarkdownConfig.userMarkdownFiles.add(mdFile);
      }
    }

    onProjectLoaded?.call();
  }

  /// Recursively filter out ignored directories and files.
  ProjectFolder _filterTree(ProjectFolder folder) {
    final filteredFiles = folder.files
        .where((f) => !_ignoreFiles.contains(f.name))
        .toList();

    final filteredFolders = folder.subfolders
        .where((d) => !_ignoreDirs.contains(d.name))
        .map((d) => _filterTree(d))
        .toList();

    return ProjectFolder(
      name: folder.name,
      path: folder.path,
      files: filteredFiles,
      subfolders: filteredFolders,
    );
  }

  // ── Language Detection ────────────────────────────────────
  String _detectPrimaryLanguage() {
    if (_projectTree == null) return 'unknown';
    
    final counts = <String, int>{};
    void countExt(ProjectFolder folder) {
      for (final f in folder.files) {
        final parts = f.name.split('.');
        if (parts.length > 1) {
          final ext = parts.last.toLowerCase();
          String? lang;
          switch (ext) {
            case 'dart': lang = 'dart'; break;
            case 'js': case 'jsx': lang = 'javascript'; break;
            case 'ts': case 'tsx': lang = 'typescript'; break;
            case 'py': lang = 'python'; break;
            case 'html': lang = 'html'; break;
            case 'css': lang = 'css'; break;
            case 'java': lang = 'java'; break;
            case 'cpp': case 'cc': case 'cxx': case 'h': case 'hpp': lang = 'cpp'; break;
          }
          if (lang != null) {
            counts[lang] = (counts[lang] ?? 0) + 1;
          }
        }
      }
      for (final sub in folder.subfolders) {
        countExt(sub);
      }
    }
    countExt(_projectTree!);
    
    if (counts.isEmpty) return 'unknown';
    
    var maxLang = 'unknown';
    var maxCount = 0;
    counts.forEach((lang, count) {
      if (count > maxCount) {
        maxCount = count;
        maxLang = lang;
      }
    });
    return maxLang;
  }

  // ── Clear state ─────────────────────────────────────────
  void clearProject() {
    _workspace = Workspace();
    _projectTree = null;
    AppConfig.currentProjectDir = null;
    notifyListeners();
  }
}
