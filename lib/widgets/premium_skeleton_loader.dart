import 'package:flutter/material.dart';

class PremiumSkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  const PremiumSkeletonLoader({
    this.height = 16, this.width = double.infinity,
    this.borderRadius, super.key,
  });

  @override
  State<PremiumSkeletonLoader> createState() => _PremiumSkeletonLoaderState();
}

class _PremiumSkeletonLoaderState extends State<PremiumSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 3, 0),
              end: Alignment(0 + _controller.value * 3, 0),
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
        );
      },
    );
  }
}
