import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/agent_activity_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/coder_app_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/project_status_card.dart';
import '../widgets/desktop_split_view.dart';
import '../theme/app_colors.dart';

// Import panels for desktop mode
import 's5_file_manager_screen.dart';
import 's7_preview_fullscreen.dart';
import 's14_image_editor_screen.dart';

/// Screen 2 — Unified Main Workspace screen.
class S2MainEmptyScreen extends StatefulWidget {
  const S2MainEmptyScreen({super.key});

  @override
  State<S2MainEmptyScreen> createState() => _S2MainEmptyScreenState();
}

class _S2MainEmptyScreenState extends State<S2MainEmptyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatAttachment> _attachments = [];
  Widget? _rightPanel; // For desktop split view

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _promptController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    final chat = Provider.of<ChatProvider>(context, listen: false);
    chat.sendMessage(text, attachments: List.from(_attachments));
    _promptController.clear();
    setState(() {
      _attachments.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
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
          bytes: file.bytes,
          mimeType: ext,
        ));
      });
    }
  }

  void _openRightPanelOrRoute(BuildContext context, Widget panelWidget, String route) {
    final sw = MediaQuery.of(context).size.width;
    if (sw > 800) {
      setState(() => _rightPanel = panelWidget);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final isDesktop = sw > 800;

    final mainContent = SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // App Bar
              Consumer<WorkspaceProvider>(
                builder: (context, workspace, _) {
                  return CoderAppBar(
                    onAvatarTap: () => context.push('/profile'),
                    actions: [
                      AppBarAction(
                        icon: Icons.folder_outlined,
                        onTap: () => _openRightPanelOrRoute(
                          context,
                          S5FileManagerScreen(
                            onClosePanel: () => setState(() => _rightPanel = null),
                          ),
                          '/files',
                        ),
                      ),
                      if (workspace.isSupportedLanguage)
                        AppBarAction(
                          icon: Icons.play_arrow_outlined,
                          onTap: () => _openRightPanelOrRoute(
                            context,
                            S7PreviewFullscreen(
                              onClosePanel: () => setState(() => _rightPanel = null),
                            ),
                            '/preview/full',
                          ),
                        )

                      else
                        AppBarAction(
                          icon: Icons.play_disabled,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Preview not supported for this language')),
                            );
                          },
                        ),

                    ],
                  );
                },
              ),

              // Separator
            Container(
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.06),
            ),

            // Main content area: Logo behind, chat on top
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  final hasMessages = chat.messages.isNotEmpty;

                  return Column(
                    children: [
                      // Agent Status Bar — driven by background agent activity
                      Consumer<AgentActivityProvider>(
                        builder: (context, agents, _) {
                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16 * s, vertical: 10 * s),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1117),
                              border: Border(
                                  bottom: BorderSide(color: AppColors.border)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 520;
                                final roles = AgentRole.values;
                                if (compact) {
                                  return Wrap(
                                    spacing: 12 * s,
                                    runSpacing: 8 * s,
                                    children: roles
                                        .map((r) => _buildAgentStatus(
                                              r.label,
                                              agents.bandConnected &&
                                                  agents.statusFor(r.id) !=
                                                      'Idle',
                                              s,
                                            ))
                                        .toList(),
                                  );
                                }
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: roles
                                      .map((r) => _buildAgentStatus(
                                            r.label,
                                            agents.bandConnected &&
                                                agents.statusFor(r.id) !=
                                                    'Idle',
                                            s,
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                      // Background logo — always visible
                      Center(
                        child: AnimatedOpacity(
                          opacity: hasMessages ? 0.15 : 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              final g =
                                  0.2 + (_glowController.value * 0.2);
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(36 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentBlue
                                          .withValues(alpha: g),
                                      blurRadius: 60,
                                      spreadRadius: 18,
                                    ),
                                    BoxShadow(
                                      color: AppColors.accentPurple
                                          .withValues(
                                              alpha: g * 0.4),
                                      blurRadius: 100,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(36 * s),
                                  child: Image.asset(
                                    'assets/logo-center.png',
                                    width: 160 * s,
                                    height: 160 * s,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Container(
                                      width: 160 * s,
                                      height: 160 * s,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accentBlue,
                                            AppColors.accentPurple,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(
                                                36 * s),
                                      ),
                                      child: const Icon(Icons.code,
                                          color: Colors.white,
                                          size: 60),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Chat messages overlay (scrollable)
                      if (hasMessages || chat.isProcessing)
                        Positioned.fill(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16 * s),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16 * s),

                                  // Render each message
                                  for (final msg in chat.messages) ...[
                                    if (msg.sender == 'user')
                                      _buildUserBubble(msg, sw, s)
                                    else if (msg.sender == 'ai')
                                      _buildAiBubble(msg, s)
                                    else if (msg.sender == 'system')
                                      _buildSystemBubble(msg, s),
                                    SizedBox(height: 12 * s),
                                  ],

                                  if (chat.clarifyingQuestions != null)
                                    _buildClarifyingQuestions(chat, s),

                                  // Plan steps
                                if (chat.currentPlan != null) ...[
                                  Row(
                                    children: [
                                      Text(
                                        'Plan',
                                        style: TextStyle(
                                          color: AppColors.accentBlue,
                                          fontSize: 16 * s,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 8 * s),
                                      Text(
                                        '• ${_formatTime()}',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12 * s,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12 * s),
                                  Text(
                                    'To build the app we are going to follow these steps:',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13 * s,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 16 * s),
                                  for (int i = 0;
                                      i <
                                          chat.currentPlan!.steps
                                              .length;
                                      i++) ...[
                                    _buildStepRow(
                                        i + 1,
                                        chat.currentPlan!.steps[i],
                                        s),
                                    SizedBox(height: 12 * s),
                                  ],
                                  SizedBox(height: 8 * s),
                                  Text(
                                    "Let's start building your app...",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13 * s,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 16 * s),
                                ],

                                // Processing indicator
                                if (chat.isProcessing &&
                                    chat.currentPlan == null)
                                  Padding(
                                    padding: EdgeInsets.all(20 * s),
                                    child: Center(
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            AppColors.accentPurple,
                                      ),
                                    ),
                                  ),

                                // Project status card
                                if (chat.currentVerifyFile.isNotEmpty) ...[
                                  ProjectStatusCard(
                                    version: 'v1.0',
                                    currentFile: chat.currentVerifyFile,
                                    steps: chat.verificationSteps,
                                    onAttach: () {
                                      // Optionally handle attaching project to chat
                                    },
                                  ),
                                  SizedBox(height: 20 * s),
                                ],

                                SizedBox(height: 20 * s),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

            // Bottom: Chat input bar with error message
            Consumer<ChatProvider>(
              builder: (context, chat, _) {
                return ChatInputBar(
                  aiNamePillText: '',
                  hasApiKey: true,
                  onAddFiles: _onAddFiles,
                  onSend: _onSend,
                  controller: _promptController,
                  attachments: _attachments,
                  errorMessage: chat.errorMessage,
                  disabled: chat.isProcessing,
                  chatScope: chat.chatScope,
                  onScopeChanged: chat.setChatScope,
                  onRemoveAttachment: (index) {
                    setState(() => _attachments.removeAt(index));
                  },
                  onTapAttachment: (index) async {
                    final att = _attachments[index];
                    if (att.type == 'image' && att.bytes != null) {
                      final metadata = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => S14ImageEditorScreen(attachment: att),
                        ),
                      );
                      // In a real app we would pass metadata to ChatProvider's context
                      if (metadata != null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image crop applied.')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        ),
        
        // Floating processing indicator — below app bar to avoid overlap
        Consumer<ChatProvider>(
          builder: (context, chat, _) {
            if (!chat.isProcessing) return const SizedBox.shrink();
            return Positioned(
              top: 8 * s,
              right: 16 * s,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5)),
                  boxShadow: [AppColors.glow(AppColors.accentBlue, blur: 12)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12 * s,
                      height: 12 * s,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                    ),
                    SizedBox(width: 8 * s),
                    Text(
                      'Agent Active',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12 * s,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isDesktop && _rightPanel != null
          ? DesktopSplitView(
              leftChild: mainContent,
              rightChild: Container(
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: _rightPanel!,
              ),
            )
          : mainContent,
    );
  }

  // ── Chat bubble builders ─────────────────────────────────

  Widget _buildUserBubble(dynamic msg, double sw, double s) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: sw * 0.75),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * s,
          vertical: 10 * s,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.attachments.isNotEmpty) ...[
              Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children: msg.attachments.map<Widget>((att) => _buildAttachmentChipReadOnly(att, s)).toList(),
              ),
              SizedBox(height: 8 * s),
            ],
            Text(
              msg.text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14 * s,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4 * s),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You • ${_formatMessageTime(msg.timestamp)}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11 * s,
                  ),
                ),
                SizedBox(width: 4 * s),
                Icon(
                  Icons.done_all,
                  color: AppColors.accentBlue,
                  size: 14 * s,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(dynamic msg, double s) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * s,
          vertical: 10 * s,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22 * s,
                  height: 22 * s,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue,
                        AppColors.accentPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6 * s),
                  ),
                  child: Icon(Icons.auto_awesome,
                      color: Colors.white, size: 12 * s),
                ),
                SizedBox(width: 8 * s),
                Text(
                  'Coder AI',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8 * s),
                Text(
                  _formatMessageTime(msg.timestamp),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11 * s,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8 * s),
            Text(
              msg.text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14 * s,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemBubble(dynamic msg, double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * s,
        vertical: 12 * s,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: AppColors.error, size: 18 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              msg.text,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13 * s,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentStatus(String name, bool isActive, double s) {
    final color = isActive ? const Color(0xFF24A148) : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * s,
          height: 8 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(width: 6 * s),
        Text(
          name,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12 * s,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _showClarifyingDialog(ChatProvider chat, double s) async {
    final questions = chat.clarifyingQuestions;
    if (questions == null || questions.isEmpty) return;

    final controllers =
        List.generate(questions.length, (_) => TextEditingController());

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'Answer Questions',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16 * s),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(questions.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ${questions[i]}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13 * s,
                        ),
                      ),
                      SizedBox(height: 6 * s),
                      TextField(
                        controller: controllers[i],
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14 * s,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Your answer',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.accentBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Submit',
              style: TextStyle(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );

    if (submitted == true && mounted) {
      final answers = controllers.map((c) => c.text.trim()).toList();
      await chat.submitClarifyingAnswers(answers);
    }

    for (final c in controllers) {
      c.dispose();
    }
  }

  Widget _buildClarifyingQuestions(ChatProvider chat, double s) {
    return Container(
      margin: EdgeInsets.only(bottom: 20 * s),
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.accentPurple, size: 20 * s),
              SizedBox(width: 8 * s),
              Text(
                'Clarifying Questions',
                style: TextStyle(
                  color: AppColors.accentPurple,
                  fontSize: 16 * s,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),
          Text(
            'The Planner needs a few more details before generating the plan:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13 * s),
          ),
          SizedBox(height: 12 * s),
          ...chat.clarifyingQuestions!.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8 * s),
              child: Text(
                '${e.key + 1}. ${e.value}',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14 * s),
              ),
            );
          }),
          SizedBox(height: 16 * s),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8 * s)),
              ),
              onPressed: () => _showClarifyingDialog(chat, s),
              child: Text('Answer Questions', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int number, String text, double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28 * s,
          height: 28 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentBlue.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: AppColors.accentBlue,
                fontSize: 13 * s,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12 * s),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4 * s),
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14 * s,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentChipReadOnly(dynamic attachment, double s) {
    final isFolder = attachment.type == 'folder';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8 * s),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFolder ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            color: AppColors.accentBlue,
            size: 14 * s,
          ),
          SizedBox(width: 6 * s),
          Text(
            attachment.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12 * s,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $amPm';
  }

  String _formatMessageTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second $amPm';
  }
}
