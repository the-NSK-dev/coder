import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Persistence service for storing user preferences and workspace state.
/// Uses SharedPreferences for cross-platform key-value storage.
class PersistenceService {
  static const _keyLastProjectPath = 'last_project_path';
  static const _keyRecentProjects = 'recent_projects';
  static const _keyDarkTheme = 'dark_theme';
  static const _keyAutoSaveEnabled = 'auto_save_enabled';
  static const _keyAutoSaveIntervalMs = 'auto_save_interval_ms';
  static const _keyGithubToken = 'github_token';
  static const _keyGithubUsername = 'github_username';
  static const _keySelectedModel = 'selected_model';
  static const _keyBandUserApiKey = 'band_user_api_key';
  static const _keyBandRoomId = 'band_room_id';
  static const _keyAimlApiKey = 'aiml_api_key';
  static const _keyVerificationEnabled = 'verification_enabled';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─────────────────────────────────────────────────────
  // WORKSPACE PERSISTENCE
  // ─────────────────────────────────────────────────────

  /// Save the last opened project path for auto-restore on next launch.
  Future<void> saveLastProjectPath(String path) async {
    final prefs = await _getPrefs;
    await prefs.setString(_keyLastProjectPath, path);
  }

  /// Get the last opened project path. Returns null if none saved.
  Future<String?> getLastProjectPath() async {
    final prefs = await _getPrefs;
    return prefs.getString(_keyLastProjectPath);
  }

  /// Add a project path to the recent projects list (max 5).
  Future<void> addRecentProject(String name, String path) async {
    final prefs = await _getPrefs;
    final recentJson = prefs.getStringList(_keyRecentProjects) ?? [];

    // Build entry as JSON
    final entry = jsonEncode({'name': name, 'path': path});

    // Remove duplicate if exists
    recentJson.removeWhere((e) {
      try {
        final decoded = jsonDecode(e) as Map<String, dynamic>;
        return decoded['path'] == path;
      } catch (_) {
        return false;
      }
    });

    // Insert at front, cap at 5
    recentJson.insert(0, entry);
    if (recentJson.length > 5) {
      recentJson.removeRange(5, recentJson.length);
    }

    await prefs.setStringList(_keyRecentProjects, recentJson);
  }

  /// Get list of recent projects as [{name, path}].
  Future<List<Map<String, String>>> getRecentProjects() async {
    final prefs = await _getPrefs;
    final recentJson = prefs.getStringList(_keyRecentProjects) ?? [];
    final result = <Map<String, String>>[];
    for (final entry in recentJson) {
      try {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        result.add({
          'name': decoded['name'] as String? ?? '',
          'path': decoded['path'] as String? ?? '',
        });
      } catch (_) {
        // Skip malformed entries
      }
    }
    return result;
  }

  /// Clear the last opened project path.
  Future<void> clearLastProject() async {
    final prefs = await _getPrefs;
    await prefs.remove(_keyLastProjectPath);
  }

  // ─────────────────────────────────────────────────────
  // THEME & PREFERENCES
  // ─────────────────────────────────────────────────────

  Future<void> saveDarkTheme(bool isDark) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_keyDarkTheme, isDark);
  }

  Future<bool> getDarkTheme() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_keyDarkTheme) ?? true;
  }

  Future<void> saveAutoSaveEnabled(bool enabled) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_keyAutoSaveEnabled, enabled);
  }

  Future<bool> getAutoSaveEnabled() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_keyAutoSaveEnabled) ?? true;
  }

  Future<void> saveAutoSaveInterval(int ms) async {
    final prefs = await _getPrefs;
    await prefs.setInt(_keyAutoSaveIntervalMs, ms);
  }

  Future<int> getAutoSaveInterval() async {
    final prefs = await _getPrefs;
    return prefs.getInt(_keyAutoSaveIntervalMs) ?? 2000;
  }

  // ─────────────────────────────────────────────────────
  // GITHUB CREDENTIALS
  // ─────────────────────────────────────────────────────

  Future<void> saveGithubCredentials(String token, String username) async {
    final prefs = await _getPrefs;
    await prefs.setString(_keyGithubToken, token);
    await prefs.setString(_keyGithubUsername, username);
  }

  Future<Map<String, String>> getGithubCredentials() async {
    final prefs = await _getPrefs;
    return {
      'token': prefs.getString(_keyGithubToken) ?? '',
      'username': prefs.getString(_keyGithubUsername) ?? '',
    };
  }

  Future<void> clearGithubCredentials() async {
    final prefs = await _getPrefs;
    await prefs.remove(_keyGithubToken);
    await prefs.remove(_keyGithubUsername);
  }

  // ─────────────────────────────────────────────────────
  // AI MODEL SELECTION
  // ─────────────────────────────────────────────────────

  Future<void> saveSelectedModel(String model) async {
    final prefs = await _getPrefs;
    await prefs.setString(_keySelectedModel, model);
  }

  Future<String> getSelectedModel() async {
    final prefs = await _getPrefs;
    return prefs.getString(_keySelectedModel) ?? 'gpt-4o-mini';
  }

  // ─────────────────────────────────────────────────────
  // BAND.AI CREDENTIALS
  // ─────────────────────────────────────────────────────

  Future<void> saveBandCredentials(String apiKey, String roomId) async {
    final prefs = await _getPrefs;
    await prefs.setString(_keyBandUserApiKey, apiKey);
    await prefs.setString(_keyBandRoomId, roomId);
  }

  Future<Map<String, String>> getBandCredentials() async {
    final prefs = await _getPrefs;
    return {
      'apiKey': prefs.getString(_keyBandUserApiKey) ?? '',
      'roomId': prefs.getString(_keyBandRoomId) ?? '',
    };
  }

  Future<void> saveAimlApiKey(String key) async {
    final prefs = await _getPrefs;
    await prefs.setString(_keyAimlApiKey, key);
  }

  Future<String> getAimlApiKey() async {
    final prefs = await _getPrefs;
    return prefs.getString(_keyAimlApiKey) ?? '';
  }

  Future<void> saveVerificationEnabled(bool enabled) async {
    final prefs = await _getPrefs;
    await prefs.setBool(_keyVerificationEnabled, enabled);
  }

  Future<bool> getVerificationEnabled() async {
    final prefs = await _getPrefs;
    return prefs.getBool(_keyVerificationEnabled) ?? true;
  }

  /// Load all app config values into [AppConfig] at startup.
  Future<void> loadAppConfig() async {
    final band = await getBandCredentials();
    final gh = await getGithubCredentials();
    final aiml = await getAimlApiKey();
    final verification = await getVerificationEnabled();

    AppConfig.applySettings(
      bandKey: band['apiKey'],
      roomId: band['roomId'],
      ghToken: gh['token'],
      ghUsername: gh['username'],
      aimlKey: aiml,
      verification: verification,
    );
  }
}
