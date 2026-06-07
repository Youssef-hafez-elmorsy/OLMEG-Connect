import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminSensitiveAction {
  roleAssigned('admin_role_assigned'),
  roleChanged('admin_role_changed'),
  userBanned('user_banned'),
  productModerationDecision('product_moderation_decision'),
  merchantApprovalDecision('merchant_approval_decision'),
  notificationCampaign('notification_campaign');

  final String value;

  const AdminSensitiveAction(this.value);
}

class AdminAuditService {
  static const schemaVersion = 1;

  final FirebaseFirestore firestore;

  const AdminAuditService(this.firestore);

  Future<void> record({
    required String actorUid,
    required String actorRole,
    required String action,
    required String targetType,
    required String targetId,
    Map<String, Object?> metadata = const {},
  }) async {
    await firestore.collection('audit_logs').add({
      'actorUid': actorUid,
      'actorRole': actorRole,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'metadata': metadata,
      'schemaVersion': schemaVersion,
      'immutable': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordSensitiveAction({
    required String actorUid,
    required String actorRole,
    required AdminSensitiveAction action,
    required String targetType,
    required String targetId,
    required String reason,
    Map<String, Object?> metadata = const {},
  }) {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'Reason is required');
    }

    return record(
      actorUid: actorUid,
      actorRole: actorRole,
      action: action.value,
      targetType: targetType,
      targetId: targetId,
      metadata: {
        ...metadata,
        'reason': normalizedReason,
      },
    );
  }
}
