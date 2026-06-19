import 'package:flutter/material.dart';

/// Centralized animation constants and reusable transition builders.
class AppAnimations {
  AppAnimations._();

  // ─────────────────────────────────────────────────────
  // DURATIONS
  // ─────────────────────────────────────────────────────

  /// Default UI transition duration (300ms).
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Fast micro-interaction duration (150ms).
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Medium transition for tabs, panels (200ms).
  static const Duration mediumDuration = Duration(milliseconds: 200);

  /// Slow transition for page changes (400ms).
  static const Duration slowDuration = Duration(milliseconds: 400);

  /// Chat message appearance duration.
  static const Duration messageDuration = Duration(milliseconds: 350);

  // ─────────────────────────────────────────────────────
  // CURVES
  // ─────────────────────────────────────────────────────

  /// Default easing curve for most transitions.
  static const Curve defaultCurve = Curves.easeInOutCubic;

  /// Snappy curve for button presses and micro-interactions.
  static const Curve snappyCurve = Curves.easeOutCubic;

  /// Bounce curve for playful elements.
  static const Curve bounceCurve = Curves.elasticOut;

  /// Deceleration curve for items entering the screen.
  static const Curve enterCurve = Curves.decelerate;

  // ─────────────────────────────────────────────────────
  // PAGE TRANSITION BUILDERS
  // ─────────────────────────────────────────────────────

  /// Fade transition for page changes.
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }

  /// Slide-up transition (e.g. for modals, bottom sheets).
  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tween = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).chain(CurveTween(curve: defaultCurve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Slide-right transition (e.g. for file opening).
  static Widget slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final tween = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: defaultCurve));

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Scale transition (e.g. for dialogs, popups).
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleTween = Tween<double>(begin: 0.95, end: 1.0)
        .chain(CurveTween(curve: defaultCurve));

    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  // ─────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────

  /// Creates an animated shimmer placeholder for loading states.
  static Widget shimmerPlaceholder({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return _ShimmerWidget(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// Internal shimmer widget for loading states.
class _ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerWidget({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: const [
                Color(0xFF1A1A2E),
                Color(0xFF2A2A4A),
                Color(0xFF1A1A2E),
              ],
            ),
          ),
        );
      },
    );
  }
}
