import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/firestore/admin_capped_query.dart';
import '../../core/widgets/admin_metric_card.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Command Center',
      description:
          'A live marketplace cockpit for queues, risk signals, staff action, and revenue operations.',
      icon: Icons.space_dashboard_outlined,
      eyebrow: 'Marketplace control room',
      actions: [
        Builder(
          builder: (context) {
            return FilledButton.icon(
              onPressed: () => _refreshSummary(context),
              icon: const Icon(Icons.sync),
              label: const Text('Refresh summary'),
            );
          },
        ),
      ],
      bottom: const _DashboardGuardrailBanner(),
      child: const _DashboardBody(),
    );
  }

  Future<void> _refreshSummary(BuildContext context) async {
    final reason = await askAdminReason(
      context,
      title: 'Refresh dashboard summary',
      actionLabel: 'Refresh',
      message: 'This runs a capped backend aggregation and writes audit logs.',
    );
    if (reason == null) return;
    try {
      await AdminActionService().refreshAdminSummary(reason: reason);
      if (!context.mounted) return;
      showAdminSnack(context, 'Dashboard summary refreshed.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Refresh failed: $error', isError: true);
    }
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AdminBreakpoints.wide;
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _OperationsPulse()),
            const SliverToBoxAdapter(child: SizedBox(height: AdminSpacing.lg)),
            if (wide)
              const SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _DashboardMetricsGrid()),
                    SizedBox(width: AdminSpacing.lg),
                    SizedBox(
                      width: 390,
                      child: Column(
                        children: [
                          _PriorityPanel(),
                          SizedBox(height: AdminSpacing.lg),
                          _OpsRunbookCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const SliverToBoxAdapter(child: _DashboardMetricsGrid()),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AdminSpacing.lg)),
              const SliverToBoxAdapter(child: _PriorityPanel()),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AdminSpacing.lg)),
              const SliverToBoxAdapter(child: _OpsRunbookCard()),
            ],
          ],
        );
      },
    );
  }
}

class _DashboardGuardrailBanner extends StatelessWidget {
  const _DashboardGuardrailBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminColors.infoSoft,
        border: Border.all(color: AdminColors.info.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.security_outlined, color: AdminColors.info, size: 16),
            SizedBox(width: AdminSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard widgets use capped reads from secured admin datasets. Backend commands, Firestore Rules, and Custom Claims enforce access; route guards are UX only.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AdminStatusBadge(
                        label: 'Today',
                        tone: AdminStatusTone.info,
                      ),
                      AdminStatusBadge(
                        label: '7 days',
                        tone: AdminStatusTone.neutral,
                      ),
                      AdminStatusBadge(
                        label: '30 days',
                        tone: AdminStatusTone.neutral,
                      ),
                      AdminStatusBadge(
                        label: 'Role scoped',
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

class _OperationsPulse extends StatelessWidget {
  const _OperationsPulse();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.ink,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final content = [
            const _PulseItem(
              icon: Icons.flash_on,
              title: 'Today focus',
              value: 'Clear queues before seller SLA breach',
            ),
            const _PulseItem(
              icon: Icons.fact_check_outlined,
              title: 'Trust ops',
              value: 'Moderation, reports, verification',
            ),
            const _PulseItem(
              icon: Icons.campaign_outlined,
              title: 'Growth ops',
              value: 'Campaigns capped and audited',
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (final item in content) ...[
                  item,
                  if (item != content.last)
                    const SizedBox(height: AdminSpacing.md),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (final item in content) ...[
                Expanded(child: item),
                if (item != content.last)
                  const SizedBox(width: AdminSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PulseItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _PulseItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AdminRadius.md),
          ),
          child: Icon(icon, color: AdminColors.accent),
        ),
        const SizedBox(width: AdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AdminColors.faint, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricsGrid extends StatelessWidget {
  const _DashboardMetricsGrid();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final cards = [
      _MetricCardConfig(
        title: 'Users',
        caption: 'Identity and buyer/seller accounts',
        icon: Icons.people_alt_outlined,
        color: AdminColors.primary,
        query: firestore.collection('users'),
      ),
      _MetricCardConfig(
        title: 'Open Reports',
        caption: 'Trust and support review queue',
        icon: Icons.report_outlined,
        color: AdminColors.danger,
        query: firestore.collection('reports'),
      ),
      _MetricCardConfig(
        title: 'Product Submissions',
        caption: 'Catalog moderation working set',
        icon: Icons.fact_check_outlined,
        color: AdminColors.warning,
        query: firestore.collection('product_submissions'),
      ),
      _MetricCardConfig(
        title: 'Merchant Reviews',
        caption: 'Seller onboarding pipeline',
        icon: Icons.storefront_outlined,
        color: AdminColors.info,
        query: firestore.collection('merchant_verifications'),
      ),
      _MetricCardConfig(
        title: 'Admin Campaigns',
        caption: 'Notification campaigns and delivery',
        icon: Icons.campaign_outlined,
        color: AdminColors.accent,
        query: firestore.collection('admin_notifications'),
      ),
      _MetricCardConfig(
        title: 'Payments',
        caption: 'Payment documents visible to admins',
        icon: Icons.payments_outlined,
        color: AdminColors.success,
        query: firestore.collection('payments'),
      ),
      _MetricCardConfig(
        title: 'Orders',
        caption: 'Order operations and exception context',
        icon: Icons.receipt_long_outlined,
        color: AdminColors.info,
        query: firestore.collection('orders'),
      ),
      _MetricCardConfig(
        title: 'Refunds',
        caption: 'Returns, refunds, and dispute queue',
        icon: Icons.assignment_return_outlined,
        color: AdminColors.warning,
        query: firestore.collection('refunds'),
      ),
      _MetricCardConfig(
        title: 'Support Tickets',
        caption: 'SLA and support queue health',
        icon: Icons.support_agent_outlined,
        color: AdminColors.primary,
        query: firestore.collection('support_tickets'),
      ),
      _MetricCardConfig(
        title: 'Risk Alerts',
        caption: 'Suspicious activity and watchlist cases',
        icon: Icons.radar_outlined,
        color: AdminColors.danger,
        query: firestore.collection('risk_cases'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AdminSpacing.md,
            mainAxisSpacing: AdminSpacing.md,
            childAspectRatio: columns == 1 ? 2.4 : 1.55,
          ),
          itemBuilder: (context, index) {
            return _DashboardMetricCard(config: cards[index]);
          },
        );
      },
    );
  }
}

class _MetricCardConfig {
  final String title;
  final String caption;
  final IconData icon;
  final Color color;
  final Query<Map<String, dynamic>> query;

  const _MetricCardConfig({
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.query,
  });
}

class _DashboardMetricCard extends StatelessWidget {
  final _MetricCardConfig config;

  const _DashboardMetricCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final query = cappedAdminQuery(config.query);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final value = snapshot.hasData
            ? snapshot.data!.docs.length.toString()
            : snapshot.hasError
                ? 'Denied'
                : '...';

        return AdminMetricCard(
          title: config.title,
          value: value,
          caption: '${config.caption}. Capped at 25.',
          icon: config.icon,
          color: config.color,
          trend: snapshot.hasError ? 'Rules' : 'Live',
        );
      },
    );
  }
}

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel();

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'Priority queues',
      icon: Icons.priority_high,
      child: Column(
        children: [
          _QueueRow(
            title: 'Seller verification',
            caption: 'Approve, reject, suspend',
            tone: AdminStatusTone.info,
          ),
          _QueueRow(
            title: 'Product moderation',
            caption: 'Approve, hide, escalate',
            tone: AdminStatusTone.warning,
          ),
          _QueueRow(
            title: 'Reports and safety',
            caption: 'Resolve, dismiss, escalate',
            tone: AdminStatusTone.danger,
          ),
          _QueueRow(
            title: 'Campaign control',
            caption: 'Create, cancel, audit',
            tone: AdminStatusTone.success,
          ),
          _QueueRow(
            title: 'Refund exceptions',
            caption: 'Resolve, escalate, link order',
            tone: AdminStatusTone.warning,
          ),
          _QueueRow(
            title: 'Risk review',
            caption: 'Open, escalate, resolve case',
            tone: AdminStatusTone.danger,
          ),
        ],
      ),
    );
  }
}

class _OpsRunbookCard extends StatelessWidget {
  const _OpsRunbookCard();

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'Operator rules',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleLine('Never trust hidden buttons as security.'),
          _RuleLine('Every sensitive action needs a reason.'),
          _RuleLine('Tables stay capped to protect Firestore cost and speed.'),
          _RuleLine('Use audit logs for accountability and rollback context.'),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PanelShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminColors.primary),
              const SizedBox(width: AdminSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final String title;
  final String caption;
  final AdminStatusTone tone;

  const _QueueRow({
    required this.title,
    required this.caption,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.md),
      child: Row(
        children: [
          AdminStatusBadge(label: 'Active', tone: tone),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(caption, style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String text;

  const _RuleLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AdminColors.success, size: 18),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
