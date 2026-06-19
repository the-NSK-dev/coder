import 'package:flutter/material.dart';
import '../models/verification_step_detail.dart';
import '../theme/app_colors.dart';
import 'verification_dots.dart';

// The "Generated App" card showing version, current file, and the
// 3 live verification dots. Pass the engine's step list in.
class ProjectStatusCard extends StatelessWidget {
  final String version;
  final String currentFile;
  final List<VerificationStepDetail> steps;
  final VoidCallback? onAttach;

  const ProjectStatusCard({
    super.key,
    required this.version,
    required this.currentFile,
    required this.steps,
    this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161629),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text('Generated App',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const Spacer(),
              Text(version,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(currentFile,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              VerificationDots(steps: steps),
              const Spacer(),
              _legend(AppColors.success, 'done'),
              const SizedBox(width: 8),
              _legend(AppColors.warning, 'running'),
              const SizedBox(width: 8),
              _legend(AppColors.error, 'failed'),
              if (onAttach != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.attach_file,
                      color: Colors.white54, size: 18),
                  onPressed: onAttach,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
