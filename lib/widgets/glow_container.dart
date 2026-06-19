import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Generic container with a glowing border shadow.
class GlowContainer extends StatelessWidget {
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final double glowBlur;
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlowContainer({
    super.key,
    this.borderColor = AppColors.accentBlue,
    this.borderWidth = 1.5,
    this.radius = 16,
    this.glowBlur = 24,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [AppColors.glow(borderColor, blur: glowBlur)],
      ),
      child: child,
    );
  }
}
