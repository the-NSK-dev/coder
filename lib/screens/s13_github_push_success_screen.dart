import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/github_provider.dart';
import '../widgets/coder_app_bar.dart';
import '../theme/app_colors.dart';

/// Screen 13 — GitHub Push Success Screen (matches Image 4).
class S13GithubPushSuccessScreen extends StatefulWidget {
  const S13GithubPushSuccessScreen({super.key});

  @override
  State<S13GithubPushSuccessScreen> createState() => _S13GithubPushSuccessScreenState();
}

class _S13GithubPushSuccessScreenState extends State<S13GithubPushSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              onAvatarTap: () => context.push('/profile'),
              actions: [
                AppBarAction(
                  icon: Icons.folder_outlined,
                  onTap: () => context.push('/files'),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36 * s,
                      height: 36 * s,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10 * s),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20 * s),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Push Successful',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Your changes have been pushed to GitHub',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12 * s,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 24 * s),
                child: Column(
                  children: [
                    SizedBox(height: 10 * s),
                    
                    // Checkmark
                    ScaleTransition(
                      scale: _scale,
                      child: Container(
                        width: 100 * s,
                        height: 100 * s,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF24A148), width: 6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF24A148).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.check, color: const Color(0xFF24A148), size: 60 * s),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24 * s),
                    Text(
                      'Push Successful!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24 * s,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Text(
                      'All changes have been pushed to the remote repository.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14 * s,
                      ),
                    ),
                    SizedBox(height: 32 * s),

                    // Repo Link Box
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10 * s),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12 * s),
                            ),
                            child: Icon(Icons.code, color: const Color(0xFF3B6FE8), size: 24 * s),
                          ),
                          SizedBox(width: 16 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'coder-app',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16 * s,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8 * s),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(12 * s),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 10 * s),
                                          SizedBox(width: 4 * s),
                                          Text(
                                            'Private',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 10 * s,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4 * s),
                                Text(
                                  Provider.of<GitHubProvider>(context).lastPushUrl ?? 'github.com/octocat/coder-app.git',
                                  style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontSize: 12 * s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_new, color: AppColors.accentBlue, size: 20 * s),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * s),

                    // Summary
                    _sectionTitle('Summary', s),
                    SizedBox(height: 12 * s),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(Icons.description_outlined, '12 commits pushed', 'From your local repository', '+12', const Color(0xFF24A148), s),
                          _divider(s),
                          _summaryRow(Icons.file_copy_outlined, '12 files changed', 'Successfully uploaded', '+256   -34', const Color(0xFF24A148), s, negativeColor: AppColors.error),
                          _divider(s),
                          _summaryRow(Icons.account_tree_outlined, 'Branch updated', 'main is now up to date', 'main', AppColors.accentBlue, s, isBadge: true),
                        ],
                      ),
                    ),
                    SizedBox(height: 24 * s),

                    // Recent Commits
                    _sectionTitle('Recent commits', s),
                    SizedBox(height: 12 * s),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _commitRow('Update authentication flow and add UI components', '2m ago', 'a1b2c3d', s),
                          _divider(s),
                          _commitRow('Refactor auth service and improve types', '1h ago', 'd4e5f6g', s),
                          _divider(s),
                          _commitRow('Add login UI and error handling', '3h ago', 'h7i8j9k', s),
                          _divider(s),
                          Padding(
                            padding: EdgeInsets.all(16 * s),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'View all commits',
                                  style: TextStyle(color: AppColors.accentBlue, fontSize: 14 * s, fontWeight: FontWeight.w500),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.accentBlue, size: 18 * s),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * s),

                    // Actions
                    GestureDetector(
                      onTap: () async {
                        final github = Provider.of<GitHubProvider>(
                            context, listen: false);
                        final urlStr = github.lastPushUrl;
                        if (urlStr != null && urlStr.isNotEmpty) {
                          final url = Uri.parse(urlStr);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52 * s,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue,
                          borderRadius: BorderRadius.circular(12 * s),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View on GitHub',
                              style: TextStyle(color: Colors.white, fontSize: 16 * s, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8 * s),
                            Icon(Icons.open_in_new, color: Colors.white, size: 18 * s),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    GestureDetector(
                      onTap: () => context.go('/files'),
                      child: Container(
                        width: double.infinity,
                        height: 52 * s,
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(
                          'Back to Files',
                          style: TextStyle(
                            color: AppColors.accentBlue,
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _sectionTitle(String title, double s) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16 * s,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String title, String subtitle, String value, Color color, double s, {Color? negativeColor, bool isBadge = false}) {
    return Padding(
      padding: EdgeInsets.all(16 * s),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentPurple, size: 24 * s),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14 * s, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2 * s),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12 * s),
                ),
              ],
            ),
          ),
          if (isBadge)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(color: AppColors.accentBlue, fontSize: 12 * s, fontWeight: FontWeight.w500),
              ),
            )
          else if (negativeColor != null)
            Row(
              children: [
                Text(
                  value.split('   ')[0],
                  style: TextStyle(color: color, fontSize: 14 * s, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 8 * s),
                Text(
                  value.split('   ')[1],
                  style: TextStyle(color: negativeColor, fontSize: 14 * s, fontWeight: FontWeight.w500),
                ),
              ],
            )
          else
            Text(
              value,
              style: TextStyle(color: color, fontSize: 14 * s, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _commitRow(String message, String time, String hash, double s) {
    return Padding(
      padding: EdgeInsets.all(16 * s),
      child: Row(
        children: [
          Container(
            width: 32 * s,
            height: 32 * s,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://github.com/octocat.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13 * s, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4 * s),
                Text(
                  'octocat committed • $time',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11 * s),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6 * s),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(
                  hash,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11 * s, fontFamily: 'monospace'),
                ),
                SizedBox(width: 4 * s),
                Icon(Icons.copy, color: AppColors.textSecondary, size: 12 * s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(double s) {
    return Container(
      height: 1,
      color: AppColors.border.withValues(alpha: 0.5),
      margin: EdgeInsets.only(left: 56 * s),
    );
  }
}
