import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:olmeg_connect/features/reports/domain/entities/report_entity.dart';
import 'package:olmeg_connect/features/reports/presentation/providers/report_provider.dart';
import 'package:olmeg_connect/features/reviews/domain/entities/review_entity.dart';
import 'package:olmeg_connect/features/reviews/presentation/providers/review_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(openReportsProvider);
    final reviewsAsync = ref.watch(pendingReviewsProvider);
    final actor = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Reviews')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Open reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          reportsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Failed to load reports: $error'),
            data: (reports) {
              if (reports.isEmpty) return const Text('No open reports');
              return Column(
                children: [
                  for (final report in reports)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.report_outlined),
                        title: Text(
                            '${report.targetType.name}: ${report.targetId}'),
                        subtitle: Text(report.reason),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Dismiss',
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                await resolveReport(
                                  report.id,
                                  ReportStatus.dismissed,
                                );
                                await AdminAuditService.record(
                                  actor: actor,
                                  action: 'report_dismissed',
                                  targetType: report.targetType.name,
                                  targetId: report.targetId,
                                  metadata: {'reportId': report.id},
                                );
                                await AdminAuditService.moderationHistory(
                                  actor: actor,
                                  targetType: report.targetType.name,
                                  targetId: report.targetId,
                                  status: 'report_dismissed',
                                  note: report.reason,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Resolve',
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                if (report.targetType ==
                                    ReportTargetType.seller) {
                                  await FirebaseFirestore.instance
                                      .collection('sellerProfiles')
                                      .doc(report.targetId)
                                      .set({
                                    'verificationStatus': 'suspended',
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));
                                }
                                await resolveReport(
                                  report.id,
                                  ReportStatus.resolved,
                                );
                                await AdminAuditService.record(
                                  actor: actor,
                                  action: 'report_resolved',
                                  targetType: report.targetType.name,
                                  targetId: report.targetId,
                                  metadata: {'reportId': report.id},
                                );
                                await AdminAuditService.moderationHistory(
                                  actor: actor,
                                  targetType: report.targetType.name,
                                  targetId: report.targetId,
                                  status: 'report_resolved',
                                  note: report.reason,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reviews pending moderation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          reviewsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Failed to load reviews: $error'),
            data: (reviews) {
              if (reviews.isEmpty) return const Text('No reviews pending');
              return Column(
                children: [
                  for (final review in reviews)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.rate_review_outlined),
                        title:
                            Text('${review.rating}/5 for ${review.productId}'),
                        subtitle: Text(review.body),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Hide',
                              icon: const Icon(Icons.visibility_off_outlined),
                              onPressed: () async {
                                await updateReviewModerationStatus(
                                  review.id,
                                  ReviewModerationStatus.hidden,
                                );
                                await AdminAuditService.moderationHistory(
                                  actor: actor,
                                  targetType: 'review',
                                  targetId: review.id,
                                  status: 'hidden',
                                  note: review.body,
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Approve',
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                await updateReviewModerationStatus(
                                  review.id,
                                  ReviewModerationStatus.visible,
                                );
                                await AdminAuditService.moderationHistory(
                                  actor: actor,
                                  targetType: 'review',
                                  targetId: review.id,
                                  status: 'visible',
                                  note: review.body,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
