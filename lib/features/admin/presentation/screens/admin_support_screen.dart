import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading support tickets');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Support tickets failed to load',
              message: '${snapshot.error}',
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.support_agent,
              title: 'No support tickets yet',
              message:
                  'Refund, delivery, seller, and live support issues will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _TicketCard(
                doc: docs[index], actor: ref.watch(authStateProvider).value),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createManualTicket(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ticket'),
      ),
    );
  }

  Future<void> _createManualTicket(BuildContext context, WidgetRef ref) async {
    final ticket =
        await FirebaseFirestore.instance.collection('support_tickets').add({
      'title': 'Manual admin follow-up',
      'category': 'support',
      'status': 'open',
      'priority': 'normal',
      'userId': 'admin_created',
      'orderId': '',
      'summary': 'Created from the admin support desk.',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AdminAuditService.record(
      actor: ref.read(authStateProvider).value,
      action: 'support_ticket_created',
      targetType: 'support_ticket',
      targetId: ticket.id,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support ticket created.')),
      );
    }
  }
}

class _TicketCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final UserEntity? actor;

  const _TicketCard({required this.doc, required this.actor});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title'] as String? ?? 'Support request';
    final status = data['status'] as String? ?? 'open';
    final priority = data['priority'] as String? ?? 'normal';
    final category = data['category'] as String? ?? 'general';
    final userId = data['userId'] as String? ?? '-';
    final orderId = data['orderId'] as String? ?? '';
    final summary = data['summary'] as String? ??
        data['message'] as String? ??
        'No summary provided.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: Text(status)),
                Chip(label: Text(priority)),
                Chip(label: Text(category)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(summary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'User: $userId${orderId.isNotEmpty ? '  Order: $orderId' : ''}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _setStatus(context, 'in_progress'),
                  icon: const Icon(Icons.pending_actions),
                  label: const Text('In progress'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _setStatus(context, 'resolved'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Resolve'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _setPriority(context, 'urgent'),
                  icon: const Icon(Icons.priority_high),
                  label: const Text('Urgent'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(BuildContext context, String status) async {
    await doc.reference.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'resolved') 'resolvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.record(
      actor: actor,
      action: 'support_ticket_status_changed',
      targetType: 'support_ticket',
      targetId: doc.id,
      metadata: {'status': status},
    );
    await _updateSellerPenalty(status);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ticket marked $status.')));
    }
  }

  Future<void> _updateSellerPenalty(String status) async {
    final sellerIds = doc.data()['sellerIds'];
    if (sellerIds is! List) return;
    final increment = status == 'resolved' ? -1 : 1;
    for (final sellerId in sellerIds.whereType<String>()) {
      await FirebaseFirestore.instance
          .collection('sellerProfiles')
          .doc(sellerId)
          .set({
        'openDisputePenalty': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _setPriority(BuildContext context, String priority) async {
    await doc.reference.set({
      'priority': priority,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.record(
      actor: actor,
      action: 'support_ticket_priority_changed',
      targetType: 'support_ticket',
      targetId: doc.id,
      metadata: {'priority': priority},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ticket marked $priority.')));
    }
  }
}
