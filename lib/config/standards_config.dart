import 'package:flutter/services.dart';

class StandardsConfig {
  static const Map<String, String> defaultAssetPaths = {
    'html': 'assets/standards/html.md',
    'css': 'assets/standards/css.md',
    'javascript': 'assets/standards/javascript.md',
    'tailwind': 'assets/standards/tailwind.md',
    'react': 'assets/standards/react.md',
    'nextjs': 'assets/standards/nextjs.md',
    'nodejs': 'assets/standards/nodejs.md',
    'java': 'assets/standards/java.md',
  };

  /// User-uploaded overrides — populated when user uploads a .md file
  /// via "Add files" whose name matches a key above (e.g. 'react.md').
  static Map<String, String> userOverrides = {};

  /// Returns the standards content for a given language.
  /// Prioritizes user overrides over bundled defaults.
  static Future<String> getStandardsFor(String language) async {
    final key = language.toLowerCase();
    if (userOverrides.containsKey(key)) {
      return userOverrides[key]!;
    }
    final path = defaultAssetPaths[key];
    if (path == null) return '';
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return '';
    }
  }
}
