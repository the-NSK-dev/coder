import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/file_item.dart';
import '../models/code_result.dart';
import '../models/workspace.dart';
import '../services/aiml_api_service.dart';
import '../services/band_ai_service.dart';
import '../services/workspace_service.dart';
import '../services/project_file_service.dart';
import '../services/github_service.dart';

/// Manages IDE-level state: workspace, file operations, GitHub push.
class IdeProvider extends ChangeNotifier {
  final AimlApiService aimlApi = AimlApiService();
  final BandAIService bandAi = BandAIService();
  final WorkspaceService workspaceService = WorkspaceService();
  final ProjectFileService projectFileService = ProjectFileService();
  final GithubService githubService = GithubService();

  Workspace workspace = Workspace();
  bool isProcessing = false;

  IdeProvider() {
    _initServices();
  }

  void _initServices() {
    try {
      bandAi.initialize(AppConfig.bandUserApiKey);
      aimlApi.initialize(AppConfig.aimlApiKey);
      githubService.updateCredentials(
        AppConfig.githubToken,
        AppConfig.githubUsername,
      );
    } catch (_) {}
  }

  void reloadConfig() {
    _initServices();
    notifyListeners();
  }

  Future<void> saveGeneratedFiles(List<FileItem> files) async {
    try {
      if (AppConfig.currentProjectDir != null &&
          AppConfig.currentProjectDir!.isNotEmpty) {
        await projectFileService.saveGeneratedFiles(
            AppConfig.currentProjectDir!, files);
        final proj = await workspaceService.createProject(
            'Current Project', AppConfig.currentProjectDir!);
        workspace = Workspace(currentProject: proj);
      }
    } catch (e) {
      debugPrint('Failed to save generated files: $e');
      workspace = Workspace();
    }
    notifyListeners();
  }

  Future<bool> pushToGithub(CodeResult? codeResult) async {
    if (codeResult == null) return false;
    isProcessing = true;
    notifyListeners();
    final success = await githubService.pushProject(codeResult);
    isProcessing = false;
    notifyListeners();
    return success;
  }
}
