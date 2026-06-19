import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_colors.dart';

/// Screen 1 — Splash screen with glowing Coder logo, tagline, and sponsors.
class S1SplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;

  const S1SplashScreen({super.key, this.onFinished});

  @override
  State<S1SplashScreen> createState() => _S1SplashScreenState();
}

class _S1SplashScreenState extends State<S1SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) widget.onFinished?.call();
      });
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final availableHeight = sh - safeTop - safeBottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ..._buildStars(sw, sh),

          // Planet arc
          Positioned(
            bottom: -sh * 0.04,
            left: 0,
            right: 0,
            height: sh * 0.2,
            child: CustomPaint(
              painter: _PlanetArcPainter(),
              size: Size(sw, sh * 0.2),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: availableHeight,
              child: Column(
                children: [
                  SizedBox(height: availableHeight * 0.10),

                  // Logo with glow
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      final g = 0.25 + (_glowController.value * 0.2);
                      final logoSize = (150 * s).clamp(100.0, 200.0);
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40 * s),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentBlue.withValues(alpha: g),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: AppColors.accentPurple
                                  .withValues(alpha: g * 0.5),
                              blurRadius: 100,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40 * s),
                          child: Image.asset(
                            'assets/logo-center.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: logoSize,
                              height: logoSize,
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
                                    BorderRadius.circular(40 * s),
                              ),
                              child: const Icon(Icons.code,
                                  color: Colors.white, size: 60),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 14 * s),

                  Text(
                    'Coder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 46 * s,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.1,
                    ),
                  ),

                  SizedBox(height: 4 * s),

                  Text(
                    'Your Engineering Team',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11 * s,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const Spacer(),

                  // Powered by
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dotLine(true, s),
                      SizedBox(width: 12 * s),
                      Text(
                        'Powered by',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11 * s,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      _dotLine(false, s),
                    ],
                  ),

                  SizedBox(height: 8 * s),

                  // Sponsors
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32 * s),
                    child: Container(
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
                            color:
                                const Color(0xFF6D28D9).withValues(alpha: 0.2),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: _sponsorLogo(
                                  'assets/sponsor-3.png', 38 * s),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28 * s,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          Expanded(
                            child: Center(
                              child: _sponsorLogo(
                                  'assets/sponsor-2.png', 34 * s),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 28 * s,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          Expanded(
                            child: Center(
                              child: _sponsorLogo(
                                  'assets/sponsor-1.png', 38 * s),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: availableHeight * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
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
        return Container(
          height: height * 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              name.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dotLine(bool left, double s) {
    final color =
        left ? AppColors.accentBlue : const Color(0xFF7C3AED);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!left)
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        if (!left) const SizedBox(width: 4),
        Container(
          width: 40 * s,
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
              color: color.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildStars(double w, double h) {
    final r = Random(42);
    return List.generate(50, (i) {
      return Positioned(
        left: r.nextDouble() * w,
        top: r.nextDouble() * h,
        child: Container(
          width: 1.0 + r.nextDouble() * 1.8,
          height: 1.0 + r.nextDouble() * 1.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15 + r.nextDouble() * 0.5),
          ),
        ),
      );
    });
  }
}

class _PlanetArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final arcRect = Rect.fromCenter(
      center: Offset(w / 2, h + w * 0.6),
      width: w * 2.2,
      height: w * 2.2,
    );

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.6,
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.5),
          AppColors.accentBlue.withValues(alpha: 0.3),
          const Color(0xFF1E3A8A).withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawOval(arcRect, glowPaint);

    final arcLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accentBlue.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.9),
          const Color(0xFF7C3AED).withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(
        Path()..addArc(arcRect, -3.14159, 3.14159), arcLinePaint);

    final spotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          AppColors.accentBlue.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCenter(
          center: Offset(w / 2, h * 0.7), width: 80, height: 80));
    canvas.drawCircle(Offset(w / 2, h * 0.7), 40, spotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
