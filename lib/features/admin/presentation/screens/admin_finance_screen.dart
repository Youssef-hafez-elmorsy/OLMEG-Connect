import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/utils/currency_formatter.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('finance_ledger')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading finance ledger');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Finance failed to load',
              message: '${snapshot.error}',
            );
          }
          final docs = snapshot.data?.docs ?? const [];
          final gmv = docs.fold<double>(
            0,
            (total, doc) =>
                total + ((doc.data()['gmv'] as num?)?.toDouble() ?? 0),
          );
          final fees = docs.fold<double>(
            0,
            (total, doc) =>
                total + ((doc.data()['platformFee'] as num?)?.toDouble() ?? 0),
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(child: _Metric('GMV', CurrencyFormatter.egp(gmv))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _Metric('Fees', CurrencyFormatter.egp(fees)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final doc in docs)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(doc.data()['orderId'] as String? ?? doc.id),
                    subtitle: Text(
                      'Seller ${doc.data()['sellerId'] ?? '-'} - ${doc.data()['payoutStatus'] ?? 'pending'}',
                    ),
                    trailing: Text(
                      CurrencyFormatter.egp(
                        (doc.data()['sellerPayout'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label),
          ],
        ),
      ),
    );
  }
}
