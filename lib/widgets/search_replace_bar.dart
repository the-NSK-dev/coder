import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../theme/app_colors.dart';

/// Floating search/replace bar overlay for the code editor.
class SearchReplaceBar extends StatefulWidget {
  final bool showReplace;
  final VoidCallback onClose;

  const SearchReplaceBar({
    super.key,
    this.showReplace = false,
    required this.onClose,
  });

  @override
  State<SearchReplaceBar> createState() => _SearchReplaceBarState();
}

class _SearchReplaceBarState extends State<SearchReplaceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late TextEditingController _searchCtrl;
  late TextEditingController _replaceCtrl;
  bool _showReplace = false;

  @override
  void initState() {
    super.initState();
    _showReplace = widget.showReplace;
    _searchCtrl = TextEditingController();
    _replaceCtrl = TextEditingController();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = Provider.of<EditorProvider>(context);
    final s = MediaQuery.of(context).size.width / 390;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value * 50),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 12 * s.clamp(0.85, 1.3),
          vertical: 8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search row
            Row(
              children: [
                // Toggle replace
                GestureDetector(
                  onTap: () => setState(() => _showReplace = !_showReplace),
                  child: Icon(
                    _showReplace
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),

                // Search input
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Find...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: AppColors.accentBlue, width: 1),
                        ),
                      ),
                      onChanged: (value) => editor.setSearchQuery(value),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Match count
                if (editor.searchMatches.isNotEmpty)
                  Text(
                    '${editor.currentMatchIndex + 1}/${editor.searchMatches.length}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),

                const SizedBox(width: 4),

                // Previous match
                _iconBtn(Icons.keyboard_arrow_up_rounded, editor.previousMatch),
                // Next match
                _iconBtn(Icons.keyboard_arrow_down_rounded, editor.nextMatch),

                const SizedBox(width: 4),

                // Close
                _iconBtn(Icons.close_rounded, _close),
              ],
            ),

            // Replace row
            if (_showReplace) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 28), // Spacer for alignment

                  // Replace input
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _replaceCtrl,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Replace...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.border, width: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.border, width: 0.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppColors.accentBlue, width: 1),
                          ),
                        ),
                        onChanged: (value) => editor.setReplaceQuery(value),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Replace current
                  _textBtn('Replace', editor.replaceCurrent),
                  const SizedBox(width: 4),
                  // Replace all
                  _textBtn('All', editor.replaceAll),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _textBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.accentBlue,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
