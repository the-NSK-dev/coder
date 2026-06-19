import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart';
import 'premium_error_state.dart';

/// Attachment data shown inside the chat bar.
class ChatAttachment {
  final String name;
  final String type; // 'image', 'file', 'folder'
  final Uint8List? bytes;
  final String? mimeType;

  const ChatAttachment({
    required this.name,
    required this.type,
    this.bytes,
    this.mimeType,
  });
}

/// Bottom-anchored chat input bar with attachments preview,
/// text field, "Add files" button, and send button.
/// Models/AI name pill removed per requirements.
class ChatInputBar extends StatelessWidget {
  // aiNamePillText kept for API compat but not rendered
  final String aiNamePillText;
  final VoidCallback onAddFiles;
  final VoidCallback onSend;
  final TextEditingController controller;
  final bool readOnly;
  final bool disabled;
  final String? errorMessage;
  final VoidCallback? onTap;
  final List<ChatAttachment> attachments;
  final void Function(int index)? onRemoveAttachment;
  final void Function(int index)? onTapAttachment;
  final ChatScope? chatScope;
  final void Function(ChatScope scope)? onScopeChanged;
  final bool hasApiKey;

  const ChatInputBar({
    super.key,
    required this.aiNamePillText,
    required this.onAddFiles,
    required this.onSend,
    required this.controller,
    this.readOnly = false,
    this.disabled = false,
    this.errorMessage,
    this.onTap,
    this.attachments = const [],
    this.onRemoveAttachment,
    this.onTapAttachment,
    this.chatScope,
    this.onScopeChanged,
    this.hasApiKey = true,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input container
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error banner
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20 * s),
                        topRight: Radius.circular(20 * s),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 14 * s),
                        SizedBox(width: 6 * s),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Attachment strip (inside bar)
                if (attachments.isNotEmpty)
                  Container(
                    padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(attachments.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8 * s),
                            child: _buildAttachmentChip(attachments[i], i, s),
                          );
                        }),
                      ),
                    ),
                  ),

                // Text field or fallback
                if (!hasApiKey)
                  PremiumErrorState(
                    severity: ErrorSeverity.info,
                    title: 'No model connected',
                    message: 'Add an AIML API or Featherless key in Settings to start chatting with agents.',
                    actionLabel: 'Open Settings →',
                    dismissible: false,
                    onAction: () => GoRouter.of(context).push('/profile'),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 4 * s),
                    child: TextField(
                      controller: controller,
                      readOnly: readOnly || disabled,
                      onTap: onTap,
                      enabled: !disabled,
                      style: TextStyle(
                        color: disabled ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 14 * s,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: disabled ? 'Cannot send messages' : 'Build a app...... !',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 14 * s,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),

                // Bottom row: scope + Add files + Send
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * s, 0, 10 * s, 10 * s),
                  child: Row(
                    children: [
                      // Add files pill button
                      GestureDetector(
                        onTap: onAddFiles,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * s,
                            vertical: 6 * s,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20 * s),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16 * s,
                              ),
                              SizedBox(width: 6 * s),
                              Text(
                                'Attach',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12 * s,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Send button
                      GestureDetector(
                        onTap: (disabled || !hasApiKey) ? null : onSend,
                        child: Container(
                          width: 36 * s,
                          height: 36 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (disabled || !hasApiKey) ? AppColors.surfaceAlt : AppColors.accentBlue,
                            boxShadow: (disabled || !hasApiKey) ? [] : [
                              AppColors.glow(AppColors.accentBlue, blur: 16),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 18 * s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12 * s),
        ],
      ),
    );
  }

  Widget _scopePill(double s) {
    final isFolder = chatScope == ChatScope.folder;
    return GestureDetector(
      onTap: () => onScopeChanged!(
        isFolder ? ChatScope.project : ChatScope.folder,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.4),
          ),
          color: AppColors.accentBlue.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isFolder ? Icons.folder_outlined : Icons.layers_outlined,
                key: ValueKey(isFolder),
                color: AppColors.accentBlue,
                size: 14 * s,
              ),
            ),
            SizedBox(width: 4 * s),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isFolder ? 'Folder' : 'Project',
                key: ValueKey(isFolder),
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 4 * s),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.accentBlue.withValues(alpha: 0.7),
              size: 14 * s,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(ChatAttachment attachment, int index, double s) {
    final isImage = attachment.type == 'image' && attachment.bytes != null;
    final isFolder = attachment.type == 'folder';

    return Container(
      constraints: BoxConstraints(maxWidth: 130 * s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10 * s),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => onTapAttachment?.call(index),
            child: Padding(
              padding: EdgeInsets.all(8 * s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6 * s),
                      child: Image.memory(
                        attachment.bytes!,
                        width: 32 * s,
                        height: 32 * s,
                        fit: BoxFit.cover,
                      ),
                    )
                else
                  Container(
                    width: 32 * s,
                    height: 32 * s,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6 * s),
                    ),
                    child: Icon(
                      isFolder
                          ? Icons.folder_outlined
                          : _fileIcon(attachment.name),
                      color: AppColors.accentBlue,
                      size: 16 * s,
                    ),
                  ),
                SizedBox(width: 8 * s),
                Flexible(
                  child: Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 4 * s),
              ],
            ),
          ),
          ),
          // Remove button
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: () => onRemoveAttachment?.call(index),
              child: Container(
                width: 18 * s,
                height: 18 * s,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 10 * s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'kt':
      case 'swift':
      case 'cpp':
      case 'c':
      case 'h':
      case 'go':
      case 'rs':
        return Icons.code;
      case 'md':
      case 'txt':
      case 'doc':
      case 'docx':
        return Icons.article_outlined;
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return Icons.data_object;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
