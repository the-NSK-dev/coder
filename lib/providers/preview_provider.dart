import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/preview_builder.dart';
import '../services/local_preview_server.dart';
import '../services/preview_detector.dart';
import '../services/process_runner_service.dart';
import '../models/code_result.dart';
import '../models/plan_result.dart';

/// Manages live preview state: URL, mode, refresh, and local server lifecycle.
class PreviewProvider extends ChangeNotifier {
  final PreviewBuilder _previewBuilder = PreviewBuilder();
  final LocalPreviewServer _previewServer = LocalPreviewServer();
  final PreviewDetector _detector = PreviewDetector();
  final ProcessRunnerService _processRunner = ProcessRunnerService();

  String? _previewUrl;
  bool _isLoading = false;
  bool _isFullscreen = false;
  bool _isSideBySide = true;
  String? _errorMessage;
  bool _serverRunning = false;
  PreviewProjectType _projectType = PreviewProjectType.unknown;

  String? get previewUrl => _previewUrl;
  bool get isLoading => _isLoading;
  bool get isFullscreen => _isFullscreen;
  bool get isSideBySide => _isSideBySide;
  String? get errorMessage => _errorMessage;
  bool get serverRunning => _serverRunning;
  bool get hasPreview => _previewUrl != null;
  PreviewProjectType get projectType => _projectType;

  Future<void> startPreview(String projectPath) async {
    if (kIsWeb) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      try {
        final html = await _previewBuilder.buildPreview(projectPath);
        _previewUrl = 'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _isLoading = false;
        _errorMessage = 'Could not build preview: $e';
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dir = Directory(projectPath);
      if (!await dir.exists()) {
        throw Exception('Project directory not found');
      }

      _projectType = await _detector.detect(projectPath);

      switch (_projectType) {
        case PreviewProjectType.npmDev:
          await _startNpmDevServer(projectPath);
          break;
        case PreviewProjectType.staticHtml:
          final servePath = await _detector.staticServePath(projectPath);
          await _previewServer.start(servePath);
          _serverRunning = true;
          _previewUrl = _previewServer.url;
          break;
        case PreviewProjectType.unknown:
          final html = await _previewBuilder.buildPreview(projectPath);
          await _previewServer.start(projectPath, port: 8765);
          _serverRunning = true;
          _previewUrl = _previewServer.url;
          if (!await _hasIndexAt(projectPath)) {
            // Fallback: inline HTML if no index found
            _previewUrl =
                'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
            await _previewServer.stop();
            _serverRunning = false;
          }
          break;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not start preview: $e';
      notifyListeners();
    }
  }

  void startPreviewFromMemory(CodeResult code, PlanResult plan) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final html = PreviewBuilder.build(code, plan);
      _previewUrl = 'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
      _serverRunning = false;
    } catch (e) {
      _errorMessage = 'Could not build preview: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _hasIndexAt(String path) async {
    return await File('$path${Platform.pathSeparator}index.html').exists();
  }

  Future<void> _startNpmDevServer(String projectPath) async {
    if (Platform.isWindows) {
      await _processRunner.runCommand('npm.cmd install', projectPath);
      final output = await _processRunner.runCommand(
        'npm.cmd run dev',
        projectPath,
        timeoutSeconds: 30,
      );
      final port = _extractPort(output) ?? 3000;
      _previewUrl = 'http://localhost:$port';
      _serverRunning = true;
    } else {
      await _processRunner.runCommand('npm install', projectPath);
      final output = await _processRunner.runCommand(
        'npm run dev',
        projectPath,
        timeoutSeconds: 30,
      );
      final port = _extractPort(output) ?? 3000;
      _previewUrl = 'http://localhost:$port';
      _serverRunning = true;
    }
  }

  int? _extractPort(String output) {
    final patterns = [
      RegExp(r'localhost:(\d+)'),
      RegExp(r'127\.0\.0\.1:(\d+)'),
      RegExp(r'port\s+(\d+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(output);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  Future<void> refreshPreview(String projectPath) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        final html = await _previewBuilder.buildPreview(projectPath);
        _previewUrl =
            'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
      } else if (_projectType == PreviewProjectType.staticHtml ||
          _projectType == PreviewProjectType.unknown) {
        if (_serverRunning) {
          await _previewServer.stop();
        }
        final servePath = await _detector.staticServePath(projectPath);
        await _previewServer.start(servePath);
        _serverRunning = true;
        _previewUrl =
            '${_previewServer.url}?t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _previewUrl =
            '${_previewUrl?.split('?').first}?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      _errorMessage = 'Refresh failed: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  void toggleSideBySide() {
    _isSideBySide = !_isSideBySide;
    notifyListeners();
  }

  void setFullscreen(bool fullscreen) {
    _isFullscreen = fullscreen;
    notifyListeners();
  }

  Future<void> stopPreview() async {
    await _processRunner.stop();
    if (_serverRunning) {
      await _previewServer.stop();
      _serverRunning = false;
    }
    _previewUrl = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPreview();
    super.dispose();
  }
}
