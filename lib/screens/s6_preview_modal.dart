import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../widgets/coder_app_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../theme/app_colors.dart';
import '../providers/preview_provider.dart';
import '../providers/chat_provider.dart';
import '../services/desktop_preview_webview.dart';

/// Screen 6 — Inline Preview Panel wired to PreviewProvider.
class S6PreviewModal extends StatefulWidget {
  const S6PreviewModal({super.key});

  @override
  State<S6PreviewModal> createState() => _S6PreviewModalState();
}

class _S6PreviewModalState extends State<S6PreviewModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startPreview());
  }

  Future<void> _startPreview() async {
    final path = AppConfig.currentProjectDir;
    final preview = context.read<PreviewProvider>();
    final chat = context.read<ChatProvider>();

    if (path == null || path.isEmpty) {
      if (chat.currentCodeResult != null && chat.currentPlan != null) {
        preview.startPreviewFromMemory(chat.currentCodeResult!, chat.currentPlan!);
      }
      return;
    }
    await preview.startPreview(path);
  }

  @override
  void dispose() {
    _borderController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final preview = Provider.of<PreviewProvider>(context);
    final chat = Provider.of<ChatProvider>(context);
    final url = preview.previewUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CoderAppBar(
              onAvatarTap: () => context.push('/profile'),
              actions: [
                AppBarAction(
                  icon: Icons.folder_outlined,
                  onTap: () => context.push('/files'),
                ),
                AppBarAction(
                  icon: Icons.play_arrow_outlined,
                  onTap: () => context.push('/preview/full'),
                  highlighted: true,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 8 * s),
                child: AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    final borderGlow =
                        0.42 + (_borderController.value * 0.24);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF02030A),
                        borderRadius: BorderRadius.circular(18 * s),
                        border: Border.all(
                          color: AppColors.accentBlue
                              .withValues(alpha: borderGlow),
                          width: 1.4,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        left: 16 * s,
                        top: 16 * s,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Icon(Icons.close,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 22 * s),
                        ),
                      ),
                      Positioned(
                        right: 16 * s,
                        top: 16 * s,
                        child: GestureDetector(
                          onTap: () => context.push('/preview/full'),
                          child: Icon(Icons.open_in_full,
                              color: AppColors.accentBlue, size: 20 * s),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            12 * s, 48 * s, 12 * s, 12 * s),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12 * s),
                          child: preview.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.accentBlue,
                                  ),
                                )
                              : url != null
                                  ? DesktopPreviewWebview(url: url)
                                  : Center(
                                      child: Text(
                                        preview.errorMessage ??
                                            'Open a project to preview',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13 * s,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ChatInputBar(
              aiNamePillText: '',
              onAddFiles: () {},
              onSend: () {
                final text = _promptController.text.trim();
                if (text.isNotEmpty) {
                  chat.sendMessage(text);
                  _promptController.clear();
                }
              },
              controller: _promptController,
              chatScope: chat.chatScope,
              onScopeChanged: chat.setChatScope,
            ),
          ],
        ),
      ),
    );
  }
}
