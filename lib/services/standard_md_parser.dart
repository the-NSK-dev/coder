import 'package:flutter/services.dart';

class StandardRules {
  final List<String> use;
  final List<String> doNot;
  final List<String> requiredFiles;
  final List<String> verifyChecks;

  StandardRules({
    required this.use,
    required this.doNot,
    required this.requiredFiles,
    required this.verifyChecks,
  });

  factory StandardRules.empty() =>
      StandardRules(use: [], doNot: [], requiredFiles: [], verifyChecks: []);
}

class StandardMdParser {
  /// Maps detected stack → asset path (Note 11 auto-select)
  static String assetForStack(String stack) {
    final map = {
      'html': 'assets/standards/html.standard.md',
      'css': 'assets/standards/css.standard.md',
      'javascript': 'assets/standards/javascript.standard.md',
      'typescript': 'assets/standards/typescript.standard.md',
      'react': 'assets/standards/react.standard.md',
      'next.js': 'assets/standards/nextjs.standard.md',
      'nextjs': 'assets/standards/nextjs.standard.md',
      'node.js': 'assets/standards/nodejs.standard.md',
      'nodejs': 'assets/standards/nodejs.standard.md',
      'python': 'assets/standards/python.standard.md',
    };
    return map[stack.toLowerCase()] ?? 'assets/standards/html.standard.md';
  }

  Future<StandardRules> loadForStack(String stack) async {
    try {
      final md = await rootBundle.loadString(assetForStack(stack));
      return parse(md);
    } catch (_) {
      return StandardRules.empty();
    }
  }

  /// Parses the dense .md rulebook into structured rules
  StandardRules parse(String md) {
    final sections = <String, List<String>>{
      'USE': [],
      'DO_NOT': [],
      'REQUIRED_FILES': [],
      'VERIFY_CHECKS': [],
    };

    String? current;
    for (final line in md.split('\n')) {
      final trimmed = line.trim();
      final header = RegExp(r'^#{1,3}\s*(USE|DO_NOT|REQUIRED_FILES|VERIFY_CHECKS)')
          .firstMatch(trimmed.toUpperCase());
      if (header != null) {
        current = header.group(1);
        continue;
      }
      if (current != null && trimmed.startsWith('-')) {
        sections[current]!.add(trimmed.substring(1).trim());
      }
    }

    return StandardRules(
      use: sections['USE']!,
      doNot: sections['DO_NOT']!,
      requiredFiles: sections['REQUIRED_FILES']!,
      verifyChecks: sections['VERIFY_CHECKS']!,
    );
  }
}
