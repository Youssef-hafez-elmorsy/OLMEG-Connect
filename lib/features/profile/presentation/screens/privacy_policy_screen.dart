import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Privacy Policy'),
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
            _buildSection('1. Data We Collect', [
              'Personal Data: Name, email, phone number, profile information',
              'User Content: Product listings (images, descriptions, prices)',
              'Device & Usage Data: Device type, IP address, logs, app interactions',
              'Payment Data: Processed by secure third-party providers. We do not store card details.',
            ]),
            _buildSection('2. Legal Basis (GDPR)', [
              'Contract: To provide the app services',
              'Legitimate Interest: Security, fraud prevention, AI moderation',
              'Consent: Marketing notifications, optional data',
            ]),
            _buildSection('3. How We Use Data', [
              'Account creation & management',
              'Marketplace operations (buy/sell)',
              'AI moderation of listings',
              'Personalized recommendations',
              'Notifications',
              'Fraud prevention',
            ]),
            _buildSection('4. Data Sharing', [
              'Firebase (Google services)',
              'Payment providers',
              'Analytics services',
              'Authorities when legally required',
              'We never sell your data.',
            ]),
            _buildSection('5. International Transfers', [
              'Your data may be processed outside your country via Firebase servers. We ensure appropriate safeguards.',
            ]),
            _buildSection('6. Data Retention', [
              'As long as your account is active',
              'Or as required by law',
              'Deleted upon request (unless legally required)',
            ]),
            _buildSection('7. Your Rights', [
              'Access your data',
              'Correct inaccurate data',
              'Request deletion (Right to be forgotten)',
              'Object to processing',
              'Withdraw consent',
              'Contact: olmegconnect@gmail.com',
            ]),
            _buildSection('8. Security', [
              'Firebase secure infrastructure',
              'Encryption',
              'Access controls',
            ]),
            _buildSection('9. Google Play Compliance', [
              'We only collect necessary data',
              'Provide clear disclosure before collection',
              'Use data only for stated purposes',
              'Allow users to delete their accounts',
            ]),
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