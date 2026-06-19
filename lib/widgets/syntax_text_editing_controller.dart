import 'package:flutter/material.dart';

/// Syntax-highlighting TextEditingController.
/// Colors are based on a VS Code / GitHub dark theme.
/// Font size is NOT set here — it is set by the parent TextField's style.
class SyntaxTextEditingController extends TextEditingController {
  SyntaxTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: _tokenize(text),
    );
  }

  List<TextSpan> _tokenize(String code) {
    final List<TextSpan> spans = [];
    final RegExp lexer = RegExp(
      r'(?<comment>//.*|/\*[\s\S]*?\*/)|' // Comments
      r'''(?<string>".*?"|'.*?'|`.*?`)|''' // Strings
      r'(?<preprocessor>#\w+)|' // Preprocessor (#include, #define)
      r'(?<keyword>\b(import|export|class|struct|enum|extends|implements|if|else|for|while|do|switch|case|break|continue|return|new|final|const|var|let|function|void|int|double|float|long|short|char|bool|boolean|String|null|true|false|async|await|try|catch|finally|throw|static|abstract|override|public|private|protected|super|this|from|of|in|instanceof|typeof|undefined|type|interface|get|set|constructor|using|namespace|include|cout|endl|cin)\b)|'
      r'(?<type>\b([A-Z]\w*)\b)|' // Types (capitalized identifiers)
      r'(?<number>\b\d+\.?\d*\b)|' // Numbers
      r'(?<operator>[+\-*/<>=!&|%^~?:]+)|' // Operators
      r'(?<punctuation>[(){}\[\];,.])|' // Punctuation
      r'(?<identifier>[a-zA-Z_]\w*)', // Other identifiers
    );

    int lastMatchEnd = 0;
    for (final match in lexer.allMatches(code)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: code.substring(lastMatchEnd, match.start),
          style: _style(const Color(0xFFE6EDF3)),
        ));
      }

      if (match.namedGroup('comment') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('comment'),
          style: _style(const Color(0xFF8B949E), italic: true),
        ));
      } else if (match.namedGroup('preprocessor') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('preprocessor'),
          style: _style(const Color(0xFFFF7B72)),
        ));
      } else if (match.namedGroup('string') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('string'),
          style: _style(const Color(0xFFA5D6FF)),
        ));
      } else if (match.namedGroup('keyword') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('keyword'),
          style: _style(const Color(0xFFFF7B72)),
        ));
      } else if (match.namedGroup('type') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('type'),
          style: _style(const Color(0xFFD2A8FF)),
        ));
      } else if (match.namedGroup('number') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('number'),
          style: _style(const Color(0xFF79C0FF)),
        ));
      } else if (match.namedGroup('operator') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('operator'),
          style: _style(const Color(0xFFF3C766)),
        ));
      } else if (match.namedGroup('punctuation') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('punctuation'),
          style: _style(const Color(0xFFE6EDF3).withValues(alpha: 0.6)),
        ));
      } else if (match.namedGroup('identifier') != null) {
        spans.add(TextSpan(
          text: match.namedGroup('identifier'),
          style: _style(const Color(0xFFE6EDF3)),
        ));
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < code.length) {
      spans.add(TextSpan(
        text: code.substring(lastMatchEnd),
        style: _style(const Color(0xFFE6EDF3)),
      ));
    }

    return spans;
  }

  TextStyle _style(Color color, {bool italic = false}) {
    return TextStyle(
      color: color,
      fontFamily: 'monospace',
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
  }
}
