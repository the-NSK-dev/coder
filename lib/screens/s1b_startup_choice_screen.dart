import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// Screen 1b — Startup / Welcome screen
// ─────────────────────────────────────────────────────────────

class S1bStartupChoiceScreen extends StatefulWidget {
  const S1bStartupChoiceScreen({super.key});

  @override
  State<S1bStartupChoiceScreen> createState() =>
      _S1bStartupChoiceScreenState();
}

class _S1bStartupChoiceScreenState extends State<S1bStartupChoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim =
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) => _slideCtrl.forward());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────

  Future<void> _openFolder() async {
    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final success = await workspace.openLocalFolder();
    if (success && mounted) {
      context.go('/main');
    } else if (workspace.errorMessage != null && mounted) {
      _showError(workspace.errorMessage!);
    }
  }

  Future<void> _openSample() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingOverlay(),
    );

    final workspace = Provider.of<WorkspaceProvider>(context, listen: false);
    final success = await workspace.loadSampleProject();

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        context.go('/main');
      } else if (workspace.errorMessage != null) {
        _showError(workspace.errorMessage!);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ..._buildStars(sw, sh),
          _buildArcGlow(sw, sh),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(_slideAnim),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: sh * 0.06),

                      // Logo
                      _buildLogo(s),
                      SizedBox(height: 16 * s),
                      _buildTitle(s),
                      SizedBox(height: 6 * s),
                      _buildTagline(s),

                      SizedBox(height: 28 * s),

                      // What is Coder?
                      _buildExplainerCard(s),

                      SizedBox(height: 20 * s),

                      // Powered by — sponsor images
                      _buildPoweredByRow(s),

                      SizedBox(height: 36 * s),

                      // Get started label
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'GET STARTED',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11 * s,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * s),

                      // Open Folder card
                      _LaunchCard(
                        key: const ValueKey('open_folder'),
                        icon: Icons.folder_open_rounded,
                        iconColor: AppColors.accentBlue,
                        title: 'Open Folder',
                        subtitle:
                            'Point Coder at any project on your device. The AI team will read your files and pick up where you left off.',
                        badge: null,
                        onTap: _openFolder,
                        s: s,
                        pulseCtrl: _pulseCtrl,
                        accentColor: AppColors.accentBlue,
                      ),

                      SizedBox(height: 14 * s),

                      // Sample project card
                      _LaunchCard(
                        key: const ValueKey('open_sample'),
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.accentPurple,
                        title: 'Try the Sample Project',
                        subtitle:
                            'Load a pre-built Coder documentation website — '
                            'explains exactly how Coder, Band.ai, and the 4 AI agents work together. '
                            'Great starting point to explore the full feature set.',
                        badge: 'Included',
                        onTap: _openSample,
                        s: s,
                        pulseCtrl: _pulseCtrl,
                        accentColor: AppColors.accentPurple,
                      ),

                      SizedBox(height: 44 * s),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────

  Widget _buildLogo(double s) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final g = 0.2 + _pulseCtrl.value * 0.25;
        final size = (72 * s).clamp(60.0, 96.0);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: [
              BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: g),
                  blurRadius: 48,
                  spreadRadius: 10),
              BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: g * 0.5),
                  blurRadius: 80,
                  spreadRadius: 4),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22 * s),
            child: Image.asset(
              'assets/logo-center.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22 * s),
                ),
                child: const Icon(Icons.code_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(double s) => Text(
        'Coder',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 36 * s,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          height: 1.0,
        ),
      );

  Widget _buildTagline(double s) => Text(
        'Your AI Engineering Team',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14 * s,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
        ),
      );

  Widget _buildExplainerCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32 * s,
                height: 32 * s,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8 * s),
                ),
                child: Icon(Icons.info_outline_rounded,
                    color: AppColors.accentBlue, size: 18 * s),
              ),
              SizedBox(width: 12 * s),
              Text(
                'What is Coder?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          _point(Icons.groups_2_rounded, AppColors.accentBlue,
              'Four AI agents work as a team',
              'Controller plans, Engineer codes, Reviewer checks quality, Verifier tests — all automatically.',
              s),
          SizedBox(height: 12 * s),
          _point(Icons.chat_bubble_outline_rounded, AppColors.accentPurple,
              'Agents coordinate via Band.ai',
              'Agents share a Band chat room and @mention each other to hand off tasks — like a real Slack team.',
              s),
          SizedBox(height: 12 * s),
          _point(Icons.folder_open_rounded, const Color(0xFF10B981),
              'Files land directly on your device',
              'Generated code is written straight into your open project folder. No cloud storage needed.',
              s),
        ],
      ),
    );
  }

  Widget _point(IconData icon, Color color, String title, String body, double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18 * s),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 2 * s),
              Text(body,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12 * s,
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  /// "Powered by" row using the real sponsor images (same as splash screen).
  Widget _buildPoweredByRow(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _dotLine(true, s),
            SizedBox(width: 10 * s),
            Text(
              'Powered by',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11 * s,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(width: 10 * s),
            _dotLine(false, s),
          ],
        ),
        SizedBox(height: 10 * s),
        Container(
          height: 52 * s,
          decoration: BoxDecoration(
            color: const Color(0xFF050508),
            borderRadius: BorderRadius.circular(12 * s),
            border: Border.all(
              color: const Color(0xFF6D28D9).withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D28D9).withValues(alpha: 0.2),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(child: _sponsorLogo('assets/sponsor-3.png', 36 * s)),
              ),
              Container(
                  width: 1,
                  height: 28 * s,
                  color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                child: Center(child: _sponsorLogo('assets/sponsor-2.png', 32 * s)),
              ),
              Container(
                  width: 1,
                  height: 28 * s,
                  color: Colors.white.withValues(alpha: 0.1)),
              Expanded(
                child: Center(child: _sponsorLogo('assets/sponsor-1.png', 36 * s)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sponsorLogo(String path, double height) {
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        final name = path
            .split('/')
            .last
            .replaceAll('.png', '')
            .replaceAll('-', ' ');
        return Text(
          name.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        );
      },
    );
  }

  Widget _dotLine(bool left, double s) {
    final color = left ? AppColors.accentBlue : const Color(0xFF7C3AED);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!left)
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.8))),
        if (!left) const SizedBox(width: 4),
        Container(
          width: 36 * s,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: left
                  ? [Colors.transparent, color.withValues(alpha: 0.6)]
                  : [color.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
        ),
        if (left) const SizedBox(width: 4),
        if (left)
          Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.8))),
      ],
    );
  }

  // ── Background ────────────────────────────────────────────

  List<Widget> _buildStars(double w, double h) {
    final r = Random(7);
    return List.generate(45, (i) => Positioned(
      left: r.nextDouble() * w,
      top: r.nextDouble() * h,
      child: Container(
        width: 1.0 + r.nextDouble() * 1.6,
        height: 1.0 + r.nextDouble() * 1.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08 + r.nextDouble() * 0.35),
        ),
      ),
    ));
  }

  Widget _buildArcGlow(double w, double h) {
    return Positioned(
      top: -h * 0.25,
      left: -w * 0.3,
      child: Container(
        width: w * 1.6,
        height: w * 1.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accentPurple.withValues(alpha: 0.08),
              AppColors.accentBlue.withValues(alpha: 0.04),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LAUNCH CARD
// ─────────────────────────────────────────────────────────────

class _LaunchCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  final double s;
  final AnimationController pulseCtrl;
  final Color accentColor;

  const _LaunchCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    required this.s,
    required this.pulseCtrl,
    required this.accentColor,
  });

  @override
  State<_LaunchCard> createState() => _LaunchCardState();
}

class _LaunchCardState extends State<_LaunchCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _hoverCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _hoverCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _hoverCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _hoverCtrl.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedBuilder(
          animation: widget.pulseCtrl,
          builder: (_, child) {
            final glow =
                _pressed ? 0.3 : 0.08 + widget.pulseCtrl.value * 0.1;
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(
                  color: widget.accentColor
                      .withValues(alpha: _pressed ? 0.5 : 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: glow),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(18 * s),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48 * s,
                  height: 48 * s,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14 * s),
                  ),
                  child:
                      Icon(widget.icon, color: widget.iconColor, size: 26 * s),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.badge != null) ...[
                            SizedBox(width: 8 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8 * s, vertical: 2 * s),
                              decoration: BoxDecoration(
                                color:
                                    widget.iconColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.badge!,
                                style: TextStyle(
                                  color: widget.iconColor,
                                  fontSize: 10 * s,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 5 * s),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5 * s,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * s),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted, size: 14 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING OVERLAY
// ─────────────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentPurple),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Building sample project…',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Creating Coder documentation website',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
