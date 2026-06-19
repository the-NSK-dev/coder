import 'package:flutter/material.dart';

class HoverPressRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final HitTestBehavior? behavior;
  final BorderRadius? borderRadius;

  const HoverPressRegion({
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.behavior,
    this.borderRadius,
    super.key,
  });

  @override
  State<HoverPressRegion> createState() => _HoverPressRegionState();
}

class _HoverPressRegionState extends State<HoverPressRegion> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onDoubleTap: widget.onDoubleTap,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withValues(alpha: 0.10)
                : _hovering
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
