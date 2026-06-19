import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/github_service.dart';
import '../services/persistence_service.dart';
import '../models/code_result.dart';

/// Manages GitHub integration state: authentication, repo selection, push workflow.
class GitHubProvider extends ChangeNotifier {
  final GithubService _githubService = GithubService();
  final PersistenceService _persistence = PersistenceService();

  String _token = '';
  String _username = '';
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isPushing = false;
  double _pushProgress = 0.0;
  String? _errorMessage;
  String? _selectedRepoSlug;
  String? _lastPushUrl;
  int? _followers;
  int? _following;
  String? _avatarUrl;
  String? _createdAt;
  int? _orgsCount;
  int? _starredCount;
  int? _publicRepos;
  int? _totalPrivateRepos;
  List<Map<String, String>> _repos = [];

  // ── Getters ─────────────────────────────────────────────
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isPushing => _isPushing;
  double get pushProgress => _pushProgress;
  String? get errorMessage => _errorMessage;
  String get username => _username;
  String? get selectedRepoSlug => _selectedRepoSlug;
  String? get lastPushUrl => _lastPushUrl;
  int? get followers => _followers;
  int? get following => _following;
  String? get avatarUrl => _avatarUrl;
  String? get createdAt => _createdAt;
  int? get orgsCount => _orgsCount;
  int? get starredCount => _starredCount;
  int? get publicRepos => _publicRepos;
  int? get totalPrivateRepos => _totalPrivateRepos;
  List<Map<String, String>> get repos => _repos;

  // ── Initialize — restore saved credentials ──────────────
  Future<void> initialize() async {
    try {
      final creds = await _persistence.getGithubCredentials();
      _token = creds['token'] ?? '';
      _username = creds['username'] ?? '';

      if (_token.isEmpty) {
        _token = AppConfig.githubToken;
        _username = AppConfig.githubUsername;
      }

      _isConnected = _token.isNotEmpty && _username.isNotEmpty;
      if (_isConnected) {
        AppConfig.applySettings(ghToken: _token, ghUsername: _username);
        _fetchProfileInBackground(_token);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('GitHubProvider.initialize error: $e');
    }
  }

  Future<void> _fetchProfileInBackground(String token) async {
    try {
      final profile = await _githubService.getUserProfile(token);
      if (profile != null) {
        _followers = profile['followers'];
        _following = profile['following'];
        _avatarUrl = profile['avatarUrl'];
        _createdAt = profile['createdAt'];
        _orgsCount = profile['orgsCount'];
        _starredCount = profile['starredCount'];
        _publicRepos = profile['publicRepos'];
        _totalPrivateRepos = profile['totalPrivateRepos'];
        _repos = await _githubService.listRepos(token);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching github profile on init: $e');
    }
  }

  void syncFromAppConfig() {
    _token = AppConfig.githubToken;
    _username = AppConfig.githubUsername;
    _isConnected = _token.isNotEmpty && _username.isNotEmpty;
    notifyListeners();
  }

  // ── Connect with token ──────────────────────────────────
  Future<bool> connectGithub(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate token by fetching user info
      final isValid = await _githubService.validateToken(token);
      if (!isValid) {
        _isLoading = false;
        _errorMessage = 'Invalid GitHub token. Please check and try again.';
        notifyListeners();
        return false;
      }

      _token = token;
      final profile = await _githubService.getUserProfile(token);
      if (profile != null) {
        _username = profile['username'] ?? 'user';
        _followers = profile['followers'];
        _following = profile['following'];
        _avatarUrl = profile['avatarUrl'];
        _createdAt = profile['createdAt'];
        _orgsCount = profile['orgsCount'];
        _starredCount = profile['starredCount'];
        _publicRepos = profile['publicRepos'];
        _totalPrivateRepos = profile['totalPrivateRepos'];
      } else {
        _username = 'user';
      }
      _isConnected = true;

      AppConfig.applySettings(ghToken: token, ghUsername: _username);
      await _persistence.saveGithubCredentials(token, _username);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not connect to GitHub: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Fetch user repositories ─────────────────────────────
  Future<void> fetchRepos() async {
    if (!_isConnected) return;

    _isLoading = true;
    notifyListeners();

    try {
      _repos = await _githubService.listRepos(_token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not fetch repositories: $e';
      notifyListeners();
    }
  }

  // ── Select a repository ─────────────────────────────────
  void selectRepo(String slug) {
    _selectedRepoSlug = slug;
    notifyListeners();
  }

  // ── Push project to GitHub ──────────────────────────────
  Future<bool> pushProject(CodeResult codeResult) async {
    _isPushing = true;
    _pushProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _githubService.pushProject(
        codeResult,
        repoSlug: _selectedRepoSlug,
        onProgress: (p) {
          _pushProgress = p;
          notifyListeners();
        },
      );

      if (success) {
        _lastPushUrl =
            _githubService.repoUrl(codeResult, repoSlug: _selectedRepoSlug);
      } else if (!_githubService.isConfigured) {
        _errorMessage =
            'GitHub not connected. Go to Settings → GitHub to connect.';
      } else {
        _errorMessage = 'Push failed. Check your token and try again.';
      }

      _isPushing = false;
      _pushProgress = success ? 1.0 : _pushProgress;
      notifyListeners();
      return success;
    } catch (e) {
      _isPushing = false;
      _errorMessage = 'Push failed: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Disconnect ──────────────────────────────────────────
  Future<void> disconnect() async {
    _token = '';
    _username = '';
    _isConnected = false;
    _repos = [];
    _followers = null;
    _following = null;
    _avatarUrl = null;
    _createdAt = null;
    _orgsCount = null;
    _starredCount = null;
    _publicRepos = null;
    _totalPrivateRepos = null;
    _selectedRepoSlug = null;
    _lastPushUrl = null;
    AppConfig.applySettings(ghToken: '', ghUsername: '');
    await _persistence.clearGithubCredentials();
    notifyListeners();
  }

  // ── Clear error ─────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
