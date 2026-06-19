import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import 'premium_tab_bar.dart';

/// VS Code / Cursor style horizontal tab bar for the multi-tab code editor.
class EditorTabBar extends StatefulWidget {
  const EditorTabBar({super.key});

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editor, _) {
        if (!editor.hasOpenTabs) return const SizedBox.shrink();

        final tabs = editor.tabs.map((tab) => TabItem(
          id: tab.filePath,
          label: tab.fileName,
          icon: _getFileIcon(tab.fileName),
          isDirty: tab.isDirty,
        )).toList();

        final activeTabId = editor.activeTab?.filePath ?? '';

        return PremiumTabBar(
          tabs: tabs,
          activeTabId: activeTabId,
          scrollable: true,
          onTabSelected: (id) {
            final idx = editor.tabs.indexWhere((t) => t.filePath == id);
            if (idx >= 0) editor.switchTab(idx);
          },
          onTabClosed: (id) {
            final idx = editor.tabs.indexWhere((t) => t.filePath == id);
            if (idx >= 0) editor.closeTab(idx);
          },
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return Icons.flutter_dash;
      case 'html':
      case 'htm':
        return Icons.html_rounded;
      case 'css':
        return Icons.css_rounded;
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return Icons.javascript_rounded;
      case 'json':
        return Icons.data_object_rounded;
      case 'md':
        return Icons.description_rounded;
      case 'yaml':
      case 'yml':
        return Icons.settings_rounded;
      case 'py':
        return Icons.code_rounded;
      case 'java':
        return Icons.coffee_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'svg':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

}

/// VS Code-style panel tabs for the file manager (Explorer / Open Editors).
class FileManagerTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String> tabs;

  const FileManagerTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.tabs = const ['EXPLORER', 'OPEN EDITORS'],
  });

  @override
  Widget build(BuildContext context) {
    final tabItems = tabs.asMap().entries.map((e) => TabItem(
      id: e.key.toString(),
      label: e.value,
    )).toList();

    return PremiumTabBar(
      tabs: tabItems,
      activeTabId: selectedIndex.toString(),
      scrollable: false,
      onTabSelected: (id) => onSelected(int.parse(id)),
    );
  }
}
