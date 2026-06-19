import 'dart:io';

void main() {
  final dir = Directory('c:/Users/monika/Downloads/NSK/coder-screen/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('app_colors.dart')) continue;
    
    var content = file.readAsStringSync();
    if (!content.contains('AppColors.')) continue;
    
    // Add provider import if not present
    if (!content.contains("import 'package:provider/provider.dart';")) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';", 
        "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';"
      );
    }
    
    // Remove const keywords from Widget/BoxShadow instantiations that contain AppColors
    // This is tricky with regex. A safe bet is to remove const in front of [
    content = content.replaceAll(RegExp(r'const\s+\['), '[');
    // Remove const from BoxShadow
    content = content.replaceAll(RegExp(r'const\s+BoxShadow'), 'BoxShadow');
    // Remove const from SizedBox (just in case)
    // content = content.replaceAll(RegExp(r'const\s+SizedBox'), 'SizedBox');
    // Remove const from TextStyle
    content = content.replaceAll(RegExp(r'const\s+TextStyle'), 'TextStyle');
    // Remove const from Container/Padding
    content = content.replaceAll(RegExp(r'const\s+Padding'), 'Padding');
    // Remove const from Color (AppColors.glow uses Color)
    
    // Replace AppColors. with AppColors.of(context).
    content = content.replaceAll('AppColors.', 'AppColors.of(context).');
    
    // Specifically fix any `const Color` issues
    // content = content.replaceAll(RegExp(r'const\s+Color'), 'Color');
    
    file.writeAsStringSync(content);
    stdout.writeln('Refactored ${file.path}');
  }
}
