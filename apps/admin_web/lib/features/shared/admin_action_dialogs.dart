import 'package:flutter/material.dart';

import '../../core/widgets/admin_tokens.dart';

Future<String?> askAdminReason(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String? message,
  String initialReason = '',
}) async {
  final controller = TextEditingController(text: initialReason);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) {
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AdminColors.warningSoft,
                          borderRadius: BorderRadius.circular(AdminRadius.md),
                        ),
                        child: const Icon(
                          Icons.edit_note_outlined,
                          color: AdminColors.warning,
                        ),
                      ),
                      const SizedBox(width: AdminSpacing.md),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AdminSpacing.md),
                    Text(message, style: const TextStyle(height: 1.45)),
                  ],
                  const SizedBox(height: AdminSpacing.lg),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Audit reason',
                      hintText:
                          'Example: abusive behavior confirmed in report #...',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Reason is required for audit logs.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AdminSpacing.md),
                  const Text(
                    'This reason is written to the immutable audit trail.',
                    style: TextStyle(color: AdminColors.muted, fontSize: 12),
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
                          Navigator.pop(context, controller.text.trim());
                        },
                        icon: const Icon(Icons.verified_outlined),
                        label: Text(actionLabel),
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
}

void showAdminSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AdminSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      content: Text(message),
      backgroundColor: isError ? AdminColors.danger : AdminColors.ink,
    ),
  );
}
