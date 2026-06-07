import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/core/widgets/app_state_widgets.dart';
import 'package:olmeg_connect/features/admin/data/admin_audit_service.dart';
import 'package:olmeg_connect/features/auth/domain/entities/user_entity.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends ConsumerState<AdminUserManagementScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingState(label: 'Loading users');
                }
                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Users failed to load',
                    message: '${snapshot.error}',
                  );
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  final haystack = [
                    data['name'],
                    data['email'],
                    data['role'],
                    data['accountStatus'],
                  ].whereType<String>().join(' ').toLowerCase();
                  return _query.isEmpty || haystack.contains(_query);
                }).toList();

                if (docs.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No matching users',
                    message: 'Try another name, email, role, or status.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _UserCard(
                    doc: docs[index],
                    actor: ref.watch(authStateProvider).value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final UserEntity? actor;

  const _UserCard({required this.doc, required this.actor});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final name = data['name'] as String? ?? 'Unnamed user';
    final email = data['email'] as String? ?? doc.id;
    final role = data['role'] as String? ?? 'user';
    final accountStatus = data['accountStatus'] as String? ?? 'active';
    final sellerStatus = data['sellerStatus'] as String? ??
        data['merchantVerificationStatus'] as String? ??
        'none';
    final chatMuted = data['chatMuted'] == true;
    final postingRestricted = data['postingRestricted'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(email,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChip(label: role, icon: Icons.badge_outlined),
                _StatusChip(
                    label: accountStatus, icon: Icons.verified_user_outlined),
                _StatusChip(
                    label: 'Seller: $sellerStatus',
                    icon: Icons.storefront_outlined),
                if (chatMuted)
                  const _StatusChip(
                      label: 'Chat muted', icon: Icons.chat_bubble_outline),
                if (postingRestricted)
                  const _StatusChip(
                      label: 'Posting restricted', icon: Icons.block),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _update(context, {
                    'accountStatus':
                        accountStatus == 'banned' ? 'active' : 'banned',
                  }),
                  icon: Icon(
                      accountStatus == 'banned' ? Icons.restore : Icons.block),
                  label: Text(accountStatus == 'banned' ? 'Restore' : 'Ban'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _update(context, {
                    'sellerStatus':
                        sellerStatus == 'suspended' ? 'active' : 'suspended',
                    'merchantVerificationStatus':
                        sellerStatus == 'suspended' ? 'approved' : 'suspended',
                  }),
                  icon: const Icon(Icons.store_mall_directory_outlined),
                  label: Text(sellerStatus == 'suspended'
                      ? 'Restore seller'
                      : 'Suspend seller'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _update(context, {'chatMuted': !chatMuted}),
                  icon: const Icon(Icons.voice_over_off_outlined),
                  label: Text(chatMuted ? 'Unmute chat' : 'Mute chat'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _update(
                      context, {'postingRestricted': !postingRestricted}),
                  icon: const Icon(Icons.edit_off_outlined),
                  label: Text(
                      postingRestricted ? 'Allow posts' : 'Restrict posts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _update(
      BuildContext context, Map<String, dynamic> fields) async {
    await doc.reference.set({
      ...fields,
      'adminReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AdminAuditService.record(
      actor: actor,
      action: 'user_admin_action',
      targetType: 'user',
      targetId: doc.id,
      metadata: fields,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User action saved.')),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
