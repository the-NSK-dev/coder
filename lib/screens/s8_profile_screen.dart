import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/chat_provider.dart';
import '../providers/github_provider.dart';
import '../providers/ide_provider.dart';
import '../services/persistence_service.dart';
import '../theme/app_colors.dart';
import '../utils/nav_utils.dart';
import '../widgets/coder_app_bar.dart';
import '../theme/app_typography.dart';

/// Screen 8 — Profile/Settings: Band.ai, GitHub, verification toggle.
class S8ProfileScreen extends StatefulWidget {
  const S8ProfileScreen({super.key});

  @override
  State<S8ProfileScreen> createState() => _S8ProfileScreenState();
}

class _S8ProfileScreenState extends State<S8ProfileScreen> {
  final _persistence = PersistenceService();
  bool _verificationEnabled = true;
  bool _notificationsEnabled = true;
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() {
      _verificationEnabled = AppConfig.verificationEnabled;
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    await _persistence.saveVerificationEnabled(_verificationEnabled);

    AppConfig.applySettings(
      bandKey: AppConfig.bandUserApiKey,
      roomId: AppConfig.bandRoomId,
      aimlKey: AppConfig.aimlApiKey,
      verification: _verificationEnabled,
    );

    if (!mounted) return;
    final chat = context.read<ChatProvider>();
    final github = context.read<GitHubProvider>();
    context.read<IdeProvider>().reloadConfig();
    await chat.reloadConfig();
    github.syncFromAppConfig();

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Color(0xFF24A148),
        ),
      );
    }
  }



  @override
  void dispose() {
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
              onBack: () => popOrGo(context),
              showLogo: false,
              title: 'Settings',
            ),
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 24 * s),
                            Center(
                              child: Text(
                                'Settings',
                                style: AppTypography.headingLarge.copyWith(fontSize: 22 * s),
                              ),
                            ),

                            SizedBox(height: 32 * s),

                            _sectionHeader('VERIFICATION', s),
                            SizedBox(height: 16 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16 * s, vertical: 12 * s),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Three-step verification',
                                          style: AppTypography.bodyLarge.copyWith(fontSize: 14 * s, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 4 * s),
                                        Text(
                                          _verificationEnabled
                                              ? 'Planner → Engineer → Reviewer → Verifier'
                                              : 'Planner → Engineer only',
                                          style: AppTypography.bodyMedium.copyWith(fontSize: 12 * s, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _verificationEnabled,
                                    activeThumbColor: AppColors.accentBlue,
                                    onChanged: (v) =>
                                        setState(() => _verificationEnabled = v),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24 * s),
                            _sectionHeader('NOTIFICATIONS', s),
                            SizedBox(height: 16 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16 * s, vertical: 12 * s),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Agent Activity',
                                          style: AppTypography.bodyLarge.copyWith(fontSize: 14 * s, fontWeight: FontWeight.w600),
                                        ),
                                        SizedBox(height: 4 * s),
                                        Text(
                                          'Receive notifications when agents finish tasks.',
                                          style: AppTypography.bodyMedium.copyWith(fontSize: 12 * s, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    activeThumbColor: AppColors.accentBlue,
                                    onChanged: (v) =>
                                        setState(() => _notificationsEnabled = v),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 32 * s),
                            _sectionHeader('AI AGENT TEAM', s),
                            SizedBox(height: 16 * s),
                            _regionCard(
                                number: 1,
                                name: 'Planner',
                                subtitle: AppConfig.region1Config,
                                s: s),
                            SizedBox(height: 8 * s),
                            _regionCard(
                                number: 2,
                                name: 'Engineer',
                                subtitle: AppConfig.region2Config,
                                s: s),
                            SizedBox(height: 8 * s),
                            _regionCard(
                                number: 3,
                                name: 'Reviewer',
                                subtitle: AppConfig.region3Config,
                                s: s),
                            SizedBox(height: 8 * s),
                            _regionCard(
                                number: 4,
                                name: 'Verifier',
                                subtitle: AppConfig.region4Config,
                                s: s),

                            SizedBox(height: 32 * s),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _saveSettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentBlue,
                                  padding: EdgeInsets.symmetric(vertical: 14 * s),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12 * s),
                                  ),
                                ),
                                child: _saving
                                    ? SizedBox(
                                        width: 20 * s,
                                        height: 20 * s,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Save Settings',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15 * s,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 24 * s),
                            _sectionHeader('LEGAL', s),
                            SizedBox(height: 16 * s),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text('Terms and Conditions', style: AppTypography.bodyMedium),
                                    trailing: Icon(Icons.open_in_new, size: 16 * s, color: AppColors.textMuted),
                                    onTap: () {},
                                  ),
                                  Divider(height: 1, color: AppColors.border),
                                  ListTile(
                                    title: Text('Privacy Policy', style: AppTypography.bodyMedium),
                                    trailing: Icon(Icons.open_in_new, size: 16 * s, color: AppColors.textMuted),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32 * s),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, double s) {
    return Padding(
      padding: EdgeInsets.only(left: 4 * s),
      child: Text(
        title,
        style: AppTypography.caption.copyWith(fontSize: 11 * s, color: AppColors.accentBlue, letterSpacing: 1.5, fontWeight: FontWeight.w700),
      ),
    );
  }



  Widget _regionCard({
    required int number,
    required String name,
    required String subtitle,
    required double s,
  }) {
    final colors = [
      AppColors.accentBlue,
      AppColors.accentPurple,
      const Color(0xFF22C55E),
      const Color(0xFFEAB308),
    ];
    final color = colors[(number - 1) % colors.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16 * s),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32 * s,
            height: 32 * s,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: TextStyle(
                      color: color,
                      fontSize: 14 * s,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyLarge.copyWith(fontSize: 14 * s, fontWeight: FontWeight.w600)),
                SizedBox(height: 4 * s),
                Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 12 * s, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
