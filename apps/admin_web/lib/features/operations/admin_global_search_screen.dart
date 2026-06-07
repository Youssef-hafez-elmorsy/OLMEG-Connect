import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/firestore/admin_capped_query.dart';
import '../../core/widgets/admin_data_grid.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/widgets/admin_status_badge.dart';
import '../../core/widgets/admin_tokens.dart';

class AdminGlobalSearchScreen extends StatefulWidget {
  const AdminGlobalSearchScreen({super.key});

  @override
  State<AdminGlobalSearchScreen> createState() =>
      _AdminGlobalSearchScreenState();
}

class _AdminGlobalSearchScreenState extends State<AdminGlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Global Search',
      description:
          'Search capped admin working sets across users, merchants, products, orders, reports, and support.',
      icon: Icons.manage_search_outlined,
      bottom: _SearchBox(
        controller: _controller,
        onChanged: (value) => setState(() => _query = value.trim()),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= AdminBreakpoints.wide ? 2 : 1;
          final panels = const [
            _SearchCollectionConfig(
              title: 'Users',
              collectionName: 'users',
              icon: Icons.people_alt_outlined,
              routePrefix: '/users',
              fields: ['email', 'displayName', 'phone', 'accountStatus'],
            ),
            _SearchCollectionConfig(
              title: 'Merchants',
              collectionName: 'merchant_verifications',
              icon: Icons.storefront_outlined,
              routePrefix: '/merchants',
              fields: ['legalBusinessName', 'contactEmail', 'status'],
            ),
            _SearchCollectionConfig(
              title: 'Products',
              collectionName: 'products',
              icon: Icons.inventory_2_outlined,
              routePrefix: '/catalog/products',
              fields: ['title', 'name', 'sellerId', 'status', 'category'],
            ),
            _SearchCollectionConfig(
              title: 'Orders',
              collectionName: 'orders',
              icon: Icons.receipt_long_outlined,
              routePrefix: '/orders',
              fields: ['buyerId', 'status', 'paymentStatus'],
            ),
            _SearchCollectionConfig(
              title: 'Reports',
              collectionName: 'reports',
              icon: Icons.report_outlined,
              routePrefix: '/reports',
              fields: ['type', 'status', 'reporterId', 'targetId'],
            ),
            _SearchCollectionConfig(
              title: 'Support',
              collectionName: 'support_tickets',
              icon: Icons.support_agent_outlined,
              fields: ['subject', 'status', 'priority', 'userId'],
            ),
          ];

          return GridView.builder(
            itemCount: panels.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AdminSpacing.lg,
              mainAxisSpacing: AdminSpacing.lg,
              childAspectRatio: columns == 1 ? 1.55 : 1.35,
            ),
            itemBuilder: (context, index) {
              return _SearchCollectionPanel(
                config: panels[index],
                query: _query,
              );
            },
          );
        },
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      padding: const EdgeInsets.all(AdminSpacing.xs),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          hintText: 'Search by uid, email, title, phone, status, order id...',
          prefixIcon: Icon(Icons.search, size: 18),
          prefixIconConstraints: BoxConstraints(minWidth: 36),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AdminSpacing.sm,
            vertical: AdminSpacing.xs,
          ),
        ),
      ),
    );
  }
}

class _SearchCollectionConfig {
  final String title;
  final String collectionName;
  final IconData icon;
  final String? routePrefix;
  final List<String> fields;

  const _SearchCollectionConfig({
    required this.title,
    required this.collectionName,
    required this.icon,
    required this.fields,
    this.routePrefix,
  });
}

class _SearchCollectionPanel extends StatelessWidget {
  final _SearchCollectionConfig config;
  final String query;

  const _SearchCollectionPanel({
    required this.config,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final stream = cappedAdminQuery(
      FirebaseFirestore.instance.collection(config.collectionName),
    ).snapshots();

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(AdminRadius.xl),
        border: Border.all(color: AdminColors.border),
        boxShadow: AdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(config.icon, color: AdminColors.primary),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(
                  child: Text(
                    config.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const AdminStatusBadge(
                  label: '25 cap',
                  tone: AdminStatusTone.warning,
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.md),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Denied or missing index: ${snapshot.error}',
                      style: const TextStyle(color: AdminColors.danger),
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final docs = snapshot.data!.docs.where(_matches).toList();
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No capped results match this search.',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AdminColors.border),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _bestTitle(doc.id, data),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          config.fields
                              .map((field) =>
                                  '$field: ${adminCellValue(data[field])}')
                              .join('  |  '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: config.routePrefix == null
                            ? null
                            : const Icon(Icons.open_in_new),
                        onTap: config.routePrefix == null
                            ? null
                            : () =>
                                context.go('${config.routePrefix}/${doc.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matches(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();
    final haystack = [
      doc.id,
      ...config.fields.map((field) => adminCellValue(doc.data()[field])),
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }

  String _bestTitle(String id, Map<String, dynamic> data) {
    for (final field in ['title', 'name', 'displayName', 'email', 'subject']) {
      final value = data[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return id;
  }
}
