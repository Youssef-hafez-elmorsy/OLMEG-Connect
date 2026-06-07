import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/firestore/admin_capped_query.dart';
import '../../core/widgets/admin_data_grid.dart';
import '../../core/widgets/admin_metric_card.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';

class PaymobOperationsScreen extends StatelessWidget {
  const PaymobOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminScaffold(
      title: 'Paymob Operations',
      description:
          'Monitor Paymob checkout attempts, HMAC webhooks, reconciliation exceptions, and backend-confirmed order payment state.',
      icon: Icons.account_balance_wallet_outlined,
      eyebrow: 'Payment command center',
      bottom: _PaymobGuardrailBanner(),
      child: _PaymobOperationsBody(),
    );
  }
}

class _PaymobOperationsBody extends StatelessWidget {
  const _PaymobOperationsBody();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaymobSummaryGrid(firestore: firestore),
          const SizedBox(height: AdminSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(AdminRadius.xl),
              border: Border.all(color: AdminColors.border),
            ),
            child: const TabBar(
              labelColor: AdminColors.ink,
              unselectedLabelColor: AdminColors.muted,
              indicatorColor: AdminColors.primary,
              tabs: [
                Tab(icon: Icon(Icons.payments_outlined), text: 'Payments'),
                Tab(icon: Icon(Icons.sync_problem_outlined), text: 'Reconcile'),
                Tab(icon: Icon(Icons.webhook_outlined), text: 'Webhooks'),
              ],
            ),
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: TabBarView(
              children: [
                _PaymobRecordsTable(
                  title: 'Paymob payment attempts',
                  subtitle:
                      'Protected source: payments. Filtered to provider=paymob and capped at 25 rows.',
                  query: firestore
                      .collection('payments')
                      .where('provider', isEqualTo: 'paymob')
                      .limit(adminDefaultPageSize),
                  columns: [
                    AdminDataGridColumn.field('Status', 'status', status: true),
                    AdminDataGridColumn.field('Ops', 'opsStatus', status: true),
                    AdminDataGridColumn.field('Order', 'orderId'),
                    AdminDataGridColumn.field('User', 'userId'),
                    AdminDataGridColumn(
                      label: 'Amount',
                      value: (data) => _moneyValue(data),
                    ),
                    AdminDataGridColumn.field('Intention', 'paymobIntentionId'),
                    AdminDataGridColumn.field(
                        'Transaction', 'paymobTransactionId'),
                    AdminDataGridColumn.field('Updated', 'updatedAt'),
                  ],
                  rowActionsBuilder: _paymentActions,
                ),
                _PaymobRecordsTable(
                  title: 'Paymob reconciliation queue',
                  subtitle:
                      'Protected source: payment_reconciliations. Backend writes only; admin actions are audited.',
                  query: firestore
                      .collection('payment_reconciliations')
                      .limit(adminDefaultPageSize),
                  columns: [
                    AdminDataGridColumn.field('Status', 'status', status: true),
                    AdminDataGridColumn.field('Ops', 'opsStatus', status: true),
                    AdminDataGridColumn.field('Order', 'orderId'),
                    AdminDataGridColumn.field('Payment', 'paymentId'),
                    AdminDataGridColumn.field('Transaction', 'transactionId'),
                    AdminDataGridColumn.field('Amount cents', 'amountCents'),
                    AdminDataGridColumn.field('Reason', 'reason', status: true),
                    AdminDataGridColumn.field('Updated', 'updatedAt'),
                  ],
                  rowActionsBuilder: _reconciliationActions,
                ),
                _PaymobRecordsTable(
                  title: 'Paymob webhook intake',
                  subtitle:
                      'Protected source: paymob_webhooks. HMAC-verified events and idempotency records.',
                  query: firestore
                      .collection('paymob_webhooks')
                      .limit(adminDefaultPageSize),
                  columns: [
                    AdminDataGridColumn.field('Status', 'status', status: true),
                    AdminDataGridColumn.field('Payment', 'paymentId'),
                    AdminDataGridColumn.field('Order', 'orderId'),
                    AdminDataGridColumn.field('Transaction', 'transactionId'),
                    AdminDataGridColumn.field('Reason', 'unmatchedReason',
                        status: true),
                    AdminDataGridColumn.field('Received', 'receivedAt'),
                    AdminDataGridColumn.field('Updated', 'updatedAt'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymobSummaryGrid extends StatelessWidget {
  final FirebaseFirestore firestore;

  const _PaymobSummaryGrid({required this.firestore});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PaymobMetricConfig(
        title: 'Paymob attempts',
        caption: 'Backend-created payment intentions',
        icon: Icons.payment_outlined,
        color: AdminColors.primary,
        query: firestore
            .collection('payments')
            .where('provider', isEqualTo: 'paymob'),
      ),
      _PaymobMetricConfig(
        title: 'Pending confirmation',
        caption: 'Waiting for Paymob webhook',
        icon: Icons.hourglass_top_outlined,
        color: AdminColors.warning,
        query: firestore
            .collection('payments')
            .where('provider', isEqualTo: 'paymob'),
        localFilter: (data) => data['status'] == 'pending',
      ),
      _PaymobMetricConfig(
        title: 'Reconciliation',
        caption: 'Latest reconciliation working set',
        icon: Icons.fact_check_outlined,
        color: AdminColors.info,
        query: firestore.collection('payment_reconciliations'),
      ),
      _PaymobMetricConfig(
        title: 'Webhook intake',
        caption: 'HMAC-verified Paymob events',
        icon: Icons.webhook_outlined,
        color: AdminColors.success,
        query: firestore.collection('paymob_webhooks'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SizedBox(
          height: compact ? 352 : 136,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compact ? 2 : 4,
              crossAxisSpacing: AdminSpacing.md,
              mainAxisSpacing: AdminSpacing.md,
              childAspectRatio: compact ? 1.58 : 1.68,
            ),
            itemBuilder: (context, index) => _PaymobMetricCard(cards[index]),
          ),
        );
      },
    );
  }
}

class _PaymobMetricConfig {
  final String title;
  final String caption;
  final IconData icon;
  final Color color;
  final Query<Map<String, dynamic>> query;
  final bool Function(Map<String, dynamic> data)? localFilter;

  const _PaymobMetricConfig({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.query,
    this.localFilter,
  });
}

class _PaymobMetricCard extends StatelessWidget {
  final _PaymobMetricConfig config;

  const _PaymobMetricCard(this.config);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: cappedAdminQuery(config.query).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final filteredCount = config.localFilter == null
            ? docs.length
            : docs.where((doc) => config.localFilter!(doc.data())).length;
        final value = snapshot.hasData
            ? filteredCount.toString()
            : snapshot.hasError
                ? 'Denied'
                : '...';
        return AdminMetricCard(
          title: config.title,
          value: value,
          caption: '${config.caption}. Capped at 25.',
          icon: config.icon,
          color: snapshot.hasError ? AdminColors.danger : config.color,
          trend: snapshot.hasError ? 'Rules' : 'Live',
        );
      },
    );
  }
}

class _PaymobRecordsTable extends StatelessWidget {
  final String title;
  final String subtitle;
  final Query<Map<String, dynamic>> query;
  final List<AdminDataGridColumn> columns;
  final AdminRowActionsBuilder? rowActionsBuilder;

  const _PaymobRecordsTable({
    required this.title,
    required this.subtitle,
    required this.query,
    required this.columns,
    this.rowActionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: cappedAdminQuery(query).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PaymobStateCard(
            icon: Icons.lock_outline,
            title: 'Unable to load protected Paymob data',
            message:
                'Firestore Rules rejected this request or the query needs an index.',
            details: snapshot.error.toString(),
          );
        }

        if (!snapshot.hasData) {
          return const _PaymobStateCard(
            icon: Icons.sync_outlined,
            title: 'Loading Paymob records',
            message: 'Reading a capped working set from secured collections.',
            loading: true,
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const _PaymobStateCard(
            icon: Icons.inventory_2_outlined,
            title: 'No Paymob records yet',
            message:
                'Once a buyer starts Paymob checkout, backend records appear here.',
          );
        }

        return AdminDataGrid(
          docs: docs,
          columns: columns,
          rowActionsBuilder: rowActionsBuilder,
          title: title,
          subtitle: subtitle,
        );
      },
    );
  }
}

class _PaymobGuardrailBanner extends StatelessWidget {
  const _PaymobGuardrailBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.infoSoft,
        border: Border.all(color: AdminColors.info.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AdminRadius.sm),
              ),
              child: const Icon(
                Icons.security_outlined,
                color: AdminColors.info,
                size: 16,
              ),
            ),
            const SizedBox(width: AdminSpacing.xs),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paymob security boundary: Flutter never stores secret keys or marks orders paid. Cloud Functions create intentions, Paymob webhooks confirm final status, and Firestore Rules block direct payment writes.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, height: 1.15),
                  ),
                  SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AdminStatusBadge(
                        label: 'Backend-only status',
                        tone: AdminStatusTone.success,
                      ),
                      AdminStatusBadge(
                        label: 'HMAC webhook',
                        tone: AdminStatusTone.info,
                      ),
                      AdminStatusBadge(
                        label: 'Capped at 25',
                        tone: AdminStatusTone.warning,
                      ),
                      AdminStatusBadge(
                        label: 'Audit required',
                        tone: AdminStatusTone.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymobStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? details;
  final bool loading;

  const _PaymobStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.details,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(AdminRadius.xl),
          border: Border.all(color: AdminColors.border),
          boxShadow: AdminShadows.card,
        ),
        padding: const EdgeInsets.all(AdminSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 48, color: AdminColors.primary),
              const SizedBox(height: AdminSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(message, textAlign: TextAlign.center),
              if (details != null) ...[
                const SizedBox(height: AdminSpacing.md),
                SelectableText(
                  details!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> _paymentActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final orderId = doc.data()['orderId']?.toString();
  return [
    if (orderId != null && orderId.isNotEmpty)
      OutlinedButton.icon(
        onPressed: () => context.go('/orders/$orderId'),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Order'),
      ),
    _auditedStatusAction(
      context,
      doc,
      label: 'Mark reviewed',
      action: 'payment_mark_reviewed',
      fields: {'opsStatus': 'reviewed'},
    ),
    _auditedStatusAction(
      context,
      doc,
      label: 'Escalate',
      action: 'payment_escalated',
      fields: {'opsStatus': 'escalated'},
    ),
  ];
}

List<Widget> _reconciliationActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final orderId = doc.data()['orderId']?.toString();
  return [
    if (orderId != null && orderId.isNotEmpty)
      OutlinedButton.icon(
        onPressed: () => context.go('/orders/$orderId'),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Order'),
      ),
    _auditedStatusAction(
      context,
      doc,
      label: 'Reviewed',
      action: 'paymob_reconciliation_reviewed',
      fields: {'opsStatus': 'reviewed'},
    ),
    _auditedStatusAction(
      context,
      doc,
      label: 'Escalate',
      action: 'paymob_reconciliation_escalated',
      fields: {'opsStatus': 'escalated'},
    ),
  ];
}

Widget _auditedStatusAction(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc, {
  required String label,
  required String action,
  required Map<String, Object?> fields,
}) {
  return OutlinedButton.icon(
    onPressed: () async {
      final reason = await askAdminReason(
        context,
        title: label,
        actionLabel: label,
        message:
            'Paymob operations are backend-command only and require an immutable audit log.',
      );
      if (reason == null) return;

      try {
        await AdminActionService().updateWithAudit(
          targetRef: doc.reference,
          data: fields,
          action: action,
          targetType: doc.reference.parent.id,
          reason: reason,
          metadata: {'workflow': 'paymob_operations'},
        );
        if (!context.mounted) return;
        showAdminSnack(context, '$label saved.');
      } catch (error) {
        if (!context.mounted) return;
        showAdminSnack(context, 'Action failed: $error', isError: true);
      }
    },
    icon: const Icon(Icons.verified_outlined),
    label: Text(label),
  );
}

String _moneyValue(Map<String, dynamic> data) {
  final amount = data['amount'];
  final amountCents = data['amountCents'];
  final currency = data['currency']?.toString() ?? 'EGP';
  if (amount is num) return '${amount.toStringAsFixed(2)} $currency';
  if (amountCents is num) {
    return '${(amountCents / 100).toStringAsFixed(2)} $currency';
  }
  return '-';
}
