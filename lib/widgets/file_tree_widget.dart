import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../theme/app_colors.dart';

class FileTreeNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileTreeNode> children;
  bool isExpanded;
  bool isLoading;

  FileTreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
    this.isExpanded = false,
    this.isLoading = false,
  });
}

class FileTreeWidget extends StatefulWidget {
  final List<FileTreeNode> nodes;
  final Function(String path) onFileTap;
  final Future<List<FileTreeNode>> Function(FileTreeNode node)? onLoadChildren;
  final Function(String path, bool isDirectory)? onRenameNode;
  final Function(String path, bool isDirectory)? onDeleteNode;

  const FileTreeWidget({
    super.key,
    required this.nodes,
    required this.onFileTap,
    this.onLoadChildren,
    this.onRenameNode,
    this.onDeleteNode,
  });

  @override
  State<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends State<FileTreeWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.nodes.map((node) => _buildNode(node, 0)).toList(),
    );
  }

  Widget _buildNode(FileTreeNode node, int depth) {
    return _FileTreeNodeItem(
      key: ValueKey(node.path),
      node: node,
      depth: depth,
      onFileTap: widget.onFileTap,
      onLoadChildren: widget.onLoadChildren,
      onRenameNode: widget.onRenameNode,
      onDeleteNode: widget.onDeleteNode,
    );
  }
}

class _FileTreeNodeItem extends StatefulWidget {
  final FileTreeNode node;
  final int depth;
  final Function(String path) onFileTap;
  final Future<List<FileTreeNode>> Function(FileTreeNode node)? onLoadChildren;
  final Function(String path, bool isDirectory)? onRenameNode;
  final Function(String path, bool isDirectory)? onDeleteNode;

  const _FileTreeNodeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.onFileTap,
    this.onLoadChildren,
    this.onRenameNode,
    this.onDeleteNode,
  });

  @override
  State<_FileTreeNodeItem> createState() => _FileTreeNodeItemState();
}

class _FileTreeNodeItemState extends State<_FileTreeNodeItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _toggleExpand() async {
    setState(() {
      widget.node.isExpanded = !widget.node.isExpanded;
    });

    if (widget.node.isExpanded && widget.node.children.isEmpty && widget.onLoadChildren != null) {
      setState(() {
        widget.node.isLoading = true;
      });
      final children = await widget.onLoadChildren!(widget.node);
      setState(() {
        widget.node.children.addAll(children);
        widget.node.isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final ext = p.extension(widget.node.name).replaceAll('.', '').toLowerCase();
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'ico'].contains(ext);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              setState(() => _isPressed = false);
              if (widget.node.isDirectory) {
                _toggleExpand();
              } else {
                widget.onFileTap(widget.node.path);
              }
            },
            onDoubleTap: widget.node.isDirectory ? _toggleExpand : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              color: _isPressed 
                  ? Colors.white.withValues(alpha: 0.10) 
                  : _isHovered 
                      ? Colors.white.withValues(alpha: 0.05) 
                      : Colors.transparent,
              padding: EdgeInsets.only(
                left: 12 * s + (widget.depth * 14 * s),
                right: 12 * s,
                top: 4 * s,
                bottom: 4 * s,
              ),
              child: Row(
                children: [
                  if (widget.node.isDirectory)
                    widget.node.isLoading
                        ? SizedBox(
                            width: 16 * s,
                            height: 16 * s,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textMuted,
                            ),
                          )
                        : Icon(
                            widget.node.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            color: AppColors.textMuted,
                            size: 16 * s,
                          )
                  else
                    SizedBox(width: 16 * s),
                  SizedBox(width: 4 * s),
                  Icon(
                    widget.node.isDirectory
                        ? (widget.node.isExpanded ? Icons.folder_open : Icons.folder)
                        : _iconForExt(ext),
                    color: widget.node.isDirectory ? const Color(0xFFDCAA60) : _colorForExt(ext),
                    size: 16 * s,
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      widget.node.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13 * s,
                        fontWeight: widget.node.isDirectory ? FontWeight.w500 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.node.isDirectory && ext.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1.5 * s),
                      decoration: BoxDecoration(
                        color: _colorForExt(ext).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4 * s),
                      ),
                      child: Text(
                        ext.toUpperCase(),
                        style: TextStyle(
                          color: _colorForExt(ext),
                          fontSize: 9 * s,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  if (isImage) ...[
                    SizedBox(width: 6 * s),
                    Icon(Icons.photo_size_select_actual_outlined, color: AppColors.textMuted, size: 12 * s),
                  ],
                  if (_isHovered && widget.onRenameNode != null) ...[
                    SizedBox(width: 8 * s),
                    GestureDetector(
                      onTap: () => widget.onRenameNode!(widget.node.path, widget.node.isDirectory),
                      child: Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 14 * s),
                    ),
                  ],
                  if (_isHovered && widget.onDeleteNode != null) ...[
                    SizedBox(width: 8 * s),
                    GestureDetector(
                      onTap: () => widget.onDeleteNode!(widget.node.path, widget.node.isDirectory),
                      child: Icon(Icons.delete_outline, color: AppColors.error, size: 14 * s),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.node.isDirectory && widget.node.isExpanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: widget.node.children.isNotEmpty
                ? Container(
                    margin: EdgeInsets.only(
                        left: 16 * s + (widget.depth * 16 * s)),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.node.children.map((childNode) {
                        return _FileTreeNodeItem(
                          key: ValueKey(childNode.path),
                          node: childNode,
                          depth: widget.depth + 1,
                          onFileTap: widget.onFileTap,
                          onLoadChildren: widget.onLoadChildren,
                          onRenameNode: widget.onRenameNode,
                          onDeleteNode: widget.onDeleteNode,
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  IconData _iconForExt(String ext) {
    switch (ext) {
      case 'dart': return Icons.flutter_dash;
      case 'js': case 'jsx': case 'ts': case 'tsx': case 'mjs': return Icons.javascript;
      case 'html': return Icons.html;
      case 'css': case 'scss': case 'sass': return Icons.css;
      case 'json': case 'yaml': case 'yml': return Icons.data_object;
      case 'md': case 'mdx': case 'txt': return Icons.article_outlined;
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'webp': case 'svg': case 'ico': case 'bmp': return Icons.image_outlined;
      case 'py': case 'java': case 'kt': case 'swift': case 'go': case 'rs': case 'cpp': case 'c': case 'h': case 'hpp': return Icons.code;
      case 'sh': case 'bash': case 'zsh': case 'fish': case 'ps1': return Icons.terminal;
      case 'sql': return Icons.storage_outlined;
      case 'xml': return Icons.code;
      case 'env': case 'gitignore': case 'dockerfile': return Icons.settings_outlined;
      case 'lock': case 'toml': case 'ini': case 'cfg': case 'conf': return Icons.tune_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorForExt(String ext) {
    switch (ext) {
      case 'dart': return const Color(0xFF54C5F8);
      case 'js': case 'jsx': case 'mjs': return const Color(0xFFF7DF1E);
      case 'ts': case 'tsx': return const Color(0xFF3178C6);
      case 'html': return const Color(0xFFE34C26);
      case 'css': case 'scss': case 'sass': return const Color(0xFF264DE4);
      case 'json': return const Color(0xFF43A047);
      case 'yaml': case 'yml': return const Color(0xFF81C784);
      case 'md': case 'mdx': case 'txt': return Colors.white70;
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'webp': case 'svg': case 'ico': return const Color(0xFFBA68C8);
      case 'py': return const Color(0xFF3776AB);
      case 'java': return const Color(0xFFED8B00);
      case 'kt': return const Color(0xFF7F52FF);
      case 'swift': return const Color(0xFFFA7343);
      case 'go': return const Color(0xFF00ACD7);
      case 'rs': return const Color(0xFFDEA584);
      case 'cpp': case 'c': case 'h': case 'hpp': return const Color(0xFF6295CB);
      case 'sh': case 'bash': case 'zsh': return const Color(0xFF89E051);
      case 'sql': return const Color(0xFF00758F);
      case 'env': return const Color(0xFFECC94B);
      default: return AppColors.textSecondary;
    }
  }
}
