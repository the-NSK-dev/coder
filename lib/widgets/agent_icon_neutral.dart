import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Neutral-colored agent icon container used on the Profile screen.
/// All 4 agent rows use this exact same widget, differing only by
/// icon and label text. NO agent-specific colors.
class AgentIconNeutral extends StatelessWidget {
  final IconData icon;
  final double size;

  const AgentIconNeutral({
    super.key,
    required this.icon,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: AppColors.neutralIcon,
          size: 24,
        ),
      ),
    );
  }
}
