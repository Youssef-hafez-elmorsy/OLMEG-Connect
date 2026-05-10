import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Total Products',
                  value: '0',
                  icon: Icons.shopping_bag,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Total Posts',
                  value: '0',
                  icon: Icons.article,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Total Revenue',
                  value: 'EGP 0',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Admin Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'Send Notification',
              subtitle: 'Send push notifications to users',
              icon: Icons.notifications,
              onTap: () => context.push('/admin/notify'),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'Moderation',
              subtitle: 'Review AI-flagged product submissions',
              icon: Icons.flag,
              onTap: () => context.push('/admin/moderation'),
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'User Management',
              subtitle: 'Manage users and permissions',
              icon: Icons.admin_panel_settings,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'Analytics',
              subtitle: 'View detailed analytics',
              icon: Icons.analytics,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'Reports',
              subtitle: 'Generate system reports',
              icon: Icons.assessment,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminToolButton(
              title: 'Send Notification',
              subtitle: 'Send push notification to users',
              icon: Icons.notifications,
              onTap: () => context.push('/admin/notify'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminToolButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminToolButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
