import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DesktopSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialLeftWidthRatio;

  const DesktopSplitView({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialLeftWidthRatio = 0.4,
  });

  @override
  State<DesktopSplitView> createState() => _DesktopSplitViewState();
}

class _DesktopSplitViewState extends State<DesktopSplitView> {
  late double _leftRatio;

  @override
  void initState() {
    super.initState();
    _leftRatio = widget.initialLeftWidthRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * _leftRatio;
        final rightWidth = totalWidth - leftWidth - 8.0; // 8.0 is divider width

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftWidth,
              child: widget.leftChild,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftRatio += details.delta.dx / totalWidth;
                  _leftRatio = _leftRatio.clamp(0.2, 0.8);
                });
              },
              child: Container(
                width: 8.0,
                color: AppColors.background,
                child: Center(
                  child: Container(
                    width: 2.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: rightWidth,
              child: widget.rightChild,
            ),
          ],
        );
      },
    );
  }
}
