import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/project_file_service.dart';

/// Represents a single open editor tab.
class EditorTab {
  final String filePath;
  final String fileName;
  String content;
  String _savedContent;
  bool get isDirty => content != _savedContent;

  EditorTab({
    required this.filePath,
    required this.fileName,
    required this.content,
  }) : _savedContent = content;

  void markSaved() {
    _savedContent = content;
  }
}

/// Manages multi-tab editor state: open tabs, active tab, auto-save, dirty tracking.
class EditorProvider extends ChangeNotifier {
  final ProjectFileService _fileService = ProjectFileService();

  final List<EditorTab> _tabs = [];
  int _activeTabIndex = -1;
  bool _autoSaveEnabled = true;
  Timer? _autoSaveTimer;
  String _searchQuery = '';
  String _replaceQuery = '';
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  // ── Auto-save config ────────────────────────────────────
  static const int _autoSaveDelayMs = 2000;

  // ── Getters ─────────────────────────────────────────────
  List<EditorTab> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  EditorTab? get activeTab =>
      _activeTabIndex >= 0 && _activeTabIndex < _tabs.length
          ? _tabs[_activeTabIndex]
          : null;
  bool get hasOpenTabs => _tabs.isNotEmpty;
  bool get autoSaveEnabled => _autoSaveEnabled;
  String get searchQuery => _searchQuery;
  String get replaceQuery => _replaceQuery;
  List<int> get searchMatches => _searchMatches;
  int get currentMatchIndex => _currentMatchIndex;
  bool get hasUnsavedChanges => _tabs.any((t) => t.isDirty);

  // ── Open a file in a new tab (or switch to existing) ────
  Future<void> openFile(String filePath, String fileName) async {
    // Check if already open
    final existingIndex = _tabs.indexWhere((t) => t.filePath == filePath);
    if (existingIndex >= 0) {
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    try {
      final content = await _fileService.readFile(filePath);
      _tabs.add(EditorTab(
        filePath: filePath,
        fileName: fileName,
        content: content,
      ));
      _activeTabIndex = _tabs.length - 1;
      notifyListeners();
    } catch (e) {
      // File might not exist yet — open with empty content
      _tabs.add(EditorTab(
        filePath: filePath,
        fileName: fileName,
        content: '',
      ));
      _activeTabIndex = _tabs.length - 1;
      notifyListeners();
    }
  }

  // ── Close a tab ─────────────────────────────────────────
  Future<bool> closeTab(int index, {bool forceSave = false}) async {
    if (index < 0 || index >= _tabs.length) return false;

    final tab = _tabs[index];

    // Auto-save dirty tabs before closing
    if (tab.isDirty && (forceSave || _autoSaveEnabled)) {
      await _saveTab(tab);
    }

    _tabs.removeAt(index);

    // Adjust active index
    if (_tabs.isEmpty) {
      _activeTabIndex = -1;
    } else if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    } else if (_activeTabIndex > index) {
      _activeTabIndex--;
    }

    notifyListeners();
    return true;
  }

  // ── Switch active tab ───────────────────────────────────
  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      _clearSearch();
      notifyListeners();
    }
  }

  // ── Update content (called on every keystroke) ──────────
  void updateContent(String newContent) {
    if (activeTab == null) return;
    activeTab!.content = newContent;
    notifyListeners();

    // Debounced auto-save
    if (_autoSaveEnabled) {
      _scheduleAutoSave();
    }
  }

  // ── Insert AI-generated code at position ────────────────
  void insertCodeAtCursor(String code, int cursorPosition) {
    if (activeTab == null) return;
    final current = activeTab!.content;
    final clamped = cursorPosition.clamp(0, current.length);
    activeTab!.content =
        current.substring(0, clamped) + code + current.substring(clamped);
    notifyListeners();

    if (_autoSaveEnabled) {
      _scheduleAutoSave();
    }
  }

  // ── Manual save ─────────────────────────────────────────
  Future<void> saveCurrentFile() async {
    if (activeTab == null) return;
    await _saveTab(activeTab!);
    notifyListeners();
  }

  Future<void> saveAllFiles() async {
    for (final tab in _tabs) {
      if (tab.isDirty) {
        await _saveTab(tab);
      }
    }
    notifyListeners();
  }

  // ── Search ──────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    _findMatches();
    notifyListeners();
  }

  void setReplaceQuery(String query) {
    _replaceQuery = query;
    notifyListeners();
  }

  void nextMatch() {
    if (_searchMatches.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    notifyListeners();
  }

  void previousMatch() {
    if (_searchMatches.isEmpty) return;
    _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) %
        _searchMatches.length;
    notifyListeners();
  }

  void replaceCurrent() {
    if (activeTab == null ||
        _searchMatches.isEmpty ||
        _currentMatchIndex < 0) {
      return;
    }

    final pos = _searchMatches[_currentMatchIndex];
    final content = activeTab!.content;
    activeTab!.content = content.substring(0, pos) +
        _replaceQuery +
        content.substring(pos + _searchQuery.length);
    _findMatches();
    notifyListeners();

    if (_autoSaveEnabled) _scheduleAutoSave();
  }

  void replaceAll() {
    if (activeTab == null || _searchQuery.isEmpty) return;
    activeTab!.content =
        activeTab!.content.replaceAll(_searchQuery, _replaceQuery);
    _findMatches();
    notifyListeners();

    if (_autoSaveEnabled) _scheduleAutoSave();
  }

  void _findMatches() {
    _searchMatches = [];
    _currentMatchIndex = -1;
    if (activeTab == null || _searchQuery.isEmpty) return;

    final content = activeTab!.content;
    int start = 0;
    while (true) {
      final index = content.indexOf(_searchQuery, start);
      if (index == -1) break;
      _searchMatches.add(index);
      start = index + 1;
    }
    if (_searchMatches.isNotEmpty) _currentMatchIndex = 0;
  }

  void _clearSearch() {
    _searchQuery = '';
    _replaceQuery = '';
    _searchMatches = [];
    _currentMatchIndex = -1;
  }

  // ── Auto-save logic ─────────────────────────────────────
  void setAutoSave(bool enabled) {
    _autoSaveEnabled = enabled;
    if (!enabled) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
    }
    notifyListeners();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: _autoSaveDelayMs),
      () async {
        if (activeTab != null && activeTab!.isDirty) {
          await _saveTab(activeTab!);
          notifyListeners();
        }
      },
    );
  }

  Future<void> _saveTab(EditorTab tab) async {
    try {
      await _fileService.updateFile(tab.filePath, tab.content);
      tab.markSaved();
    } catch (e) {
      debugPrint('Auto-save failed for ${tab.fileName}: $e');
    }
  }

  // ── Cleanup ─────────────────────────────────────────────
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // ── Handle file rename/delete externally ────────────────
  void onFileRenamed(String oldPath, String newPath, String newName) {
    for (final tab in _tabs) {
      if (tab.filePath == oldPath) {
        // Update the tab's path reference
        // Since fields are final, we need to close and reopen
        final content = tab.content;
        final index = _tabs.indexOf(tab);
        _tabs[index] = EditorTab(
          filePath: newPath,
          fileName: newName,
          content: content,
        );
        break;
      }
    }
    notifyListeners();
  }

  void onFileDeleted(String path) {
    final index = _tabs.indexWhere((t) => t.filePath == path);
    if (index >= 0) {
      _tabs.removeAt(index);
      if (_tabs.isEmpty) {
        _activeTabIndex = -1;
      } else if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      }
      notifyListeners();
    }
  }
}
