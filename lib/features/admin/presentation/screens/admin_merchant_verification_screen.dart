import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminMerchantVerificationScreen extends ConsumerWidget {
  const AdminMerchantVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Verification')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('merchant_verifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading merchant submissions');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Merchant submissions failed to load',
              message: '${snapshot.error}',
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No merchant submissions yet',
              message: 'Merchant verification requests will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _MerchantVerificationCard(
                doc: docs[index],
                actor: actor,
              );
            },
          );
        },
      ),
    );
  }
}

class _MerchantVerificationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final UserEntity? actor;

  const _MerchantVerificationCard({required this.doc, required this.actor});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final status = data['status'] as String? ?? 'submitted';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['legalBusinessName'] as String? ??
                            'Unnamed business',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        status,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow('Tax ID', data['taxId'] as String? ?? ''),
            _InfoRow('Business phone', data['businessPhone'] as String? ?? ''),
            _InfoRow('Contact email', data['contactEmail'] as String? ?? ''),
            _InfoRow(
              'Business address',
              data['businessAddress'] as String? ?? '',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setStatus(
                      context,
                      status: 'rejected',
                      label: 'Merchant rejected.',
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setStatus(
                      context,
                      status: 'suspended',
                      label: 'Merchant suspended.',
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspend'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _setStatus(
                      context,
                      status: 'approved',
                      label: 'Merchant approved.',
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context, {
    required String status,
    required String label,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance.collection('users').doc(doc.id);

    batch.update(doc.reference, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'accountType': 'merchant',
      'role': 'merchant',
      'merchantVerificationStatus': status,
      'isMerchant': true,
      'isApprovedMerchant': status == 'approved',
    });

    await batch.commit();

    final products = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: doc.id)
        .limit(450)
        .get();
    final submissions = await FirebaseFirestore.instance
        .collection('product_submissions')
        .where('sellerId', isEqualTo: doc.id)
        .limit(450)
        .get();
    final productsBatch = FirebaseFirestore.instance.batch();
    for (final product in products.docs) {
      final category = (product.data()['categoryName'] as String? ??
              product.data()['category'] as String? ??
              '')
          .toLowerCase();
      productsBatch.update(product.reference, {
        'sellerMerchantVerificationStatus': status,
        'deliveryEligible': status == 'approved' && category.contains('hand'),
      });
    }
    await productsBatch.commit();

    final submissionsBatch = FirebaseFirestore.instance.batch();
    for (final product in submissions.docs) {
      final category = (product.data()['categoryName'] as String? ??
              product.data()['category'] as String? ??
              '')
          .toLowerCase();
      submissionsBatch.update(product.reference, {
        'sellerMerchantVerificationStatus': status,
        'deliveryEligible': status == 'approved' && category.contains('hand'),
      });
    }
    await submissionsBatch.commit();
    await AdminAuditService.record(
      actor: actor,
      action: 'merchant_verification_$status',
      targetType: 'seller',
      targetId: doc.id,
    );
    await AdminAuditService.moderationHistory(
      actor: actor,
      targetType: 'seller',
      targetId: doc.id,
      status: status,
      note: 'Merchant verification updated to $status.',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(label)));
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
