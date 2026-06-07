import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../domain/entities/merchant_verification_entity.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();
  final _businessPhoneCtrl = TextEditingController();
  AccountType _accountType = AccountType.regular;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _businessNameCtrl.dispose();
    _taxIdCtrl.dispose();
    _businessAddressCtrl.dispose();
    _businessPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final merchantVerification = _accountType == AccountType.merchant
        ? MerchantVerificationEntity(
            userId: '',
            legalBusinessName: _businessNameCtrl.text.trim(),
            taxId: _taxIdCtrl.text.trim(),
            businessAddress: _businessAddressCtrl.text.trim(),
            businessPhone: _businessPhoneCtrl.text.trim(),
            contactEmail: _emailCtrl.text.trim(),
            createdAt: now,
            updatedAt: now,
          )
        : null;

    final error = await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          accountType: _accountType,
          merchantVerification: merchantVerification,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => closeOrGo(context, fallback: '/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: AppBrandLockup(
                    centered: true,
                    logoSize: 72,
                    titleSize: 24,
                    taglineSize: 13,
                    titleColor: AppColors.textPrimary,
                    taglineColor: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Join ${l10n.appName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  l10n.marketplaceTagline,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                SegmentedButton<AccountType>(
                  segments: const [
                    ButtonSegment(
                      value: AccountType.regular,
                      icon: Icon(Icons.person_outline),
                      label: Text('Regular user'),
                    ),
                    ButtonSegment(
                      value: AccountType.merchant,
                      icon: Icon(Icons.storefront_outlined),
                      label: Text('Merchant'),
                    ),
                  ],
                  selected: {_accountType},
                  onSelectionChanged: (selection) {
                    setState(() => _accountType = selection.first);
                  },
                ),
                if (_accountType == AccountType.merchant) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Text(
                      'Merchant accounts are reviewed before delivery features are enabled.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_accountType == AccountType.merchant) ...[
                  TextFormField(
                    controller: _businessNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Legal Business Name',
                      prefixIcon: Icon(Icons.badge_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) => _accountType == AccountType.merchant &&
                            (v == null || v.trim().isEmpty)
                        ? 'Business name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _taxIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Tax ID',
                      prefixIcon: Icon(Icons.receipt_long_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) => _accountType == AccountType.merchant &&
                            (v == null || v.trim().isEmpty)
                        ? 'Tax ID is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _businessAddressCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) => _accountType == AccountType.merchant &&
                            (v == null || v.trim().isEmpty)
                        ? 'Business address is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _businessPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Business Phone',
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: AppColors.textSecondary),
                    ),
                    validator: (v) => _accountType == AccountType.merchant &&
                            (v == null || v.trim().isEmpty)
                        ? 'Business phone is required'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Confirm Password
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
