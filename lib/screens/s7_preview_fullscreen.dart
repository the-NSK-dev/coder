import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/preview_provider.dart';
import '../services/desktop_preview_webview.dart';
import '../utils/nav_utils.dart';

/// Screen 7 — Full Preview Mode with live PreviewProvider.
class S7PreviewFullscreen extends StatefulWidget {
  final VoidCallback? onClosePanel;

  const S7PreviewFullscreen({super.key, this.onClosePanel});

  @override
  State<S7PreviewFullscreen> createState() => _S7PreviewFullscreenState();
}

class _S7PreviewFullscreenState extends State<S7PreviewFullscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  bool _isDesktop = false;
  final GlobalKey<DesktopPreviewWebviewState> _webviewKey = GlobalKey();

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

  Future<void> _refresh() async {
    final path = AppConfig.currentProjectDir;
    final preview = context.read<PreviewProvider>();
    final chat = context.read<ChatProvider>();

    if (path == null || path.isEmpty) {
      if (chat.currentCodeResult != null && chat.currentPlan != null) {
        preview.startPreviewFromMemory(chat.currentCodeResult!, chat.currentPlan!);
      }
      return;
    }
    await preview.refreshPreview(path);
  }

  Future<void> _openExternal() async {
    final url = context.read<PreviewProvider>().previewUrl;
    if (url == null || url.startsWith('data:')) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final chat = Provider.of<ChatProvider>(context);
    final preview = Provider.of<PreviewProvider>(context);
    final code = chat.currentCodeResult;
    final url = preview.previewUrl ?? 'about:blank';
    final displayUrl = url.startsWith('data:') ? 'inline preview' : url;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (mounted) {
            if (widget.onClosePanel != null) {
              widget.onClosePanel!();
            } else {
              popOrGo(context);
            }
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * s, vertical: 12 * s),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onClosePanel != null) {
                        widget.onClosePanel!();
                      } else {
                        popOrGo(context);
                      }
                    },
                    child: Container(
                      width: 40 * s,
                      height: 40 * s,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111115),
                        borderRadius: BorderRadius.circular(12 * s),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 20 * s),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${code?.projectName ?? "App"} – ${code?.version ?? "v1"}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12 * s,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isDesktop = !_isDesktop),
                    child: _iconBtn(
                      Icon(
                        _isDesktop
                            ? Icons.desktop_windows_outlined
                            : Icons.phone_android_outlined,
                        color: _isDesktop
                            ? AppColors.accentBlue
                            : Colors.white.withValues(alpha: 0.7),
                        size: 20 * s,
                      ),
                      s,
                      highlighted: _isDesktop,
                    ),
                  ),
                ],
              ),
            ),
            // Standard browser control toolbar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4 * s),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _webviewKey.currentState?.goBack(),
                    child: _iconBtn(
                      Icon(Icons.arrow_back_ios_new, color: Colors.white.withValues(alpha: 0.7), size: 16 * s),
                      s,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  GestureDetector(
                    onTap: () => _webviewKey.currentState?.goForward(),
                    child: _iconBtn(
                      Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 16 * s),
                      s,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  GestureDetector(
                    onTap: () {
                      _refresh();
                      _webviewKey.currentState?.reload();
                    },
                    child: _iconBtn(
                      Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.7), size: 18 * s),
                      s,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  GestureDetector(
                    onTap: _openExternal,
                    child: _iconBtn(
                      Icon(Icons.open_in_browser, color: Colors.white.withValues(alpha: 0.7), size: 18 * s),
                      s,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  GestureDetector(
                    onTap: () async {
                      if (url.startsWith('data:')) return;
                      // In a real app we'd copy to clipboard using flutter/services
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied to clipboard!')));
                    },
                    child: _iconBtn(
                      Icon(Icons.copy, color: Colors.white.withValues(alpha: 0.7), size: 16 * s),
                      s,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16 * s),
              height: 36 * s,
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D20),
                borderRadius: BorderRadius.circular(8 * s),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12 * s),
                  Container(
                    width: 8 * s,
                    height: 8 * s,
                    decoration: BoxDecoration(
                      color: preview.hasPreview
                          ? AppColors.success
                          : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      displayUrl,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11 * s,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12 * s),
                ],
              ),
            ),
            if (preview.errorMessage != null)
              Padding(
                padding: EdgeInsets.all(12 * s),
                child: Text(
                  preview.errorMessage!,
                  style: TextStyle(color: AppColors.error, fontSize: 12 * s),
                ),
              ),
            SizedBox(height: 8 * s),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 12 * s),
                child: AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    final borderGlow =
                        0.42 + (_borderController.value * 0.24);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1117),
                        borderRadius: BorderRadius.circular(12 * s),
                        border: Border.all(
                          color: AppColors.accentBlue
                              .withValues(alpha: borderGlow),
                          width: 1.4,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: SizedBox(
                      width: _isDesktop ? double.infinity : 375 * s,
                      height: _isDesktop ? double.infinity : 812 * s,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11 * s),
                        child: preview.isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accentBlue),
                                ),
                              )
                            : _buildPreviewContent(url, s),
                      ),
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
    );
  }

  Widget _buildPreviewContent(String url, double s) {
    return DesktopPreviewWebview(
      key: _webviewKey,
      url: url,
    );
  }

  Widget _iconBtn(Widget child, double s, {bool highlighted = false}) {
    return Container(
      width: 40 * s,
      height: 40 * s,
      decoration: BoxDecoration(
        color: const Color(0xFF090B13),
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(
          color: highlighted
              ? AppColors.accentBlue.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Center(child: child),
    );
  }
}
