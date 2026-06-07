import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';

class AdminRiskScreen extends StatelessWidget {
  const AdminRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk & Safety')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('risk_signals')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading risk signals');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Risk signals failed to load',
              message: '${snapshot.error}',
            );
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.security_outlined,
              title: 'No risk signals',
              message:
                  'Fraud, spam, payment, and moderation signals appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.security_outlined),
                  title: Text(data['signal'] as String? ?? 'Risk signal'),
                  subtitle: Text(
                    '${data['targetType'] ?? 'target'}: ${data['targetId'] ?? docs[index].id}',
                  ),
                  trailing: Text('${data['score'] ?? 0}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
