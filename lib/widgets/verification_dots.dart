import 'package:flutter/material.dart';
import '../models/verification_status.dart';
import '../models/verification_step_detail.dart';
import '../theme/app_colors.dart';

// Renders 3 verification dots. Tapping a dot opens a detail sheet
// showing the agent, model, duration, and each individual check.
class VerificationDots extends StatefulWidget {
  // Pass the rich step list from VerificationEngine.
  final List<VerificationStepDetail> steps;
  final double size;

  const VerificationDots({
    super.key,
    required this.steps,
    this.size = 16,
  });

  @override
  State<VerificationDots> createState() => _VerificationDotsState();
}

class _VerificationDotsState extends State<VerificationDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _buildDot(widget.steps[i]),
        ],
      ],
    );
  }

  Widget _buildDot(VerificationStepDetail step) {
    Widget dot;
    switch (step.status) {
      case VerificationStatus.passed:
        dot = _solidDot(AppColors.success);
        break;
      case VerificationStatus.inProgress:
        dot = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: _solidDot(AppColors.warning),
          ),
        );
        break;
      case VerificationStatus.failed:
        dot = _solidDot(step.isEscalated
            ? const Color(0xFF111111)
            : AppColors.error);
        break;
      case VerificationStatus.pending:
        dot = _outlineDot();
        break;
    }

    return GestureDetector(
      onTap: () => _showDetailSheet(step),
      child: Tooltip(
        message: 'Step ${step.step}: ${step.name}',
        child: dot,
      ),
    );
  }

  void _showDetailSheet(VerificationStepDetail step) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEP ${step.step}: ${step.name.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agent: ${step.agentLabel} · Model: ${step.model} · '
              '${step.duration.inMilliseconds}ms',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              step.agentHandle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const Divider(color: Colors.white24, height: 24),
            ...step.checks.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        c.pass ? Icons.check_circle : Icons.cancel,
                        color: c.pass
                            ? AppColors.success
                            : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13)),
                            Text(c.reason,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _solidDot(Color color) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _outlineDot() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF444466), width: 1.5),
        color: Colors.transparent,
      ),
    );
  }
}
