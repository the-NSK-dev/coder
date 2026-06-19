import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../utils/nav_utils.dart';
import 'package:provider/provider.dart';
import '../providers/github_provider.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// Data class for a single action button in the CoderAppBar.
class AppBarAction {
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;
  final bool highlighted;

  const AppBarAction({
    this.icon,
    this.svgAsset,
    required this.onTap,
    this.highlighted = false,
  }) : assert(icon != null || svgAsset != null);
}

/// Shared app bar used across all screens.
/// Always shows: GitHub icon + branding, action buttons, and an Exit button.
class CoderAppBar extends StatelessWidget {
  final List<AppBarAction> actions;
  final bool showLogo;
  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onAvatarTap;
  final bool autoWireActions;
  final String backFallbackRoute;

  const CoderAppBar({
    super.key,
    this.actions = const [],
    this.showLogo = true,
    this.title,
    this.onBack,
    this.onAvatarTap,
    this.autoWireActions = false,
    this.backFallbackRoute = '/main',
  });

  // ─── Auto-wired GitHub tap ───────────────────────────────────────────────
  static void handleGithubTap(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath.startsWith('/github')) {
      context.go('/main');
      return;
    }
    if (AppConfig.githubToken.isEmpty || AppConfig.githubToken == 'YOUR_GITHUB_TOKEN') {
      context.push('/github/connect');
    } else {
      context.push('/github/connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF090B13) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.86)
        : Colors.black.withValues(alpha: 0.75);
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D20);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
      child: Row(
        children: [
          // Left: back button or GitHub icon
          if (onBack != null)
            _buildBackButton(context, s, bgColor, borderColor, iconColor)
          else
            _buildGithubBranding(context, s, bgColor, borderColor, iconColor, textColor),

          const Spacer(),

          // Right: action buttons row
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) SizedBox(width: 6 * s),
            _buildActionButton(actions[i], s, bgColor, borderColor, iconColor),
          ],

        ],
      ),
    );
  }

  // GitHub logo + "Coder" branding always visible, tappable to navigate
  Widget _buildGithubBranding(BuildContext context, double s, Color bgColor,
      Color borderColor, Color iconColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar/profile button
        if (onAvatarTap != null)
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 36 * s,
              height: 36 * s,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10 * s),
                border: Border.all(color: borderColor, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Consumer<GitHubProvider>(
                builder: (context, github, _) {
                  if (github.isConnected && github.avatarUrl != null) {
                    return Image.network(
                      github.avatarUrl!,
                      fit: BoxFit.cover,
                    );
                  }
                  return Icon(Icons.person_outline, color: iconColor, size: 18 * s);
                },
              ),
            ),
          ),
        if (onAvatarTap != null) SizedBox(width: 10 * s),

        // GitHub icon (always visible)
        GestureDetector(
          onTap: () => handleGithubTap(context),
          child: Container(
            width: 36 * s,
            height: 36 * s,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10 * s),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/github.svg',
                width: 18 * s,
                height: 18 * s,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
        SizedBox(width: 10 * s),

        // Coder logo + name
        if (showLogo) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8 * s),
            child: Image.asset(
              'assets/logo-center.png',
              width: 26 * s,
              height: 26 * s,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 26 * s,
                height: 26 * s,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: Icon(Icons.code, color: Colors.white, size: 14 * s),
              ),
            ),
          ),
          SizedBox(width: 6 * s),
          Text(
            'Coder',
            style: TextStyle(
              color: textColor,
              fontSize: 17 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else if (title != null)
          Text(
            title!,
            style: TextStyle(
              color: textColor,
              fontSize: 17 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, double s, Color bgColor,
      Color borderColor, Color iconColor) {
    return GestureDetector(
      onTap: () {
        if (onBack != null) {
          onBack!();
        } else {
          popOrGo(context, fallback: backFallbackRoute);
        }
      },
      child: Container(
        width: 40 * s,
        height: 40 * s,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12 * s),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Icon(Icons.arrow_back, color: iconColor, size: 20 * s),
      ),
    );
  }


  Widget _buildActionButton(AppBarAction action, double s, Color bgColor,
      Color borderColor, Color iconColor) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 36 * s,
        height: 36 * s,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10 * s),
          border: Border.all(
            color: action.highlighted
                ? AppColors.accentBlue.withValues(alpha: 0.82)
                : borderColor,
            width: action.highlighted ? 1.5 : 1,
          ),
          boxShadow: action.highlighted
              ? [AppColors.glow(AppColors.accentBlue, blur: 16)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (action.svgAsset != null)
              SvgPicture.asset(
                action.svgAsset!,
                width: 18 * s,
                height: 18 * s,
                colorFilter: ColorFilter.mode(
                    action.highlighted ? AppColors.accentBlue : iconColor,
                    BlendMode.srcIn),
              )
            else
              Icon(
                action.icon,
                color: action.highlighted ? AppColors.accentBlue : iconColor,
                size: 18 * s,
              ),
            if (action.highlighted)
              Container(
                margin: EdgeInsets.only(top: 2 * s),
                width: 12 * s,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
