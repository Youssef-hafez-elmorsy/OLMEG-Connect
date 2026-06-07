import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class SellerBulkToolsScreen extends ConsumerStatefulWidget {
  const SellerBulkToolsScreen({super.key});

  @override
  ConsumerState<SellerBulkToolsScreen> createState() =>
      _SellerBulkToolsScreenState();
}

class _SellerBulkToolsScreenState extends ConsumerState<SellerBulkToolsScreen> {
  final _csvController = TextEditingController();
  final _handlingController = TextEditingController(text: '2');
  final _campaignProductController = TextEditingController();
  final _dealPercentController = TextEditingController();
  final Map<int, int> _promotionPackages = const {
    1: 50,
    2: 90,
    3: 120,
    7: 180,
    14: 300,
  };
  int _selectedPackageDays = 1;
  bool _vacationMode = false;

  @override
  void dispose() {
    _csvController.dispose();
    _handlingController.dispose();
    _campaignProductController.dispose();
    _dealPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk seller tools')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Section(
            title: 'CSV upload template',
            child: TextField(
              controller: _csvController,
              maxLines: 8,
              decoration: const InputDecoration(
                helperText:
                    'title,description,price,stock,category,status,discount',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => _importCsv(user.id),
                icon: const Icon(Icons.upload_file),
                label: const Text('Import CSV'),
              ),
              OutlinedButton.icon(
                onPressed: () => _bulkUpdate(user.id, {'status': 'draft'}),
                icon: const Icon(Icons.drafts_outlined),
                label: const Text('Move all to draft'),
              ),
              OutlinedButton.icon(
                onPressed: () => _bulkUpdate(user.id, {'dealPercent': 10}),
                icon: const Icon(Icons.percent),
                label: const Text('10% discount all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Low-stock alerts',
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: user.id)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                final lowStock = (snapshot.data?.docs ?? const []).where((doc) {
                  final data = doc.data();
                  final stock = (data['stockQuantity'] as num?)?.toInt() ??
                      (data['stock'] as num?)?.toInt() ??
                      0;
                  return stock <= 3;
                }).toList();
                if (lowStock.isEmpty) return const Text('No low-stock items.');
                return Column(
                  children: [
                    for (final doc in lowStock)
                      ListTile(
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(doc.data()['title'] as String? ?? doc.id),
                        subtitle: const Text('Restock reminder'),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Paid promotion or deal',
            child: Column(
              children: [
                TextField(
                  controller: _campaignProductController,
                  decoration: const InputDecoration(labelText: 'Product ID'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _selectedPackageDays,
                  decoration: const InputDecoration(
                    labelText: 'Promotion package',
                    border: OutlineInputBorder(),
                  ),
                  items: _promotionPackages.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child:
                              Text('${entry.key} day(s) - EGP ${entry.value}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedPackageDays = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _dealPercentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Optional deal percent after payment',
                    helperText:
                        'Leave empty for promotion only. Deals activate after payment confirmation.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => _createCampaign(user.id),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Submit campaign'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Section(
            title: 'Vacation and handling time',
            child: Column(
              children: [
                SwitchListTile(
                  value: _vacationMode,
                  onChanged: (value) => setState(() => _vacationMode = value),
                  title: const Text('Vacation mode'),
                ),
                TextField(
                  controller: _handlingController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Handling time days'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => _saveSellerSettings(user.id),
                  child: const Text('Save settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv(String sellerId) async {
    final lines = _csvController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('title,'));
    for (final line in lines) {
      final cells = line.split(',');
      if (cells.length < 4) continue;
      final ref =
          FirebaseFirestore.instance.collection('product_submissions').doc();
      await ref.set({
        'title': cells[0],
        'description': cells.length > 1 ? cells[1] : '',
        'price': double.tryParse(cells.length > 2 ? cells[2] : '') ?? 0,
        'stockQuantity': int.tryParse(cells.length > 3 ? cells[3] : '') ?? 1,
        'categoryName': cells.length > 4 ? cells[4] : 'New',
        'status': cells.length > 5 ? cells[5] : 'draft',
        'dealPercent': int.tryParse(cells.length > 6 ? cells[6] : ''),
        'sellerId': sellerId,
        'moderationStatus': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CSV imported.')));
    }
  }

  Future<void> _bulkUpdate(String sellerId, Map<String, dynamic> fields) async {
    final docs = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .limit(450)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs.docs) {
      batch.set(
          doc.reference,
          {
            ...fields,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bulk update saved.')));
    }
  }

  Future<void> _saveSellerSettings(String sellerId) async {
    await FirebaseFirestore.instance
        .collection('sellerProfiles')
        .doc(sellerId)
        .set({
      'vacationMode': _vacationMode,
      'handlingTimeDays': int.tryParse(_handlingController.text.trim()) ?? 2,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller settings saved.')));
    }
  }

  Future<void> _createCampaign(String sellerId) async {
    final productId = _campaignProductController.text.trim();
    if (productId.isEmpty) return;
    final amountEgp = _promotionPackages[_selectedPackageDays] ?? 50;
    final rawDealPercent = int.tryParse(_dealPercentController.text.trim());
    final dealPercent = rawDealPercent == null || rawDealPercent <= 0
        ? null
        : rawDealPercent.clamp(1, 90);
    final promotionType = dealPercent == null ? 'promote' : 'deal';

    final orderRef =
        await FirebaseFirestore.instance.collection('promotion_orders').add({
      'sellerId': sellerId,
      'productId': productId,
      'promotionType': promotionType,
      'packageDays': _selectedPackageDays,
      'amountEgp': amountEgp,
      'requestedDealPercent': dealPercent,
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'startsAt': null,
      'endsAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('sponsored_campaigns').add({
      'sellerId': sellerId,
      'productId': productId,
      'promotionOrderId': orderRef.id,
      'promotionType': promotionType,
      'packageDays': _selectedPackageDays,
      'amountEgp': amountEgp,
      'requestedDealPercent': dealPercent,
      'targeting': {'placement': 'home_search', 'language': 'all'},
      'status': 'pending_payment',
      'paymentStatus': 'pending',
      'spend': 0,
      'impressions': 0,
      'clicks': 0,
      'conversions': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment request created: $_selectedPackageDays day(s), EGP $amountEgp.',
          ),
        ),
      );
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
