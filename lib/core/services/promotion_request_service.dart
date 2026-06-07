import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class PromotionRequestService {
  static const Map<int, int> packages = {
    1: 50,
    2: 90,
    3: 120,
    7: 180,
    14: 300,
  };

  static Future<void> showPromotionSheet({
    required BuildContext context,
    required String ownerId,
    required String targetId,
    required String targetTitle,
    required String targetType,
    bool allowDeal = false,
    bool requireDeal = false,
  }) async {
    int selectedDays = 1;
    final dealController = TextEditingController();
    final canCreateDeal = allowDeal || requireDeal;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final amount = packages[selectedDays] ?? 50;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requireDeal
                          ? 'Create product offer'
                          : 'Promote ${targetType == 'post' ? 'post' : 'product'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      targetTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDays,
                      decoration: const InputDecoration(
                        labelText: 'Promotion package',
                        border: OutlineInputBorder(),
                      ),
                      items: packages.entries
                          .map(
                            (entry) => DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(
                                  '${entry.key} day(s) - EGP ${entry.value}'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedDays = value);
                      },
                    ),
                    if (canCreateDeal) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: dealController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Offer discount percent',
                          helperText: 'Activated after payment is approved',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(requireDeal
                            ? Icons.local_offer_outlined
                            : Icons.campaign_outlined),
                        label: Text(
                          requireDeal
                              ? 'Request offer - EGP $amount'
                              : 'Request promotion - EGP $amount',
                        ),
                        onPressed: () async {
                          final requestedDealPercent =
                              int.tryParse(dealController.text.trim());
                          if (requireDeal &&
                              (requestedDealPercent == null ||
                                  requestedDealPercent <= 0)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Enter an offer discount percent.'),
                              ),
                            );
                            return;
                          }
                          await createPromotionOrder(
                            ownerId: ownerId,
                            targetId: targetId,
                            targetTitle: targetTitle,
                            targetType: targetType,
                            packageDays: selectedDays,
                            requestedDealPercent:
                                canCreateDeal ? requestedDealPercent : null,
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  requireDeal
                                      ? 'Offer request created. Complete payment to activate.'
                                      : 'Promotion request created. Complete payment to activate.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    dealController.dispose();
  }

  static Future<void> createPromotionOrder({
    required String ownerId,
    required String targetId,
    required String targetTitle,
    required String targetType,
    required int packageDays,
    int? requestedDealPercent,
  }) async {
    final amountEgp = packages[packageDays] ?? 50;
    final dealPercent =
        requestedDealPercent == null || requestedDealPercent <= 0
            ? null
            : requestedDealPercent.clamp(1, 90);
    final promotionType = dealPercent == null ? 'sponsor' : 'deal';

    final data = {
      'sellerId': ownerId,
      'ownerId': ownerId,
      'targetId': targetId,
      'targetTitle': targetTitle,
      'targetType': targetType,
      if (targetType == 'product') 'productId': targetId,
      if (targetType == 'post') 'postId': targetId,
      'promotionType': promotionType,
      'packageDays': packageDays,
      'amountEgp': amountEgp,
      'requestedDealPercent': dealPercent,
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'startsAt': null,
      'endsAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final orderRef = await FirebaseFirestore.instance
        .collection('promotion_orders')
        .add(data);
    await FirebaseFirestore.instance.collection('sponsored_campaigns').add({
      ...data,
      'promotionOrderId': orderRef.id,
      'targeting': {'placement': 'home_search_feed', 'language': 'all'},
      'spend': 0,
      'impressions': 0,
      'clicks': 0,
      'conversions': 0,
    });
  }
}
