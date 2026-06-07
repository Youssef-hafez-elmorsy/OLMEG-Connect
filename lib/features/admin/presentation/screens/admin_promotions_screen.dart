import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminPromotionsScreen extends ConsumerWidget {
  const AdminPromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = ref.watch(authStateProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Promotion payment orders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('promotion_orders')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading promotion orders');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Promotions failed to load',
              message: '${snapshot.error}',
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.campaign_outlined,
              title: 'No paid promotion orders',
              message:
                  'Sellers create promotion or deal requests before payment.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) =>
                _PromotionOrderCard(doc: docs[index], actor: actor),
          );
        },
      ),
    );
  }
}

class _PromotionOrderCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final UserEntity? actor;

  const _PromotionOrderCard({required this.doc, required this.actor});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final productId = data['productId'] as String? ?? '';
    final sellerId = data['sellerId'] as String? ?? '';
    final promotionType = data['promotionType'] as String? ?? 'promote';
    final status = data['status'] as String? ?? 'pending_payment';
    final paymentStatus = data['paymentStatus'] as String? ?? 'pending';
    final packageDays = (data['packageDays'] as num?)?.toInt() ?? 1;
    final amountEgp = (data['amountEgp'] as num?)?.toDouble() ?? 0;
    final dealPercent = (data['requestedDealPercent'] as num?)?.toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promotionType == 'deal'
                            ? 'Seller-paid deal request'
                            : 'Seller-paid promotion request',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product $productId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'Seller $sellerId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: Text('$packageDays day(s)')),
                Chip(label: Text(CurrencyFormatter.egp(amountEgp))),
                Chip(label: Text('Payment: $paymentStatus')),
                Chip(label: Text('Status: $status')),
                if (dealPercent != null)
                  Chip(label: Text('$dealPercent% deal after payment')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (status == 'pending_payment')
                  ElevatedButton.icon(
                    onPressed: () => _markPaidAndActivate(context),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Mark paid & activate'),
                  ),
                if (status == 'active')
                  OutlinedButton.icon(
                    onPressed: () => _endPromotion(context),
                    icon: const Icon(Icons.close),
                    label: const Text('End promotion'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaidAndActivate(BuildContext context) async {
    final data = doc.data();
    final productId = data['productId'] as String? ?? '';
    final packageDays = (data['packageDays'] as num?)?.toInt() ?? 1;
    final promotionType = data['promotionType'] as String? ?? 'promote';
    final dealPercent = (data['requestedDealPercent'] as num?)?.toInt();
    if (productId.isEmpty) return;

    final now = DateTime.now();
    final endsAt = now.add(Duration(days: packageDays));
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(productId);
    final product = await productRef.get();
    final price = (product.data()?['price'] as num?)?.toDouble() ?? 0;
    final salePrice =
        dealPercent == null ? null : price * (1 - dealPercent / 100);

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      doc.reference,
      {
        'status': 'active',
        'paymentStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'startsAt': Timestamp.fromDate(now),
        'endsAt': Timestamp.fromDate(endsAt),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      productRef,
      {
        'promotionStatus': promotionType == 'deal' ? 'deal' : 'promoted',
        'promotionOrderId': doc.id,
        'promotionPriority': 10,
        'promotionEndsAt': Timestamp.fromDate(endsAt),
        'dealPercent': dealPercent ?? FieldValue.delete(),
        'salePriceOverride': salePrice ?? FieldValue.delete(),
        'discountCampaignId':
            dealPercent == null ? FieldValue.delete() : doc.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _syncSponsoredCampaign(status: 'active');
    await batch.commit();
    await _audit('seller_paid_promotion_activated', {
      'productId': productId,
      'packageDays': packageDays,
      'promotionType': promotionType,
      'dealPercent': dealPercent,
    });
    if (context.mounted) _toast(context, 'Promotion activated after payment.');
  }

  Future<void> _endPromotion(BuildContext context) async {
    final productId = doc.data()['productId'] as String? ?? '';
    if (productId.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      doc.reference,
      {
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      FirebaseFirestore.instance.collection('products').doc(productId),
      {
        'promotionStatus': 'none',
        'promotionOrderId': FieldValue.delete(),
        'promotionPriority': FieldValue.delete(),
        'promotionEndsAt': FieldValue.delete(),
        'dealPercent': FieldValue.delete(),
        'salePriceOverride': FieldValue.delete(),
        'discountCampaignId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _syncSponsoredCampaign(status: 'ended');
    await batch.commit();
    await _audit('seller_paid_promotion_ended', {'productId': productId});
    if (context.mounted) _toast(context, 'Promotion ended.');
  }

  Future<void> _syncSponsoredCampaign({required String status}) async {
    final campaigns = await FirebaseFirestore.instance
        .collection('sponsored_campaigns')
        .where('promotionOrderId', isEqualTo: doc.id)
        .limit(5)
        .get();
    for (final campaign in campaigns.docs) {
      await campaign.reference.set({
        'status': status,
        'paymentStatus': status == 'active' ? 'paid' : 'closed',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _audit(String action,
      [Map<String, dynamic> metadata = const {}]) {
    return AdminAuditService.record(
      actor: actor,
      action: action,
      targetType: 'promotion_order',
      targetId: doc.id,
      metadata: metadata,
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
