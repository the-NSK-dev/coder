import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../providers/github_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/nav_utils.dart';
import '../widgets/coder_app_bar.dart';

/// Screen 10 — Repo Dashboard.
class S10GithubRepoScreen extends StatefulWidget {
  const S10GithubRepoScreen({super.key});

  @override
  State<S10GithubRepoScreen> createState() => _S10GithubRepoScreenState();
}

class _S10GithubRepoScreenState extends State<S10GithubRepoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gh = Provider.of<GitHubProvider>(context, listen: false);
      if (gh.isConnected && gh.repos.isEmpty) {
        gh.fetchRepos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CoderAppBar(
              onBack: () => popOrGo(context, fallback: '/github/connected'),
              onAvatarTap: () => context.push('/profile'),
              actions: [
                AppBarAction(
                  icon: Icons.folder_outlined,
                  onTap: () => context.push('/files'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: 16 * s, vertical: 16 * s),
                child: Column(
                  children: [
                    // Header row
                    Consumer<ChatProvider>(
                      builder: (context, chat, _) {
                        final projectName = chat.currentCodeResult?.projectName ?? 'My Project';
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => popOrGo(context, fallback: '/github/connected'),
                              child: Container(
                                width: 40 * s,
                                height: 40 * s,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(12 * s),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Icon(Icons.arrow_back,
                                    color: AppColors.textPrimary,
                                    size: 20 * s),
                              ),
                            ),
                            SizedBox(width: 16 * s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    projectName,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 24 * s,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 8 * s),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10 * s, vertical: 4 * s),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(12 * s),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_outline,
                                            color: AppColors.textSecondary,
                                            size: 12 * s),
                                        SizedBox(width: 6 * s),
                                        Text(
                                          'Local Project',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12 * s,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _GlowingGithubAvatar(scale: s),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 24 * s),

                    // Live Repositories List
                    Consumer<GitHubProvider>(
                      builder: (context, github, _) {
                        if (!github.isConnected) return const SizedBox.shrink();
                        if (github.isLoading) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20 * s),
                              child: const CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (github.repos.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20 * s),
                              child: Text(
                                'No repositories found or still loading.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13 * s),
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR REPOSITORIES',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12 * s,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 12 * s),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: github.repos.length > 5 ? 5 : github.repos.length,
                                separatorBuilder: (context, index) => _rowDivider(s),
                                itemBuilder: (context, i) {
                                  final r = github.repos[i];
                                  return _actionRow(
                                    Icons.source_outlined,
                                    r['name'] ?? 'repo',
                                    r['private'] == 'true' ? 'Private' : 'Public',
                                    s,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 24 * s),

                    // Push Card
                    Container(
                      padding: EdgeInsets.all(20 * s),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1C),
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(
                            color: AppColors.accentBlue
                                .withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentBlue
                                .withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48 * s,
                            height: 48 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.accentBlue,
                                  width: 2),
                            ),
                            child: Icon(
                                Icons.cloud_upload_outlined,
                                color: AppColors.accentBlue,
                                size: 24 * s),
                          ),
                          SizedBox(width: 16 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Push Current Project',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15 * s,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                Text(
                                  'Push latest changes to GitHub',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
                                    fontSize: 12 * s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer<GitHubProvider>(
                            builder: (context, github, _) => GestureDetector(
                              onTap: github.isPushing ? null : () async {
                                final chat = Provider.of<ChatProvider>(
                                    context,
                                    listen: false);
                                if (chat.currentCodeResult == null) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No project to push. Generate a project first.')),
                                    );
                                  }
                                  return;
                                }
                                final success =
                                    await github.pushProject(chat.currentCodeResult!);
                                if (success) {
                                  if (context.mounted) {
                                    context.push(
                                        '/github/push_success');
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              github.errorMessage ?? 'Failed to push. Check your token.')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20 * s, vertical: 12 * s),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue,
                                  borderRadius:
                                      BorderRadius.circular(12 * s),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentBlue
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: github.isPushing
                                    ? SizedBox(
                                        width: 16 * s,
                                        height: 16 * s,
                                        child: const CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Push Now',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14 * s,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * s),

                    // Connection Status Card
                    Container(
                      padding: EdgeInsets.all(16 * s),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10 * s),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.link,
                                color: AppColors.accentBlue,
                                size: 20 * s),
                          ),
                          SizedBox(width: 16 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8 * s,
                                      height: 8 * s,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF24A148),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6 * s),
                                    Consumer<GitHubProvider>(
                                      builder: (context, github, _) => Text(
                                        github.isConnected ? 'Connected' : 'Not Connected',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14 * s,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4 * s),
                                Consumer<GitHubProvider>(
                                  builder: (context, github, _) => Text(
                                    github.username.isNotEmpty
                                        ? github.username
                                        : 'octocat',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12 * s,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.push('/github/connected'),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16 * s, vertical: 8 * s),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(20 * s),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      color: AppColors.accentBlue,
                                      fontSize: 13 * s,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4 * s),
                                  Icon(Icons.chevron_right,
                                      color: AppColors.accentBlue,
                                      size: 16 * s),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _actionRow(
      IconData icon, String title, String subtitle, double s) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 16 * s, vertical: 16 * s),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Icon(icon,
                color: AppColors.accentBlue, size: 20 * s),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4 * s),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12 * s,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 20 * s),
        ],
      ),
    );
  }

  Widget _rowDivider(double s) {
    return Container(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.5),
      margin: EdgeInsets.only(left: 64 * s),
    );
  }
}

// ─── Glowing GitHub Avatar ────────────────────────────────────────────────────
class _GlowingGithubAvatar extends StatefulWidget {
  final double scale;
  const _GlowingGithubAvatar({required this.scale});

  @override
  State<_GlowingGithubAvatar> createState() => _GlowingGithubAvatarState();
}

class _GlowingGithubAvatarState extends State<_GlowingGithubAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glow = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        return Container(
          width: 80 * s,
          height: 80 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: _glow.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue
                    .withValues(alpha: 0.4 * _glow.value),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
              child: ClipOval(
                child: Consumer<GitHubProvider>(
                  builder: (context, github, _) {
                    if (github.avatarUrl != null) {
                      return Image.network(
                        github.avatarUrl!,
                        width: 80 * s,
                        height: 80 * s,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: const Color(0xFF0D1117),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/github.svg',
                          width: 40 * s,
                          height: 40 * s,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        );
      },
    );
  }
}
