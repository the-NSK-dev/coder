import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/workspace_provider.dart';
import '../theme/app_colors.dart';
import '../utils/nav_utils.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/ide_bottom_panel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/python.dart';

/// Screen 11 — Real Syntax-Highlighted Code Editor matching reference design.
/// Wired to EditorProvider for tab/save management and ChatProvider for AI prompts.
class S11CodeEditorScreen extends StatefulWidget {
  final String filePath;

  const S11CodeEditorScreen({super.key, required this.filePath});

  @override
  State<S11CodeEditorScreen> createState() => _S11CodeEditorScreenState();
}

class _S11CodeEditorScreenState extends State<S11CodeEditorScreen> {
  late CodeController _textController;
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  bool _isSaving = false;
  // Simple undo stack
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastText = '';

  final List<ChatAttachment> _attachments = [];
  final Map<int, String> _diagnostics = {};

  @override
  void initState() {
    super.initState();
    _textController = CodeController(
      language: dart,
    );
    _textController.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFile();
    });
  }

  void _onTextChanged() {
    final newText = _textController.text;
    if (newText != _lastText) {
      _undoStack.add(_lastText);
      _redoStack.clear();
      _lastText = newText;
      if (_undoStack.length > 100) _undoStack.removeAt(0);

      // Notify EditorProvider of content change
      final editor = Provider.of<EditorProvider>(context, listen: false);
      editor.updateContent(newText);
    }
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_textController.text);
    final prev = _undoStack.removeLast();
    _textController.removeListener(_onTextChanged);
    _textController.text = prev;
    _lastText = prev;
    _textController.addListener(_onTextChanged);
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_textController.text);
    final next = _redoStack.removeLast();
    _textController.removeListener(_onTextChanged);
    _textController.text = next;
    _lastText = next;
    _textController.addListener(_onTextChanged);
    setState(() {});
  }

  void _loadFile() {
    final editor = Provider.of<EditorProvider>(context, listen: false);
    
    // Add a listener to EditorProvider so we can update when active tab changes
    editor.addListener(_onEditorTabChanged);

    final fileName = widget.filePath.split('/').last.split('\\').last;

    // Open the file in the editor provider (handles tab management)
    editor.openFile(widget.filePath, fileName).then((_) {
      _syncWithActiveTab();
    }).catchError((_) {
      // Fallback: load directly from filesystem
      _loadFileDirect();
    });
  }

  void _onEditorTabChanged() {
    if (mounted) {
      _syncWithActiveTab();
    }
  }

  void _syncWithActiveTab() {
    final editor = Provider.of<EditorProvider>(context, listen: false);
    final tab = editor.activeTab;
    if (tab != null) {
      if (_lastText != tab.content) {
        _textController.removeListener(_onTextChanged);
        _textController.language = _getLanguageForPath(tab.filePath);
        _textController.text = tab.content;
        _lastText = tab.content;
        _textController.addListener(_onTextChanged);
        _analyzeDiagnostics(tab.content);
        setState(() {});
      }
    }
  }

  dynamic _getLanguageForPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart': return dart;
      case 'js': case 'jsx': return javascript;
      case 'ts': case 'tsx': return typescript;
      case 'html': return xml;
      case 'css': return css;
      case 'json': return json;
      case 'md': return markdown;
      case 'py': return python;
      default: return null;
    }
  }

  /// Direct filesystem load as fallback
  void _loadFileDirect() {
    if (kIsWeb) return;

    try {
      final file = File(widget.filePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        _textController.text = content;
        _lastText = content;
        _analyzeDiagnostics(content);
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
    }
  }

  void _analyzeDiagnostics(String content) {
    _diagnostics.clear();
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Simple heuristics for demonstration
      if (line.contains('= 0;') && (i + 1 < lines.length)) {
        final nextLine = lines[i + 1];
        if (nextLine.contains('/ b') || nextLine.contains('/b')) {
          _diagnostics[i + 1] = 'Potential division by zero';
        }
      }
    }
    setState(() {});
  }

  Future<void> _saveFile() async {
    setState(() => _isSaving = true);

    // Save via EditorProvider (handles auto-save, dirty tracking)
    final editor = Provider.of<EditorProvider>(context, listen: false);
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);

    if (editor.activeTab != null) {
      await editor.saveCurrentFile();
    }

    // Also save via WorkspaceProvider for consistency
    await workspace.saveFile(widget.filePath, _textController.text);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File Saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _onSendPrompt() {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    // Send via ChatProvider so it appears in main chat history too
    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.sendMessageFromEditor(text, _textController.text);
    _promptController.clear();
  }

  Future<void> _onAddFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      final ext = file.name.split('.').last.toLowerCase();
      final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
      setState(() {
        _attachments.add(ChatAttachment(
          name: file.name,
          type: isImage ? 'image' : 'file',
          bytes: isImage ? file.bytes : null,
          mimeType: ext,
        ));
      });
    }
  }

  @override
  void dispose() {
    final editor = Provider.of<EditorProvider>(context, listen: false);
    editor.removeListener(_onEditorTabChanged);
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    _textController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = Provider.of<EditorProvider>(context);
    final activePath = editor.activeTab?.filePath ?? widget.filePath;

    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    final parts = activePath.isEmpty
        ? ['main_folder', 'main.dart']
        : activePath.replaceAll('\\', '/').split('/');
    final folder = parts.length > 1 ? parts[parts.length - 2] : 'project';
    final filename = parts.isNotEmpty ? parts.last : 'main.dart';


    final canUndo = _undoStack.isNotEmpty;
    final canRedo = _redoStack.isNotEmpty;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (mounted) popOrGo(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B0D1A),
          body: SafeArea(
        child: Column(
          children: [
            // ── Header row (matches reference: back, skip-back | undo, redo) ─────
            _buildHeader(s, filename, canUndo, canRedo),

            // ── Tabs ──────────────────────────────────────────────────────────
            const EditorTabBar(),

            // ── Breadcrumb ─────────────────────────────────────────────────────
            _buildBreadcrumb(folder, filename, s),

            // ── Code Editor Area ───────────────────────────────────────────────
            Expanded(
              child: RepaintBoundary(
                child: Container(
                  margin: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1117),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16 * s),
                    child: CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: CodeField(
                        controller: _textController,
                        textStyle: TextStyle(
                          fontSize: 14 * s,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                        expands: true,
                      ),
                    ),
                  ),
                ),
            ),
            ),

            // ── IDE Bottom Panel (Terminal, etc) ──────────────────────────────
            IdeBottomPanel(scale: s),

            // ── Chat Input Bar ─────────────────────────────────────────────────
            ChatInputBar(
              aiNamePillText: '',
              onAddFiles: _onAddFiles,
              onSend: _onSendPrompt,
              controller: _promptController,
              attachments: _attachments,
              onRemoveAttachment: (i) => setState(() => _attachments.removeAt(i)),
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildHeader(double s, String filename, bool canUndo, bool canRedo) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      child: Row(
        children: [
          // Skip-all-back button (go to start)
          _headerBtn(
            icon: Icons.keyboard_double_arrow_left,
            s: s,
            onTap: () => context.go('/main'),
          ),
          SizedBox(width: 8 * s),
          // Back button
          _headerBtn(
            icon: Icons.chevron_left,
            s: s,
            onTap: () => popOrGo(context),
          ),



          // Undo button
          _headerBtn(
            icon: Icons.undo_rounded,
            s: s,
            onTap: canUndo ? _undo : null,
            enabled: canUndo,
          ),
          SizedBox(width: 8 * s),
          // Redo button
          _headerBtn(
            icon: Icons.redo_rounded,
            s: s,
            onTap: canRedo ? _redo : null,
            enabled: canRedo,
          ),
          SizedBox(width: 8 * s),
          // Save button
          GestureDetector(
            onTap: _isSaving ? null : _saveFile,
            child: Container(
              height: 36 * s,
              padding: EdgeInsets.symmetric(horizontal: 14 * s),
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(10 * s),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 16 * s,
                      height: 16 * s,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_outlined,
                            color: Colors.white, size: 14 * s),
                        SizedBox(width: 6 * s),
                        Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn({
    required IconData icon,
    required double s,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final color = enabled
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.25);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40 * s,
        height: 40 * s,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(
            color: const Color(0xFF30363D),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 20 * s),
      ),
    );
  }

  Widget _buildBreadcrumb(String folder, String filename, double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF30363D)),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4 * s, vertical: 4 * s),
        child: Row(
          children: [
            Icon(Icons.folder_outlined,
                color: const Color(0xFF8B5FE8), size: 14 * s),
            SizedBox(width: 8 * s),
            Text(
              '$folder  >>  $filename',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12 * s,
                fontFamily: 'monospace',
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // Diagnostics count badge
            if (_diagnostics.isNotEmpty)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10 * s),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppColors.error, size: 6 * s),
                    SizedBox(width: 4 * s),
                    Text(
                      '${_diagnostics.length} issue${_diagnostics.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }




}
