import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/github_provider.dart';
import '../utils/nav_utils.dart';
import '../widgets/coder_app_bar.dart';
import '../theme/app_colors.dart';

/// Screen 9 — Connect GitHub screen.
/// Wired to GitHubProvider for token-based authentication.
class S9ConnectGithubScreen extends StatefulWidget {
  const S9ConnectGithubScreen({super.key});

  @override
  State<S9ConnectGithubScreen> createState() => _S9ConnectGithubScreenState();
}

class _S9ConnectGithubScreenState extends State<S9ConnectGithubScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _showTokenInput = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connectWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a GitHub token')),
      );
      return;
    }

    final github = Provider.of<GitHubProvider>(context, listen: false);
    final success = await github.connectGithub(token);

    if (success && mounted) {
      context.go('/github/connected');
    } else if (github.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(github.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
            // App Bar with GitHub highlighted + persistent Exit
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
              child: Consumer<GitHubProvider>(
                builder: (context, github, _) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 52 * s),

                        // GitHub glowing icon
                        Container(
                          width: 88 * s,
                          height: 88 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/github.svg',
                              width: 52 * s,
                              height: 52 * s,
                              colorFilter: const ColorFilter.mode(
                                  Colors.black, BlendMode.srcIn),
                            ),
                          ),
                        ),

                        SizedBox(height: 28 * s),

                        Text(
                          'Connect GitHub',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32 * s,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),

                        SizedBox(height: 12 * s),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32 * s),
                          child: Text(
                            'Authorize Coder to sync projects directly to your repositories.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14 * s,
                              height: 1.5,
                            ),
                          ),
                        ),

                        SizedBox(height: 36 * s),

                        // Token input field (shown when user taps Connect)
                        if (_showTokenInput) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20 * s),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14 * s),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        16 * s, 14 * s, 16 * s, 4 * s),
                                    child: Row(
                                      children: [
                                        Icon(Icons.key_rounded,
                                            color: AppColors.accentBlue,
                                            size: 16 * s),
                                        SizedBox(width: 8 * s),
                                        Text(
                                          'Personal Access Token',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12 * s,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        16 * s, 4 * s, 16 * s, 14 * s),
                                    child: TextField(
                                      controller: _tokenController,
                                      obscureText: true,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14 * s,
                                        fontFamily: 'monospace',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'ghp_xxxxxxxxxxxx',
                                        hintStyle: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14 * s,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * s),

                          // Connect button
                          GestureDetector(
                            onTap: github.isLoading
                                ? null
                                : _connectWithToken,
                            child: Container(
                              width: double.infinity,
                              height: 52 * s,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 20 * s),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue,
                                borderRadius: BorderRadius.circular(14 * s),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentBlue
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: github.isLoading
                                    ? SizedBox(
                                        width: 24 * s,
                                        height: 24 * s,
                                        child:
                                            const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Connect',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16 * s,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12 * s),

                          // Generate token link
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(
                                  'https://github.com/settings/tokens/new');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                            child: Text(
                              'Generate a new token on GitHub →',
                              style: TextStyle(
                                color: AppColors.accentBlue,
                                fontSize: 13 * s,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Continue with GitHub Button
                          GestureDetector(
                            onTap: () {
                              // Check if already connected
                              if (github.isConnected) {
                                context.go('/github/connected');
                                return;
                              }
                              // Show token input
                              setState(() => _showTokenInput = true);
                            },
                            child: Container(
                              width: double.infinity,
                              height: 52 * s,
                              margin: EdgeInsets.symmetric(
                                  horizontal: 20 * s),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14 * s),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/github.svg',
                                    width: 24 * s,
                                    height: 24 * s,
                                    colorFilter: const ColorFilter.mode(
                                        Colors.black, BlendMode.srcIn),
                                  ),
                                  SizedBox(width: 12 * s),
                                  Text(
                                    'Continue with GitHub',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16 * s,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 24 * s),

                        // Capabilities panel
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20 * s),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 22 * s, vertical: 18 * s),
                            decoration: BoxDecoration(
                              color: const Color(0xFF030712)
                                  .withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(16 * s),
                              border: Border.all(
                                color: const Color(0xFF31415F)
                                    .withValues(alpha: 0.78),
                              ),
                            ),
                            child: Column(
                              children: [
                                _capabilityRow('Push generated projects', s),
                                _dividerRow(s),
                                _capabilityRow('Create repositories', s),
                                _dividerRow(s),
                                _capabilityRow('Commit updates', s),
                                _dividerRow(s),
                                _capabilityRow('Manage branches', s),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 40 * s),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilityRow(String label, double s) {
    return Row(
      children: [
        Container(
          width: 28 * s,
          height: 28 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0A84FF), width: 2),
          ),
          child: Icon(Icons.check,
              color: const Color(0xFF0A84FF), size: 17 * s),
        ),
        SizedBox(width: 18 * s),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15 * s,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dividerRow(double s) {
    return Padding(
      padding: EdgeInsets.only(left: 44 * s),
      child: Divider(
        height: 26 * s,
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    );
  }
}
