import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/seller/presentation/providers/seller_provider.dart';

class SellerStorefrontScreen extends ConsumerStatefulWidget {
  const SellerStorefrontScreen({super.key});

  @override
  ConsumerState<SellerStorefrontScreen> createState() =>
      _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState
    extends ConsumerState<SellerStorefrontScreen> {
  final _storeNameController = TextEditingController();
  final _returnPolicyController = TextEditingController();
  final _shippingController = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _returnPolicyController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }

    final profileAsync = ref.watch(sellerProfileProvider(user.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Storefront')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load profile: $error')),
        data: (profile) {
          if (!_seeded) {
            _storeNameController.text =
                profile?.storeName ?? '${user.name} Store';
            _returnPolicyController.text = profile?.returnPolicy ?? '';
            _shippingController.text =
                profile?.shippingMethods.join(', ') ?? '';
            _seeded = true;
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text(
                    (profile?.ratingAverage ?? 0).toStringAsFixed(1),
                  ),
                  subtitle: Text('${profile?.ratingCount ?? 0} seller reviews'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Store name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _returnPolicyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Return policy'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _shippingController,
                decoration: const InputDecoration(
                  labelText: 'Shipping methods',
                  helperText: 'Separate methods with commas',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save storefront'),
                onPressed: () async {
                  await saveSellerProfile(
                    userId: user.id,
                    displayName: user.name,
                    storeName: _storeNameController.text.trim(),
                    returnPolicy: _returnPolicyController.text.trim(),
                    shippingMethods: _shippingController.text
                        .split(',')
                        .map((value) => value.trim())
                        .where((value) => value.isNotEmpty)
                        .toList(),
                    verificationStatus:
                        user.isApprovedMerchant ? 'verified' : 'pending',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Storefront saved')),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
