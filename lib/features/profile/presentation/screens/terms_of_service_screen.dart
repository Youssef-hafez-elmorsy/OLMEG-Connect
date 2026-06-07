import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.getBackground(isDark);
    final surfaceColor = AppColors.getSurface(isDark);
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, '1. Eligibility', [
              'You must be at least 13 years old to use the app.',
            ]),
            _buildSection(context, '2. Account Responsibility', [
              'You are responsible for your account',
              'Keep credentials secure',
              'Provide accurate information',
            ]),
            _buildSection(context, '3. Marketplace Rules', [
              'Listings must be legal and accurate',
              'No prohibited or harmful items',
              'You are responsible for your products',
            ]),
            _buildSection(context, '4. AI Moderation', [
              'We may automatically review listings',
              'We may reject or remove content',
            ]),
            _buildSection(context, '5. Payments', [
              'Processed via third-party providers',
              'We are not liable for external payment failures',
            ]),
            _buildSection(context, '6. Prohibited Conduct', [
              'Users may not commit fraud or scams',
              'Upload illegal or offensive content',
              'Violate intellectual property rights',
              'Abuse the platform',
            ]),
            _buildSection(context, '7. Ratings & Reviews', [
              'Must be honest',
              'No fake reviews or manipulation',
            ]),
            _buildSection(context, '8. Account Suspension', [
              'We may suspend or terminate accounts that violate policies.',
            ]),
            _buildSection(context, '9. Liability Disclaimer', [
              'Olmeg Connect acts as a platform only',
              'We do not guarantee product quality',
              'We are not responsible for disputes between users',
            ]),
            _buildSection(context, '10. Privacy Reference', [
              'Use of the app is also governed by our Privacy Policy.',
            ]),
            _buildSection(context, '11. Changes', [
              'We may modify these terms at any time.',
            ]),
            _buildSection(context, '12. Governing Law', [
              'Egyptian law',
              'Applicable international regulations (e.g., GDPR if relevant)',
            ]),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  const Text('Contact',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text('Email: olmegconnect@gmail.com',
                      style: TextStyle(color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Effective Date: ${DateTime.now().year}',
                style: TextStyle(color: secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<String> points) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.getTextPrimary(isDark);
    final secondaryColor = AppColors.getTextSecondary(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: secondaryColor)),
                    Expanded(
                      child: Text(p, style: TextStyle(color: textColor)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
