import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Eligibility', [
              'You must be at least 13 years old to use the app.',
            ]),
            _buildSection('2. Account Responsibility', [
              'You are responsible for your account',
              'Keep credentials secure',
              'Provide accurate information',
            ]),
            _buildSection('3. Marketplace Rules', [
              'Listings must be legal and accurate',
              'No prohibited or harmful items',
              'You are responsible for your products',
            ]),
            _buildSection('4. AI Moderation', [
              'We may automatically review listings',
              'We may reject or remove content',
            ]),
            _buildSection('5. Payments', [
              'Processed via third-party providers',
              'We are not liable for external payment failures',
            ]),
            _buildSection('6. Prohibited Conduct', [
              'Users may not commit fraud or scams',
              'Upload illegal or offensive content',
              'Violate intellectual property rights',
              'Abuse the platform',
            ]),
            _buildSection('7. Ratings & Reviews', [
              'Must be honest',
              'No fake reviews or manipulation',
            ]),
            _buildSection('8. Account Suspension', [
              'We may suspend or terminate accounts that violate policies.',
            ]),
            _buildSection('9. Liability Disclaimer', [
              'Olmeg Connect acts as a platform only',
              'We do not guarantee product quality',
              'We are not responsible for disputes between users',
            ]),
            _buildSection('10. Privacy Reference', [
              'Use of the app is also governed by our Privacy Policy.',
            ]),
            _buildSection('11. Changes', [
              'We may modify these terms at any time.',
            ]),
            _buildSection('12. Governing Law', [
              'Egyptian law',
              'Applicable international regulations (e.g., GDPR if relevant)',
            ]),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Column(
                children: [
                  Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  SizedBox(height: 8),
                  Text('Email: olmegconnect@gmail.com', style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Effective Date: ${DateTime.now().year}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
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
                    const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(p, style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}