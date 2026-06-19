import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Screen 1c — Terms & Conditions
class S1cTermsScreen extends StatelessWidget {
  const S1cTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final s = (sw / 390).clamp(0.85, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28 * s,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24 * s),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''By using Coder, you agree to the following terms:

1. Acceptance of Terms
By accessing or using the app, you agree to be bound by these Terms.

2. AI Models and Data
Coder uses third-party AI models to assist with software development. Your code and prompts may be processed by these models. Do not submit sensitive or personally identifiable information.

3. User Responsibilities
You are solely responsible for the code generated and any actions taken based on the app's output. Coder is not liable for bugs, security vulnerabilities, or other issues in the generated code.

4. Intellectual Property
You retain ownership of your code. However, you grant Coder a license to use your code and prompts to improve our services, subject to our Privacy Policy.

5. Modifications
We reserve the right to modify these Terms at any time. Continued use of the app constitutes acceptance of any changes.

Please read carefully before proceeding.''',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14 * s,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24 * s),
              SizedBox(
                width: double.infinity,
                height: 54 * s,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16 * s),
                    ),
                  ),
                  onPressed: () {
                    // In a real app we'd save this to SharedPreferences
                    context.go('/startup');
                  },
                  child: Text(
                    'I Agree',
                    style: TextStyle(
                      fontSize: 18 * s,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Show a message or exit
                  },
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16 * s,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
