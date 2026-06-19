// ════════════════════════════════════════════════════════════
// lib/config/app_config.dart
//
// Runtime configuration for Band.ai, GitHub, and agent pipeline.
// Values can be set via Settings UI (persisted) or compile-time defaults.
// ════════════════════════════════════════════════════════════

class AppConfig {
  // ── Compile-time defaults (dev fallback) ─────────────────
  static const String _defaultBandUserApiKey = '';
  static const String _defaultBandRoomId = '';
  static const String _defaultGithubToken = '';
  static const String _defaultGithubUsername = '';
  static const String _defaultAimlApiKey = 'rc_e4305877d5e9cecd268db19cb4e6292275a35716ffbd16c64ed14b7b129af918';
  static const String featherlessBaseUrl = 'https://featherless.ai/v1/chat/completions';

  // ── Runtime mutable values ─────────────────────────────────
  static String bandUserApiKey = _defaultBandUserApiKey;
  static String bandRoomId = _defaultBandRoomId;
  static String githubToken = _defaultGithubToken;
  static String githubUsername = _defaultGithubUsername;
  static String aimlApiKey = _defaultAimlApiKey;
  static bool verificationEnabled = true;

  static String? currentProjectDir;
  static bool darkTheme = true;

  /// The 8 supported languages for preview and 3-step verification.
  static const Set<String> supportedLanguages = {
    'dart', 'javascript', 'typescript', 'python', 'html', 'css', 'java', 'cpp'
  };

  /// Legacy region fields — kept for backward compat.
  static String region1Name = 'Controller-Planner';
  static String region1Config = 'AIMLAPI';
  static String region2Name = 'Engineer';
  static String region2Config = 'Featherless';
  static String region3Name = 'Reviewer';
  static String region3Config = 'AIMLAPI';
  static String region4Name = 'Verifier';
  static String region4Config = 'Featherless';

  // ── Computed ───────────────────────────────────────────────

  static bool get isBandConfigured =>
      bandUserApiKey.isNotEmpty && bandRoomId.isNotEmpty;

  static bool get isGithubConfigured =>
      githubToken.isNotEmpty && githubUsername.isNotEmpty;

  static bool get isAimlConfigured => aimlApiKey.isNotEmpty;

  /// Live Band room when configured.
  static bool get useLiveAgents => false;

  /// Apply persisted or in-memory settings at runtime.
  static void applySettings({
    String? bandKey,
    String? roomId,
    String? ghToken,
    String? ghUsername,
    String? aimlKey,
    bool? verification,
  }) {
    if (bandKey != null) bandUserApiKey = bandKey;
    if (roomId != null) bandRoomId = roomId;
    if (ghToken != null) githubToken = ghToken;
    if (ghUsername != null) githubUsername = ghUsername;
    if (aimlKey != null) aimlApiKey = aimlKey;
    if (verification != null) verificationEnabled = verification;
  }
}
