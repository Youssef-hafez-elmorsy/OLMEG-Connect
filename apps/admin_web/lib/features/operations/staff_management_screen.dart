import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/actions/admin_action_service.dart';
import '../../core/rbac/admin_roles.dart';
import '../../core/widgets/admin_tokens.dart';
import '../shared/admin_action_dialogs.dart';
import '../shared/admin_collection_table_page.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminCollectionTablePage(
      title: 'Staff & Roles',
      description:
          'Invite staff, assign roles, disable access, inspect role history, and protect the last super_admin.',
      icon: Icons.admin_panel_settings_outlined,
      collectionName: 'admin_roles',
      headerActions: [
        Builder(
          builder: (context) {
            return FilledButton.icon(
              onPressed: () => _assignRoleDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Assign role'),
            );
          },
        ),
      ],
      columns: [
        AdminTableColumn.field('Email', 'email'),
        AdminTableColumn.field('Role', 'role', status: true),
        AdminTableColumn.field('Status', 'status', status: true),
        AdminTableColumn.field('Updated', 'updatedAt'),
        AdminTableColumn.field('Claims Synced', 'claimsUpdatedAt'),
      ],
      rowActionsBuilder: _staffActions,
    );
  }
}

List<Widget> _staffActions(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  return [
    OutlinedButton.icon(
      onPressed: () => _assignRoleDialog(context, uid: doc.id),
      icon: const Icon(Icons.manage_accounts_outlined),
      label: const Text('Change role'),
    ),
    OutlinedButton.icon(
      onPressed: () => _disableStaff(context, doc.id),
      icon: const Icon(Icons.person_off_outlined),
      label: const Text('Disable'),
    ),
  ];
}

Future<void> _assignRoleDialog(BuildContext context, {String? uid}) async {
  final uidController = TextEditingController(text: uid ?? '');
  final reasonController = TextEditingController();
  var role = AdminRole.support.value;
  final formKey = GlobalKey<FormState>();

  final draft = await showDialog<_RoleDraft>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(AdminSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminRadius.xl),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(AdminSpacing.xl),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign staff role',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      TextFormField(
                        controller: uidController,
                        decoration: const InputDecoration(
                          labelText: 'Firebase Auth UID',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: [
                          for (final item in AdminRole.values)
                            DropdownMenuItem(
                              value: item.value,
                              child: Text(item.value),
                            ),
                        ],
                        onChanged: (value) {
                          setState(
                              () => role = value ?? AdminRole.support.value);
                        },
                      ),
                      const SizedBox(height: AdminSpacing.md),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Audit reason',
                          alignLabelWithHint: true,
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AdminSpacing.sm),
                          FilledButton.icon(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(
                                context,
                                _RoleDraft(
                                  uid: uidController.text.trim(),
                                  role: role,
                                  reason: reasonController.text.trim(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Assign'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (draft == null) return;
  try {
    await AdminActionService().assignStaffRole(
      uid: draft.uid,
      role: draft.role,
      reason: draft.reason,
    );
    if (!context.mounted) return;
    showAdminSnack(context, 'Staff role updated.');
  } catch (error) {
    if (!context.mounted) return;
    showAdminSnack(context, 'Role update failed: $error', isError: true);
  }
}

Future<void> _disableStaff(BuildContext context, String uid) async {
  final reason = await askAdminReason(
    context,
    title: 'Disable staff',
    actionLabel: 'Disable',
    message:
        'This revokes admin claims and refuses to disable the last super_admin.',
  );
  if (reason == null) return;
  try {
    await AdminActionService().disableStaff(uid: uid, reason: reason);
    if (!context.mounted) return;
    showAdminSnack(context, 'Staff account disabled.');
  } catch (error) {
    if (!context.mounted) return;
    showAdminSnack(context, 'Disable failed: $error', isError: true);
  }
}

String? _required(String? value) {
  return (value ?? '').trim().isEmpty ? 'Required' : null;
}

class _RoleDraft {
  final String uid;
  final String role;
  final String reason;

  const _RoleDraft({
    required this.uid,
    required this.role,
    required this.reason,
  });
}
