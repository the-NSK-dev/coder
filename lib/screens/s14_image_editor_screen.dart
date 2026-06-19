import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/chat_input_bar.dart';
import '../theme/app_colors.dart';

/// Screen 14 — Image Editor (Crop & Annotate)
class S14ImageEditorScreen extends StatefulWidget {
  final ChatAttachment attachment;

  const S14ImageEditorScreen({super.key, required this.attachment});

  @override
  State<S14ImageEditorScreen> createState() => _S14ImageEditorScreenState();
}

class _S14ImageEditorScreenState extends State<S14ImageEditorScreen> {
  // Mock metadata to return
  final Map<String, dynamic> _metadata = {
    'cropRect': {'x': 10, 'y': 10, 'width': 100, 'height': 100},
    'annotations': ['Highlighted button'],
  };

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Image',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16 * s,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Return mock metadata
              context.pop(_metadata);
            },
            child: Text(
              'Done',
              style: TextStyle(
                color: AppColors.accentBlue,
                fontSize: 14 * s,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.attachment.bytes != null)
              Container(
                margin: EdgeInsets.all(20 * s),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accentBlue, width: 2),
                ),
                child: Image.memory(
                  widget.attachment.bytes!,
                  fit: BoxFit.contain,
                ),
              )
            else
              Text(
                'No image data',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            SizedBox(height: 20 * s),
            Text(
              'Crop & Annotate Tools Here',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14 * s,
              ),
            ),
            SizedBox(height: 10 * s),
            Text(
              '(Returning mock crop data when Done is pressed)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12 * s,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
