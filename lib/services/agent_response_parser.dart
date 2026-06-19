import 'dart:convert';
import '../models/code_result.dart';
import '../models/plan_result.dart';

class VerificationVerdict {
  final bool failed;
  VerificationVerdict(this.failed);
}

class AgentResponseParser {
  /// Robust file extraction — handles multiple LLM header formats
  CodeResult parseFiles(String text, {String projectName = 'App Build'}) {
    final files = <GeneratedFile>[];

    // Strategy 1: Standard "## File: path" + fenced code
    final patterns = [
      RegExp(r'#{1,4}\s*File:\s*([^\n]+)\n+```[a-zA-Z0-9]*\n([\s\S]*?)```',
          multiLine: true),
      // Strategy 2: "**path**" bold filename + code
      RegExp(r'\*\*([^\*\n]+\.[a-zA-Z]+)\*\*\s*\n+```[a-zA-Z0-9]*\n([\s\S]*?)```',
          multiLine: true),
      // Strategy 3: filename as code-fence info string ```path/file.js
      RegExp(r'```([a-zA-Z0-9_\-./]+\.[a-zA-Z]+)\n([\s\S]*?)```',
          multiLine: true),
    ];

    final seenPaths = <String>{};
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        final rawPath = match.group(1)?.trim() ?? '';
        final content = match.group(2) ?? '';
        final path = _sanitizePath(rawPath);
        if (path.isEmpty || seenPaths.contains(path)) continue;
        if (content.trim().isEmpty) continue;
        seenPaths.add(path);
        files.add(GeneratedFile(
            path: path,
            name: path.split('/').last,
            content: content.trimRight()));
      }
      if (files.isNotEmpty) break; // first working strategy wins
    }

    return CodeResult(
      projectName: projectName,
      files: files,
      projectType: _detectProjectType(files),
    );
  }

  CodeResult? parseCodeResult(String text, {required String projectName}) {
    final res = parseFiles(text, projectName: projectName);
    if (res.files.isEmpty) return null;
    return res;
  }

  /// Robust JSON plan extraction — survives LLM prose wrapping
  PlanResult? parsePlan(String text) {
    // Try fenced ```json block first
    final jsonBlock = RegExp(r'```json\s*\n([\s\S]*?)```').firstMatch(text);
    String? candidate = jsonBlock?.group(1);

    // Fallback: find first balanced {...}
    candidate ??= _extractBalancedJson(text);
    if (candidate == null) return null;

    try {
      final json = jsonDecode(candidate.trim()) as Map<String, dynamic>;
      return PlanResult(
        steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
        languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [json['stack']?.toString() ?? 'unknown'],
        previewMode: json['previewMode']?.toString() ?? 'live',
      );
    } catch (_) {
      return null; // graceful: caller treats as plain text
    }
  }

  List<String>? parseClarifyingQuestions(String text) {
    if (text.toLowerCase().contains('clarifying question')) {
      final lines = text.split('\n');
      final qs = lines
          .where((l) => RegExp(r'^\d+\.|\*|-').hasMatch(l.trim()))
          .map((l) => l.trim().replaceFirst(RegExp(r'^(\d+\.|\*|-)\s*'), ''))
          .toList();
      return qs.isNotEmpty ? qs : null;
    }
    return null;
  }

  VerificationVerdict parseVerification(String text) {
    final t = text.toLowerCase();
    // If text contains word like "fail", "failed", "error", "missing"
    if (t.contains('fail') || t.contains('error') || t.contains('missing') || t.contains('issue')) {
      return VerificationVerdict(true);
    }
    return VerificationVerdict(false);
  }

  static String _sanitizePath(String path) {
    // Block path traversal, strip leading slashes
    if (path.contains('..')) return '';
    return path.replaceAll(RegExp(r'^[/\\]+'), '').replaceAll('\\', '/');
  }

  static String? _extractBalancedJson(String text) {
    final start = text.indexOf('{');
    if (start == -1) return null;
    int depth = 0;
    for (int i = start; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  static String _detectProjectType(List<GeneratedFile> files) {
    final paths = files.map((f) => f.path.toLowerCase()).toList();
    if (paths.any((p) => p.contains('next.config'))) return 'Next.js';
    if (paths.any((p) => p.endsWith('.tsx') || p.endsWith('.jsx'))) return 'React';
    if (paths.any((p) => p.endsWith('.py'))) return 'Python';
    if (paths.any((p) => p == 'package.json')) return 'Node.js';
    if (paths.any((p) => p.endsWith('.html'))) return 'HTML';
    return 'Band.ai Build';
  }
}
