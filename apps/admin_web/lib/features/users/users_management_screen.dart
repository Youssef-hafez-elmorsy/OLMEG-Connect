import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class UsersManagementScreen extends StatelessWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Users Management',
      description: 'Capped user search, account actions, and role context.',
      icon: Icons.people_outline,
      collectionName: 'users',
      serverFilterOptions: const [
        AdminServerFilterOption(
          label: 'Active',
          icon: Icons.verified_user_outlined,
          filters: [
            AdminServerFilter.equals('accountStatus', 'active'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Blocked',
          icon: Icons.block,
          filters: [
            AdminServerFilter.equals('accountStatus', 'banned'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Merchants',
          icon: Icons.storefront_outlined,
          filters: [
            AdminServerFilter.equals('accountType', 'merchant'),
          ],
        ),
        AdminServerFilterOption(
          label: 'Deleted',
          icon: Icons.delete_outline,
          filters: [
            AdminServerFilter.equals('accountStatus', 'deleted'),
          ],
        ),
      ],
      columns: [
        AdminTableColumn.field('Email', 'email'),
        AdminTableColumn.field('Name', 'displayName'),
        AdminTableColumn.field('Status', 'accountStatus', status: true),
        AdminTableColumn.field('Account Type', 'accountType'),
        AdminTableColumn.field(
          'Merchant Status',
          'merchantVerificationStatus',
          status: true,
        ),
        AdminTableColumn.field('Created', 'createdAt'),
      ],
      rowActionsBuilder: _userActions,
    );
  }
}

List<Widget> _userActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final status = (data['accountStatus'] as String? ?? 'active').toLowerCase();
  final isBlocked = status == 'banned' || status == 'blocked';
  final service = AdminActionService();

  Future<void> updateUser({
    required String label,
    required String action,
    required Map<String, Object?> fields,
  }) async {
    final reason = await askAdminReason(
      context,
      title: label,
      actionLabel: label,
      message: 'This writes an immutable audit log for ${doc.id}.',
    );
    if (reason == null) return;
    try {
      await service.updateWithAudit(
        targetRef: doc.reference,
        data: fields,
        action: action,
        targetType: 'users',
        reason: reason,
        metadata: {'fieldNames': fields.keys.toList()},
      );
      if (!context.mounted) return;
      showAdminSnack(context, '$label saved.');
    } catch (error) {
      if (!context.mounted) return;
      showAdminSnack(context, 'Action failed: $error', isError: true);
    }
  }

  return [
    FilledButton.tonalIcon(
      onPressed: () => updateUser(
        label: isBlocked ? 'Unblock user' : 'Block user',
        action: isBlocked ? 'user_unblocked' : 'user_banned',
        fields: {
          'accountStatus': isBlocked ? 'active' : 'banned',
        },
      ),
      icon: Icon(isBlocked ? Icons.restore : Icons.block),
      label: Text(isBlocked ? 'Unblock' : 'Block'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateUser(
        label: data['postingRestricted'] == true
            ? 'Allow posts'
            : 'Restrict posts',
        action: 'user_posting_restriction_changed',
        fields: {'postingRestricted': data['postingRestricted'] != true},
      ),
      icon: const Icon(Icons.edit_off_outlined),
      label:
          Text(data['postingRestricted'] == true ? 'Allow posts' : 'No posts'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateUser(
        label: data['chatMuted'] == true ? 'Unmute chat' : 'Mute chat',
        action: 'user_chat_mute_changed',
        fields: {'chatMuted': data['chatMuted'] != true},
      ),
      icon: const Icon(Icons.voice_over_off_outlined),
      label: Text(data['chatMuted'] == true ? 'Unmute' : 'Mute'),
    ),
    OutlinedButton.icon(
      onPressed: () => updateUser(
        label: 'Soft delete user',
        action: 'user_soft_deleted',
        fields: {
          'accountStatus': 'deleted',
        },
      ),
      icon: const Icon(Icons.delete_outline),
      label: const Text('Soft delete'),
    ),
  ];
}
