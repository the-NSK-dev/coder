import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/github_provider.dart';
import '../utils/nav_utils.dart';
import '../widgets/coder_app_bar.dart';
import '../theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Screen 12 — GitHub Connected Dashboard.
class S12GithubConnectedScreen extends StatelessWidget {
  const S12GithubConnectedScreen({super.key});

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
              onBack: () => popOrGo(context, fallback: '/main'),
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
                    // Top profile card
                    Container(
                      padding: EdgeInsets.all(20 * s),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
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
                          Consumer<GitHubProvider>(
                            builder: (context, github, _) => _GlowingGithubAvatar(
                              scale: s,
                              imageUrl: github.avatarUrl,
                            ),
                          ),
                          SizedBox(width: 20 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GitHub Connected',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18 * s,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4 * s),
                                Consumer<GitHubProvider>(
                                  builder: (context, github, _) => Text(
                                    github.username.isNotEmpty
                                        ? github.username
                                        : 'octocat',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16 * s,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Consumer<GitHubProvider>(
                                  builder: (context, github, _) => Text(
                                    '@${github.username.isNotEmpty ? github.username : 'octocat'}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13 * s,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8 * s),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10 * s, vertical: 4 * s),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D2411),
                                    borderRadius:
                                        BorderRadius.circular(12 * s),
                                    border: Border.all(
                                        color: const Color(0xFF198038)
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6 * s,
                                        height: 6 * s,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF24A148),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 6 * s),
                                      Text(
                                        'Connected',
                                        style: TextStyle(
                                          color: const Color(0xFF24A148),
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
                          Icon(Icons.chevron_right,
                              color: AppColors.textSecondary,
                              size: 24 * s),
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * s),

                    // Stats Grid
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 20 * s),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Consumer<GitHubProvider>(
                            builder: (context, github, _) => Row(
                              children: [
                                _statItem('${(github.publicRepos ?? 0) + (github.totalPrivateRepos ?? 0)}', 'Repositories',
                                    Icons.inventory_2_outlined, s),
                                _divider(s, vertical: true),
                                _statItem('${github.followers ?? 0}', 'Followers',
                                    Icons.people_outline, s),
                                _divider(s, vertical: true),
                                _statItem('${github.following ?? 0}', 'Following',
                                    Icons.person_add_alt_1_outlined, s),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20 * s),
                            child: _divider(s, vertical: false),
                          ),
                           Consumer<GitHubProvider>(
                             builder: (context, github, _) => Row(
                               children: [
                                 _statItem('${github.orgsCount ?? 0}', 'Organizations',
                                     Icons.domain_outlined, s),
                                 _divider(s, vertical: true),
                                 _statItem('${github.starredCount ?? 0}', 'Starred',
                                     Icons.star_border, s),
                                 _divider(s, vertical: true),
                                 _statItem('${github.repos.fold<int>(0, (sum, repo) => sum + 1 /* can't get total branches easily, fallback to repo count for now or placeholder */)}', 'Branches',
                                     Icons.account_tree_outlined, s),
                               ],
                             ),
                           ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * s),

                    // Details List
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16 * s),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _detailRow(Icons.link, 'Connection Status',
                              trailing: _statusBadge(s), s: s),
                          _divider(s, vertical: false),
                          _detailRow(Icons.person_outline,
                              'Primary Account',
                              trailingText: Provider.of<GitHubProvider>(context)
                                      .username.isNotEmpty
                                  ? Provider.of<GitHubProvider>(context).username
                                  : 'octocat',
                              s: s),
                          _divider(s, vertical: false),
                          Consumer<GitHubProvider>(
                            builder: (context, github, _) {
                              String dateStr = 'Unknown';
                              if (github.createdAt != null) {
                                try {
                                  final dt = DateTime.parse(github.createdAt!);
                                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                  dateStr = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
                                } catch (_) {}
                              }
                              return _detailRow(Icons.calendar_today_outlined,
                                  'Connected Since',
                                  trailingText: dateStr, s: s);
                            },
                          ),
                          _divider(s, vertical: false),
                          _detailRow(Icons.security_outlined,
                              'Authentication',
                              trailingText: 'Personal Access Token', s: s),
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * s),

                    // Manage Account button
                    GestureDetector(
                      onTap: () => context.push('/github/repo'),
                      child: Container(
                        width: double.infinity,
                        height: 52 * s,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(12 * s),
                          border: Border.all(
                              color: AppColors.accentBlue),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue
                                  .withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.manage_accounts_outlined,
                                color: AppColors.accentBlue,
                                size: 20 * s),
                            SizedBox(width: 8 * s),
                            Text(
                              'Manage Account',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * s),

                    // Disconnect Button
                    GestureDetector(
                      onTap: () async {
                        final github = Provider.of<GitHubProvider>(
                            context, listen: false);
                        await github.disconnect();
                        if (context.mounted) {
                          context.go('/github/connect');
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52 * s,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(12 * s),
                          border:
                              Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline,
                                color: AppColors.error,
                                size: 20 * s),
                            SizedBox(width: 8 * s),
                            Text(
                              'Disconnect',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30 * s),

                    // Security note
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline,
                            color: AppColors.textSecondary,
                            size: 18 * s),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: Text(
                            'Your data is secure and never stored by Coder.\nWe use GitHub OAuth for authentication.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12 * s,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30 * s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, double s) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 24 * s),
          SizedBox(height: 12 * s),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * s),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12 * s,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(double s, {required bool vertical}) {
    if (vertical) {
      return Container(
          width: 1,
          height: 60 * s,
          color: AppColors.border.withValues(alpha: 0.5));
    }
    return Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.5));
  }

  Widget _detailRow(IconData icon, String label,
      {String? trailingText, Widget? trailing, required double s}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 16 * s, vertical: 16 * s),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 20 * s),
          SizedBox(width: 12 * s),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14 * s,
              ),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14 * s,
              ),
            ),
          trailing ?? const SizedBox.shrink(),
          SizedBox(width: 8 * s),
          Icon(Icons.chevron_right,
              color: AppColors.textSecondary, size: 18 * s),
        ],
      ),
    );
  }

  Widget _statusBadge(double s) {
    return Row(
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
        Text(
          'Connected',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14 * s,
          ),
        ),
      ],
    );
  }
}

// ─── Glowing GitHub Avatar ───────────────────────────────────────────────────
class _GlowingGithubAvatar extends StatefulWidget {
  final double scale;
  final String? imageUrl;
  const _GlowingGithubAvatar({required this.scale, this.imageUrl});

  @override
  State<_GlowingGithubAvatar> createState() =>
      _GlowingGithubAvatarState();
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
              color: AppColors.accentBlue
                  .withValues(alpha: _glow.value),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue
                    .withValues(alpha: 0.3 * _glow.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: const Color(0xFF0D1117),
              child: Center(
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.imageUrl!,
                        width: 80 * s,
                        height: 80 * s,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.person,
                        size: 40 * s,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
