import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/code_result.dart';
import '../models/file_item.dart';
import '../models/plan_result.dart';

/// Combines generated files into a single self-contained HTML string
/// for WebView rendering.
class PreviewBuilder {
  PreviewBuilder();

  /// Build preview HTML from files in a project directory on disk.
  Future<String> buildPreview(String projectPath) async {
    if (kIsWeb) {
      return '<html><body><h1>Preview not available on web</h1></body></html>';
    }

    final dir = Directory(projectPath);
    if (!await dir.exists()) {
      return '<html><body><h1>Project not found</h1></body></html>';
    }

    String htmlContent = '<body></body>';
    final cssBuffer = StringBuffer();
    final jsBuffer = StringBuffer();

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final path = entity.path.toLowerCase();
        try {
          if (path.endsWith('.html') || path.endsWith('.htm')) {
            htmlContent = await entity.readAsString();
          } else if (path.endsWith('.css')) {
            cssBuffer.writeln(await entity.readAsString());
          } else if (path.endsWith('.js')) {
            jsBuffer.writeln(await entity.readAsString());
          }
        } catch (_) {
          // Skip unreadable files
        }
      }
    }

    return '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>${cssBuffer.toString()}</style>
</head><body>
$htmlContent
<script type="text/javascript">${jsBuffer.toString()}</script>
</body></html>''';
  }

  /// Build preview from in-memory CodeResult and PlanResult objects.
  static String build(CodeResult code, PlanResult plan) {
    final htmlFile = code.files.firstWhere(
      (f) => f.path.endsWith('.html'),
      orElse: () =>
          FileItem(path: '', name: '', content: '<body></body>'),
    );
    final cssFiles =
        code.files.where((f) => f.path.endsWith('.css'));
    final jsFiles = code.files.where(
        (f) => f.path.endsWith('.js') || f.path.endsWith('.jsx'));

    final tailwindScript = plan.languages.contains('tailwind')
        ? '<script src="https://cdn.tailwindcss.com"></script>'
        : '';
    final reactScripts = plan.languages.contains('react')
        ? '''
      <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
      <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
      <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    '''
        : '';

    final css = cssFiles.map((f) => f.content).join('\n');
    final js = jsFiles.map((f) => f.content).join('\n');
    final scriptType =
        plan.languages.contains('react') ? 'text/babel' : 'text/javascript';

    return '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
$tailwindScript
<style>$css</style>
</head><body>
${htmlFile.content}
$reactScripts
<script type="$scriptType">$js</script>
</body></html>''';
  }
}

