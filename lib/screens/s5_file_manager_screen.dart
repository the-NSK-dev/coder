import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../theme/app_colors.dart';
import '../config/app_config.dart';
import '../providers/ide_provider.dart';
import '../providers/editor_provider.dart';
import '../widgets/coder_app_bar.dart';
import '../widgets/editor_tab_bar.dart';
import '../widgets/file_tree_widget.dart';
import '../widgets/hover_press_region.dart';
import '../widgets/premium_error_state.dart';
import '../utils/nav_utils.dart';
const _imageExtensions = {
  'png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'ico', 'bmp',
};

/// Screen 5 — File Manager screen with nested folder tree.
class S5FileManagerScreen extends StatefulWidget {
  final VoidCallback? onClosePanel;

  const S5FileManagerScreen({super.key, this.onClosePanel});

  @override
  State<S5FileManagerScreen> createState() => _S5FileManagerScreenState();
}

class _S5FileManagerScreenState extends State<S5FileManagerScreen> {
  bool _isLoading = false;
  int _panelTab = 0;
  List<FileTreeNode> _treeNodes = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDirectory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _loadDirectory() {
    setState(() => _isLoading = true);

    if (AppConfig.currentProjectDir == null ||
        AppConfig.currentProjectDir!.isEmpty) {
      setState(() {
        _isLoading = false;
        _treeNodes = [];
      });
      return;
    }

    if (kIsWeb) {
      setState(() {
        _isLoading = false;
        _treeNodes = [];
      });
      return;
    }

    try {
      final dir = Directory(AppConfig.currentProjectDir!);
      if (dir.existsSync()) {
        _treeNodes = _buildNodes(dir);
      }
    } catch (e) {
      debugPrint('Error loading directory: $e');
    }

    setState(() => _isLoading = false);
  }

  List<FileTreeNode> _buildNodes(Directory dir) {
    try {
      final entities = dir.listSync().toList()
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.compareTo(b.path);
        });
      return entities
          .map((e) => FileTreeNode(
                name: p.basename(e.path),
                path: e.path,
                isDirectory: e is Directory,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FileTreeNode>> _loadSubNodes(FileTreeNode node) async {
    if (kIsWeb) return [];
    try {
      final dir = Directory(node.path);
      if (dir.existsSync()) {
        return _buildNodes(dir);
      }
    } catch (e) {
      debugPrint('Failed to load directory: $e');
    }
    return [];
  }

  Future<void> _openFolder() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Native App Required to access local file system.')),
      );
      return;
    }

    try {
      final path = await FilePicker.getDirectoryPath();
      if (path != null) {
        AppConfig.currentProjectDir = path;
        _loadDirectory();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error opening folder: $e')));
    }
  }

  void _onFileTap(String path) {
    final ext = path.split('.').last.toLowerCase();

    if (_imageExtensions.contains(ext)) {
      _showImagePreview(path);
    } else {
      // Use the EditorProvider to open the file and manage its tab
      final editor = Provider.of<EditorProvider>(context, listen: false);
      editor.openFile(path, p.basename(path));
      context.push('/editor', extra: path);
    }
  }

  void _showImagePreview(String path) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(24 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined,
                          color: AppColors.accentBlue, size: 18 * s),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: Text(
                          p.basename(path),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18 * s),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: kIsWeb
                      ? Center(
                          child: Text('Image preview N/A on web',
                              style: TextStyle(color: AppColors.textSecondary)))
                      : Image.file(File(path),
                          fit: BoxFit.contain,
                          errorBuilder: (_, e, _) => Padding(
                                padding: EdgeInsets.all(24 * s),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_outlined,
                                        color: AppColors.textMuted,
                                        size: 40 * s),
                                    SizedBox(height: 8 * s),
                                    Text('Cannot load image',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              )),
                ),
                SizedBox(height: 16 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }



  List<FileTreeNode> get _filteredNodes {
    if (_searchQuery.isEmpty) return _treeNodes;
    return _treeNodes
        .where((n) =>
            n.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    final hasNoProject = AppConfig.currentProjectDir == null ||
        AppConfig.currentProjectDir!.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CoderAppBar(
              onBack: () {
                if (widget.onClosePanel != null) {
                  widget.onClosePanel!();
                } else {
                  popOrGo(context);
                }
              },
              showLogo: false,
              title: 'Files',
              actions: [
                AppBarAction(
                  icon: Icons.folder_open,
                  onTap: _openFolder,
                ),
                AppBarAction(
                  icon: Icons.refresh,
                  onTap: _loadDirectory,
                ),
              ],
            ),

            // Project path bar
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
              color: AppColors.surface.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined,
                      color: AppColors.accentPurple, size: 16 * s),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      AppConfig.currentProjectDir ??
                          'Select a project to begin',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12 * s,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 10 * s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40 * s,
                decoration: BoxDecoration(
                  color: _searchFocus.hasFocus
                      ? AppColors.surface
                      : AppColors.surfaceAlt.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(
                    color: _searchFocus.hasFocus
                        ? AppColors.accentBlue
                        : AppColors.border,
                    width: _searchFocus.hasFocus ? 1.5 : 1.0,
                  ),
                  boxShadow: _searchFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 14 * s),
                    Icon(
                      Icons.search,
                      color: _searchFocus.hasFocus
                          ? AppColors.accentBlue
                          : AppColors.textMuted,
                      size: 18 * s,
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search files and folders...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14 * s,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _searchFocus.requestFocus();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12 * s),
                          child: Icon(Icons.close,
                              color: AppColors.textPrimary, size: 16 * s),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            FileManagerTabBar(
              selectedIndex: _panelTab,
              onSelected: (i) => setState(() => _panelTab = i),
            ),

            // Toolbar
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16 * s, vertical: 10 * s),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  _toolbarIcon(Icons.create_new_folder_outlined, s,
                      onTap: () => _createItem(isFolder: true)),
                  SizedBox(width: 8 * s),
                  _toolbarIcon(Icons.note_add_outlined, s, 
                      onTap: () => _createItem(isFolder: false)),

                  const Spacer(),
                  // Legend chips
                  _legendChip(Icons.code, 'Code', AppColors.accentBlue, s),
                  SizedBox(width: 6 * s),
                  _legendChip(Icons.image_outlined, 'Image',
                      AppColors.accentPurple, s),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue))
                  : _panelTab == 1
                      ? _buildOpenEditors(s)
                      : hasNoProject
                          ? _buildEmptyState(s)
                          : _buildFileTree(s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(
      IconData icon, String label, Color color, double s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12 * s),
        SizedBox(width: 3 * s),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10 * s,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72 * s,
            height: 72 * s,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.folder_open,
                color: AppColors.accentBlue, size: 36 * s),
          ),
          SizedBox(height: 20 * s),
          Text(
            'No Project Opened',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18 * s,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8 * s),
          Text(
            kIsWeb
                ? 'Use the Windows desktop app to open local project folders.'
                : 'Open a folder to start working',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14 * s,
              height: 1.5,
            ),
          ),
          SizedBox(height: 28 * s),
          if (!kIsWeb)
            GestureDetector(
              onTap: _openFolder,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 28 * s, vertical: 14 * s),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentBlue, Color(0xFF2E65F3)],
                  ),
                  borderRadius: BorderRadius.circular(12 * s),
                  boxShadow: [
                    AppColors.glow(AppColors.accentBlue, blur: 20),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open,
                        color: Colors.white, size: 20 * s),
                    SizedBox(width: 10 * s),
                    Text(
                      'Open Folder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w700,
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

  Widget _buildOpenEditors(double s) {
    return Consumer<EditorProvider>(
      builder: (context, editor, _) {
        if (!editor.hasOpenTabs) {
          return Center(
            child: Text(
              'No open editors',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14 * s),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8 * s),
          itemCount: editor.tabs.length,
          itemBuilder: (context, i) {
            final tab = editor.tabs[i];
            final active = i == editor.activeTabIndex;
            return ListTile(
              dense: true,
              selected: active,
              selectedTileColor: AppColors.accentBlue.withValues(alpha: 0.08),
              leading: Icon(
                Icons.insert_drive_file_outlined,
                color: active ? AppColors.accentBlue : AppColors.textMuted,
                size: 18 * s,
              ),
              title: Text(
                tab.fileName,
                style: TextStyle(
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 13 * s,
                ),
              ),
              subtitle: Text(
                tab.filePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11 * s),
              ),
              onTap: () {
                editor.switchTab(i);
                context.push('/editor', extra: tab.filePath);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFileTree(double s) {
    final nodes = _filteredNodes;
    if (nodes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No files match "$_searchQuery"' : 'Empty Directory',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14 * s),
        ),
      );
    }

    return SingleChildScrollView(
      child: FileTreeWidget(
        nodes: nodes,
        onFileTap: _onFileTap,
        onLoadChildren: _loadSubNodes,
        onRenameNode: _renameNode,
        onDeleteNode: _deleteNode,
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, double s,
      {required VoidCallback onTap}) {
    return HoverPressRegion(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * s),
      child: Container(
        width: 32 * s,
        height: 32 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8 * s),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child:
              Icon(icon, color: AppColors.textPrimary, size: 16 * s),
        ),
      ),
    );
  }

  Future<void> _createItem({required bool isFolder}) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not supported on web')));
      return;
    }
    if (AppConfig.currentProjectDir == null || AppConfig.currentProjectDir!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open a project first to create items.')));
      return;
    }

    String? errorMsg;
    String initial = '';

    while (true) {
      final name = await _showInputDialog('New ${isFolder ? 'Folder' : 'File'}', 'Enter name', initialText: initial, errorMessage: errorMsg);
      if (name == null || name.trim().isEmpty || !mounted) return;

      final ide = Provider.of<IdeProvider>(context, listen: false);
      final path = p.join(AppConfig.currentProjectDir!, name.trim());
      try {
        if (isFolder) {
          await ide.projectFileService.createFolder(path);
        } else {
          await ide.projectFileService.createFile(path);
        }
        if (!mounted) return;
        _loadDirectory();
        break; // Success
      } catch (e) {
        errorMsg = e.toString().contains('exists') ? 'A file named "${name.trim()}" already exists in this folder.' : e.toString();
        initial = name;
      }
    }
  }

  Future<void> _renameNode(String path, bool isDirectory) async {
    if (kIsWeb) return;
    final oldName = p.basename(path);
    
    String? errorMsg;
    String initial = oldName;

    while (true) {
      final newName = await _showInputDialog('Rename', 'Enter new name', initialText: initial, errorMessage: errorMsg);
      if (newName == null || newName.trim().isEmpty || newName == oldName || !mounted) return;

      final ide = Provider.of<IdeProvider>(context, listen: false);
      final newPath = p.join(p.dirname(path), newName.trim());
      try {
        await ide.projectFileService.renameItem(path, newPath, isDirectory);
        if (!mounted) return;
        _loadDirectory();
        break; // Success
      } catch (e) {
        errorMsg = e.toString().contains('exists') ? 'A file named "${newName.trim()}" already exists in this folder.' : e.toString();
        initial = newName;
      }
    }
  }

  Future<void> _deleteNode(String path, bool isDirectory) async {
    if (kIsWeb) return;
    final name = p.basename(path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text('Delete $name?', style: const TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete this ${isDirectory ? 'folder' : 'file'}?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final ide = Provider.of<IdeProvider>(context, listen: false);
      try {
        await ide.projectFileService.deleteItem(path, isDirectory);
        if (!mounted) return;
        _loadDirectory();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _showInputDialog(String title, String hint, {String initialText = '', String? errorMessage}) async {
    String value = initialText;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null) ...[
              PremiumErrorState(
                severity: ErrorSeverity.warning,
                title: 'Name already in use',
                message: errorMessage,
                dismissible: false,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentBlue)),
              ),
              controller: TextEditingController(text: initialText),
              onChanged: (v) => value = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, value), child: const Text('OK', style: TextStyle(color: AppColors.accentBlue))),
        ],
      ),
    );
  }
}
