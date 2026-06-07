import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';

class AdminOperationsScreen extends StatelessWidget {
  const AdminOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Operations Center')),
      body: FutureBuilder<List<AggregateQuerySnapshot>>(
        future: Future.wait([
          firestore.collection('orders').count().get(),
          firestore.collection('users').count().get(),
          firestore.collection('reports').count().get(),
          firestore.collection('support_tickets').count().get(),
          firestore.collection('merchant_verifications').count().get(),
          firestore.collection('audit_logs').count().get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading operations');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Operations failed to load',
              message: '${snapshot.error}',
            );
          }
          final counts = snapshot.data ?? const [];
          final cards = [
            _OpsCard('Orders', counts[0].count ?? 0,
                Icons.receipt_long_outlined, Colors.deepPurple),
            _OpsCard('Users', counts[1].count ?? 0, Icons.people_outline,
                Colors.blue),
            _OpsCard('Reports', counts[2].count ?? 0, Icons.report_outlined,
                AppColors.error),
            _OpsCard('Support', counts[3].count ?? 0, Icons.support_agent,
                Colors.orange),
            _OpsCard('Sellers', counts[4].count ?? 0, Icons.store_outlined,
                Colors.indigo),
            _OpsCard('Audit events', counts[5].count ?? 0,
                Icons.history_outlined, Colors.teal),
          ];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 900 ? 3 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.9,
                ),
                itemBuilder: (context, index) => cards[index],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Recent audit trail',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore
                    .collection('audit_logs')
                    .orderBy('createdAt', descending: true)
                    .limit(25)
                    .snapshots(),
                builder: (context, auditSnapshot) {
                  if (auditSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final docs = auditSnapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.history_outlined,
                      title: 'No audit events yet',
                      message: 'Admin and seller actions will appear here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final doc in docs)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(doc.data()['action'] as String? ??
                                'Admin action'),
                            subtitle: Text(
                              '${doc.data()['targetType'] ?? 'target'}: ${doc.data()['targetId'] ?? doc.id}',
                            ),
                            trailing:
                                Text(doc.data()['actorRole'] as String? ?? ''),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OpsCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _OpsCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  Text('$value',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
