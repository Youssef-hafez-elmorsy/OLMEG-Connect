import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/features/admin/data/admin_permissions.dart';
import 'package:olmeg_connect/features/admin/data/admin_dashboard_data.dart';
import 'package:olmeg_connect/features/admin/presentation/providers/admin_dashboard_provider.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardDataProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Admin'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: () => ref.invalidate(adminDashboardDataProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDashboardDataProvider.future),
        child: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _EmptyPanel(
                icon: Icons.error_outline,
                title: 'Dashboard failed to load',
                body: '$error',
              ),
            ],
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Header(data: data),
              const SizedBox(height: AppSpacing.lg),
              _MetricsGrid(data: data),
              const SizedBox(height: AppSpacing.xl),
              Text('Operations', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _ToolGrid(
                tools: [
                  _AdminTool(
                    title: 'Product moderation',
                    subtitle: '${data.pendingProducts} products need review',
                    icon: Icons.flag_outlined,
                    route: '/admin/moderation',
                    permission: AdminPermission.moderation,
                  ),
                  _AdminTool(
                    title: 'Merchant verification',
                    subtitle: '${data.pendingMerchants} merchant applications',
                    icon: Icons.storefront_outlined,
                    route: '/admin/merchants',
                    permission: AdminPermission.merchants,
                  ),
                  const _AdminTool(
                    title: 'User management',
                    subtitle: 'Ban, mute, suspend, and restore accounts',
                    icon: Icons.admin_panel_settings_outlined,
                    route: '/admin/users',
                    permission: AdminPermission.users,
                  ),
                  _AdminTool(
                    title: 'Reports & reviews',
                    subtitle: '${data.openReports} open reports',
                    icon: Icons.report_outlined,
                    route: '/admin/reports',
                    permission: AdminPermission.reports,
                  ),
                  const _AdminTool(
                    title: 'Notifications',
                    subtitle: 'Campaigns, segments, and announcements',
                    icon: Icons.notifications_active_outlined,
                    route: '/admin/notify',
                    permission: AdminPermission.notifications,
                  ),
                  _AdminTool(
                    title: 'Support tickets',
                    subtitle: '${data.supportTickets} active tickets',
                    icon: Icons.support_agent,
                    route: '/admin/support',
                    permission: AdminPermission.support,
                  ),
                  const _AdminTool(
                    title: 'Promotions & deals',
                    subtitle: 'Promote products and manage seller discounts',
                    icon: Icons.campaign_outlined,
                    route: '/admin/promotions',
                    permission: AdminPermission.promotions,
                  ),
                  const _AdminTool(
                    title: 'Operations center',
                    subtitle: 'Orders, payments, reports, sellers, users',
                    icon: Icons.dashboard_customize_outlined,
                    route: '/admin/operations',
                    permission: AdminPermission.operations,
                  ),
                  const _AdminTool(
                    title: 'Finance',
                    subtitle: 'GMV, fees, refunds, disputes, and payouts',
                    icon: Icons.account_balance_wallet_outlined,
                    route: '/admin/finance',
                    permission: AdminPermission.finance,
                  ),
                  const _AdminTool(
                    title: 'Risk & safety',
                    subtitle: 'Fraud signals, risk scores, and overrides',
                    icon: Icons.security_outlined,
                    route: '/admin/risk',
                    permission: AdminPermission.risk,
                  ),
                ]
                    .where((tool) => user?.canAdmin(tool.permission) == true)
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _LiveMonitoringPanel(data: data),
              const SizedBox(height: AppSpacing.xl),
              _AiModerationPanel(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AdminDashboardData data;

  const _Header({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marketplace command center',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Monitor users, sales, moderation, support, and seller health from one console.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _SignalChip(
                  icon: Icons.warning_amber_outlined,
                  label:
                      '${data.pendingProducts + data.openReports + data.supportTickets} needs attention',
                ),
                _SignalChip(
                  icon: Icons.payments_outlined,
                  label: CurrencyFormatter.egp(data.revenue),
                ),
                _SignalChip(
                  icon: Icons.people_alt_outlined,
                  label: '${data.users} users',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AdminDashboardData data;

  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : 2;
    final metrics = [
      _Metric('Users', '${data.users}', Icons.people_outline, Colors.blue),
      _Metric('Products', '${data.products}', Icons.inventory_2_outlined,
          Colors.green),
      _Metric('Orders', '${data.orders}', Icons.receipt_long_outlined,
          Colors.deepPurple),
      _Metric('Revenue', CurrencyFormatter.egp(data.revenue),
          Icons.account_balance_wallet_outlined, Colors.teal),
      _Metric('Reports', '${data.openReports}', Icons.report_outlined,
          AppColors.error),
      _Metric('Product review', '${data.pendingProducts}',
          Icons.fact_check_outlined, AppColors.warning),
      _Metric('Merchants', '${data.pendingMerchants}', Icons.store_outlined,
          Colors.indigo),
      _Metric('Support', '${data.supportTickets}', Icons.support_agent,
          Colors.orange),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: width >= 900 ? 2.6 : 1.55,
      ),
      itemBuilder: (context, index) => _StatCard(metric: metrics[index]),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  final List<_AdminTool> tools;

  const _ToolGrid({required this.tools});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 3 : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: width >= 900 ? 3.3 : 4.2,
      ),
      itemBuilder: (context, index) => _ToolCard(tool: tools[index]),
    );
  }
}

class _LiveMonitoringPanel extends StatelessWidget {
  final AdminDashboardData data;

  const _LiveMonitoringPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live monitoring',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _HealthRow(
              label: 'Live chats',
              value: '${data.activeChats}',
              icon: Icons.chat_bubble_outline,
            ),
            _HealthRow(
              label: 'Active order load',
              value: '${data.orders}',
              icon: Icons.local_shipping_outlined,
            ),
            _HealthRow(
              label: 'Fraud and report queue',
              value: '${data.openReports}',
              icon: Icons.security_outlined,
            ),
            const _HealthRow(
              label: 'Server health',
              value: 'Firebase online',
              icon: Icons.cloud_done_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiModerationPanel extends StatelessWidget {
  final AdminDashboardData data;

  const _AiModerationPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI moderation readiness',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'The queue is prepared for scam, spam, toxicity, counterfeit, and fake-listing scores when Phase 36 connects real AI services.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RiskChip(label: 'Scam probability', value: data.openReports),
                _RiskChip(
                    label: 'Spam probability', value: data.supportTickets),
                _RiskChip(
                    label: 'Fake listing score', value: data.pendingProducts),
                _RiskChip(
                  label: 'Counterfeit probability',
                  value: data.pendingProducts ~/ 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _Metric metric;

  const _StatCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: metric.color.withValues(alpha: 0.14),
              foregroundColor: metric.color,
              child: Icon(metric.icon),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    metric.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
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

class _ToolCard extends StatelessWidget {
  final _AdminTool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push(tool.route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(tool.icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tool.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SignalChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final int value;

  const _RiskChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        value > 0 ? Icons.warning_amber_outlined : Icons.check_circle_outline,
        size: 16,
      ),
      label: Text('$label: ${value > 0 ? 'watch' : 'clear'}'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _Metric(this.title, this.value, this.icon, this.color);
}

class _AdminTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final AdminPermission permission;

  const _AdminTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.permission,
  });
}
