import 'package:flutter/material.dart';

enum ErrorSeverity { info, warning, critical }

class PremiumErrorState extends StatelessWidget {
  final ErrorSeverity severity;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const PremiumErrorState({
    required this.severity,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.dismissible = true,
    this.onDismiss,
    super.key,
  });

  Color get _accentColor => switch (severity) {
    ErrorSeverity.info => const Color(0xFF3B6FE8),
    ErrorSeverity.warning => const Color(0xFFEAB308),
    ErrorSeverity.critical => const Color(0xFFEF4444),
  };

  IconData get _icon => switch (severity) {
    ErrorSeverity.info => Icons.info_outline_rounded,
    ErrorSeverity.warning => Icons.warning_amber_rounded,
    ErrorSeverity.critical => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12.5, height: 1.4)),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(actionLabel!, style: TextStyle(
                      color: _accentColor, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          if (dismissible)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16,
                  color: Colors.white.withValues(alpha: 0.4)),
              onPressed: onDismiss,
              splashRadius: 16,
            ),
        ],
      ),
    );
  }
}
