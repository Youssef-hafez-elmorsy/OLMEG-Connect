import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'access_denied_screen.dart';
import '../core/navigation/external_link.dart';
import '../core/rbac/admin_access.dart';
import '../core/rbac/admin_roles.dart';
import '../core/widgets/admin_tokens.dart';

const String _publicAppUrl = String.fromEnvironment(
  'PUBLIC_APP_URL',
  defaultValue: '/',
);

class AdminAuthGate extends StatelessWidget {
  final Widget child;

  const AdminAuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult?>(
      future: FirebaseAuth.instance.currentUser?.getIdTokenResult(true),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _AdminLoadingShell();
        }
        final role = roleFromClaims(snapshot.data?.claims);
        if (role == null) {
          return const AccessDeniedScaffold();
        }
        return AdminShell(role: role, child: child);
      },
    );
  }
}

class AdminShell extends StatelessWidget {
  final AdminRole role;
  final Widget child;

  const AdminShell({
    super.key,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AdminBreakpoints.compact;
        final body = DecoratedBox(
          decoration: const BoxDecoration(gradient: AdminGradients.shell),
          child: Column(
            children: [
              _AdminTopBar(
                role: role,
                compact: compact,
                onMenuPressed:
                    compact ? () => Scaffold.of(context).openDrawer() : null,
              ),
              Expanded(child: child),
            ],
          ),
        );

        if (compact) {
          return Scaffold(
            drawer: _Sidebar(role: role, location: location, compact: true),
            body: Builder(
              builder: (context) {
                return DecoratedBox(
                  decoration:
                      const BoxDecoration(gradient: AdminGradients.shell),
                  child: Column(
                    children: [
                      _AdminTopBar(
                        role: role,
                        compact: true,
                        onMenuPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _Sidebar(role: role, location: location),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final AdminRole role;
  final String location;
  final bool compact;

  const _Sidebar({
    required this.role,
    required this.location,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeGroup = _activeGroupForLocation(role, location);
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: AdminColors.sidebar,
        boxShadow: AdminShadows.floating,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandLockup(role: role),
              const SizedBox(height: AdminSpacing.md),
              _RolePanel(role: role),
              const SizedBox(height: AdminSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    for (final group in adminNavigationGroupsFor(role)) ...[
                      _NavigationGroup(
                        role: role,
                        group: group,
                        location: location,
                        compact: compact,
                        initiallyExpanded: group == activeGroup,
                      ),
                      const SizedBox(height: AdminSpacing.sm),
                    ],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: AdminSpacing.sm),
                _SidebarActionButton(
                  icon: Icons.open_in_new,
                  label: 'Public app',
                  onPressed: () => _openPublicApp(context),
                ),
                const SizedBox(height: AdminSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AdminRadius.md),
                      ),
                    ),
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.manage_search_outlined, size: 18),
                    label: const Text('Global search'),
                  ),
                ),
              ],
              if (compact) ...[
                const SizedBox(height: AdminSpacing.sm),
                _SidebarActionButton(
                  icon: Icons.open_in_new,
                  label: 'Public app',
                  onPressed: () => _openPublicApp(context),
                ),
              ],
              const SizedBox(height: AdminSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminRadius.md),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationGroup extends StatelessWidget {
  final AdminRole role;
  final String group;
  final String location;
  final bool compact;
  final bool initiallyExpanded;

  const _NavigationGroup({
    required this.role,
    required this.group,
    required this.location,
    required this.compact,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final routes = adminNavigationRoutesFor(role, group).toList();
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        expansionTileTheme: const ExpansionTileThemeData(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.white,
          collapsedIconColor: AdminColors.faint,
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey('admin_nav_$group'),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        title: _NavSectionLabel(group),
        children: [
          for (final route in routes)
            _NavLink(
              label: route.title,
              path: route.path,
              icon: _iconForPath(route.path),
              selected: location == route.path ||
                  _isActiveDetail(location, route.path),
              compact: compact,
            ),
        ],
      ),
    );
  }
}

String? _activeGroupForLocation(AdminRole role, String location) {
  for (final group in adminNavigationGroupsFor(role)) {
    for (final route in adminNavigationRoutesFor(role, group)) {
      if (location == route.path || _isActiveDetail(location, route.path)) {
        return group;
      }
    }
  }
  return null;
}

class _BrandLockup extends StatelessWidget {
  final AdminRole role;

  const _BrandLockup({required this.role});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AdminRadius.lg),
      onTap: () => context.go(
        _firstReachablePath(role, const ['/dashboard', '/search']),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AdminGradients.command,
                borderRadius: BorderRadius.circular(AdminRadius.md),
              ),
              child: const Icon(Icons.storefront, color: Colors.white),
            ),
            const SizedBox(width: AdminSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olmeg',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    'Commerce Command',
                    style: TextStyle(color: AdminColors.faint, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AdminColors.faint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.22),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminRadius.md),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _RolePanel extends StatelessWidget {
  final AdminRole role;

  const _RolePanel({required this.role});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(AdminRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AdminColors.accent,
              foregroundColor: Colors.white,
              child: Icon(Icons.verified_user_outlined),
            ),
            const SizedBox(width: AdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signed in role',
                    style: TextStyle(color: AdminColors.faint, fontSize: 12),
                  ),
                  Text(
                    role.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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

class _AdminTopBar extends StatelessWidget {
  final AdminRole role;
  final bool compact;
  final VoidCallback? onMenuPressed;

  const _AdminTopBar({
    required this.role,
    required this.compact,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 78 : 88,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AdminSpacing.md : AdminSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: const Border(bottom: BorderSide(color: AdminColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          if (compact) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: AdminSpacing.sm),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: TextField(
                readOnly: true,
                onTap: () => context.go('/search'),
                decoration: InputDecoration(
                  hintText:
                      'Global search: users, merchants, products, orders...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: compact
                      ? null
                      : const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text('Ctrl K'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AdminColors.pageAlt,
                            side: BorderSide.none,
                          ),
                        ),
                ),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: AdminSpacing.md),
            _TopBarNavChip(
              icon: Icons.security_outlined,
              label: 'Rules enforced',
              color: AdminColors.primary,
              onPressed: () => context.go(
                _firstReachablePath(role, const [
                  '/audit-logs',
                  '/risk',
                  '/dashboard',
                ]),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            _TopIconButton(
              icon: Icons.open_in_new,
              tooltip: 'Public app',
              onPressed: () => _openPublicApp(context),
            ),
            const SizedBox(width: AdminSpacing.sm),
            _TopIconButton(
              icon: Icons.notifications_none,
              tooltip: 'Staff alerts',
              onPressed: () => context.go(
                _firstReachablePath(role, const [
                  '/notifications',
                  '/support/tickets',
                  '/dashboard',
                ]),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            _TopIconButton(
              icon: Icons.help_outline,
              tooltip: 'Runbook',
              onPressed: () => context.go(
                _firstReachablePath(role, const [
                  '/audit-logs',
                  '/risk',
                  '/dashboard',
                ]),
              ),
            ),
            const SizedBox(width: AdminSpacing.sm),
            Tooltip(
              message: 'Role settings',
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.go(
                  _firstReachablePath(role, const [
                    '/staff',
                    '/settings',
                    '/dashboard',
                  ]),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AdminColors.ink,
                  foregroundColor: Colors.white,
                  child: Text(role.value.substring(0, 1).toUpperCase()),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBarNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TopBarNavChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _firstReachablePath(AdminRole role, List<String> candidates) {
  for (final path in candidates) {
    if (canAccessPath(role, path)) return path;
  }
  return firstAllowedPath(role);
}

void _openPublicApp(BuildContext context) {
  final opened = openExternalLink(_publicAppUrl);
  if (opened || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Public app link is available on web builds. Configure PUBLIC_APP_URL for production.',
      ),
    ),
  );
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: AdminColors.cardWarm,
          foregroundColor: AdminColors.ink,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  final String label;

  const _NavSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AdminColors.faint,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.35,
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String path;
  final IconData icon;
  final bool selected;
  final bool compact;

  const _NavLink({
    required this.label,
    required this.path,
    required this.icon,
    required this.selected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AdminRadius.md),
          onTap: () {
            if (compact) Navigator.pop(context);
            context.go(path);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdminRadius.md),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AdminColors.ink : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AdminSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? AdminColors.ink : Colors.white,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: selected ? AdminColors.primary : AdminColors.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminLoadingShell extends StatelessWidget {
  const _AdminLoadingShell();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AdminGradients.shell),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

IconData _iconForPath(String path) {
  return switch (path) {
    '/dashboard' => Icons.space_dashboard_outlined,
    '/search' => Icons.manage_search_outlined,
    '/users' => Icons.people_alt_outlined,
    '/merchants' => Icons.storefront_outlined,
    '/catalog/products' => Icons.inventory_2_outlined,
    '/catalog/categories' => Icons.category_outlined,
    '/moderation/products' => Icons.fact_check_outlined,
    '/moderation/reviews' => Icons.rate_review_outlined,
    '/reports' => Icons.report_outlined,
    '/orders' => Icons.receipt_long_outlined,
    '/refunds' => Icons.assignment_return_outlined,
    '/payments' => Icons.payments_outlined,
    '/payments/paymob' => Icons.account_balance_wallet_outlined,
    '/support/tickets' => Icons.support_agent_outlined,
    '/notifications' => Icons.campaign_outlined,
    '/marketing/promotions' => Icons.local_offer_outlined,
    '/risk' => Icons.radar_outlined,
    '/analytics' => Icons.query_stats_outlined,
    '/audit-logs' => Icons.history_edu_outlined,
    '/staff' => Icons.admin_panel_settings_outlined,
    '/settings' => Icons.settings_outlined,
    _ => Icons.chevron_right,
  };
}

bool _isActiveDetail(String location, String routePath) {
  if (routePath == '/users') return location.startsWith('/users/');
  if (routePath == '/merchants') return location.startsWith('/merchants/');
  if (routePath == '/catalog/products') {
    return location.startsWith('/catalog/products/');
  }
  if (routePath == '/reports') return location.startsWith('/reports/');
  if (routePath == '/orders') return location.startsWith('/orders/');
  if (routePath == '/payments') {
    return location.startsWith('/payments/') && location != '/payments/paymob';
  }
  return false;
}

class AccessDeniedScaffold extends StatelessWidget {
  const AccessDeniedScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AccessDeniedScreen());
  }
}
