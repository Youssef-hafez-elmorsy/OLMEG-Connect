import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminActionService {
  final FirebaseFunctions functions;

  AdminActionService({FirebaseFunctions? functions})
      : functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> runCommand(
    String command, {
    required String targetId,
    required String reason,
    Map<String, Object?> data = const {},
  }) async {
    final callable = functions.httpsCallable(command);
    final result = await callable.call<Map<String, dynamic>>({
      ...data,
      'targetId': targetId,
      'reason': reason.trim(),
    });
    return result.data;
  }

  Future<Map<String, dynamic>> updateWithAudit({
    required DocumentReference<Map<String, dynamic>> targetRef,
    required Map<String, Object?> data,
    required String action,
    required String targetType,
    required String reason,
    Map<String, Object?> metadata = const {},
  }) {
    final command = commandForAction(action);
    final payload = {
      ...data,
      ...metadata,
      'action': action,
      'targetPath': targetRef.path,
      'targetType': targetType,
    };
    return runCommand(
      command,
      targetId: targetRef.id,
      reason: reason,
      data: payload,
    );
  }

  Future<Map<String, dynamic>> deleteWithAudit({
    required DocumentReference<Map<String, dynamic>> targetRef,
    required String action,
    required String targetType,
    required String reason,
    Map<String, Object?> metadata = const {},
  }) {
    return runCommand(
      commandForAction(action),
      targetId: targetRef.id,
      reason: reason,
      data: {
        ...metadata,
        'targetPath': targetRef.path,
        'targetType': targetType,
      },
    );
  }

  Future<int> createNotificationCampaign({
    required String title,
    required String body,
    required String audience,
    required String reason,
  }) async {
    final result = await functions
        .httpsCallable('adminCreateNotificationCampaign')
        .call<Map<String, dynamic>>({
      'title': title,
      'body': body,
      'audience': audience,
      'reason': reason.trim(),
      'limit': adminNotificationFanoutLimit,
    });
    return (result.data['sentCount'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, dynamic>> assignStaffRole({
    required String uid,
    required String role,
    required String reason,
  }) {
    return runCommand(
      'adminAssignStaffRole',
      targetId: uid,
      reason: reason,
      data: {'role': role},
    );
  }

  Future<Map<String, dynamic>> disableStaff({
    required String uid,
    required String reason,
  }) {
    return runCommand(
      'adminDisableStaff',
      targetId: uid,
      reason: reason,
    );
  }

  Future<Map<String, dynamic>> refreshAdminSummary({required String reason}) {
    return runCommand(
      'adminRefreshAdminSummary',
      targetId: 'command_center',
      reason: reason,
    );
  }
}

String commandForAction(String action) {
  return switch (action) {
    'user_banned' => 'adminBlockUser',
    'user_unblocked' => 'adminUnblockUser',
    'user_posting_restriction_changed' => 'adminRestrictUserPosting',
    'user_chat_mute_changed' => 'adminMuteUserChat',
    'user_soft_deleted' => 'adminSoftDeleteUser',
    'merchant_verification_approved' => 'adminApproveMerchant',
    'merchant_verification_rejected' => 'adminRejectMerchant',
    'merchant_verification_suspended' => 'adminSuspendMerchant',
    'merchant_user_status_approved' => 'adminApproveMerchant',
    'merchant_user_status_rejected' => 'adminRejectMerchant',
    'merchant_user_status_suspended' => 'adminSuspendMerchant',
    'product_moderation_approved' => 'adminApproveProduct',
    'product_moderation_rejected' => 'adminRejectProduct',
    'product_moderation_hidden' => 'adminHideProduct',
    'product_moderation_escalated' => 'adminEscalateProduct',
    'report_resolved' => 'adminResolveReport',
    'report_dismissed' => 'adminDismissReport',
    'report_escalated' => 'adminEscalateReport',
    'notification_cancelled' => 'adminCancelNotificationCampaign',
    'notification_deleted' => 'adminDeleteNotificationCampaign',
    'users_note_added' => 'adminUpdateOperationalRecord',
    'merchant_verifications_note_added' => 'adminUpdateOperationalRecord',
    'orders_note_added' => 'adminUpdateOperationalRecord',
    'reports_note_added' => 'adminUpdateOperationalRecord',
    'products_note_added' => 'adminUpdateOperationalRecord',
    'category_visible' => 'adminUpdateOperationalRecord',
    'category_hidden' => 'adminUpdateOperationalRecord',
    'review_moderation_approved' => 'adminUpdateOperationalRecord',
    'review_moderation_hidden' => 'adminUpdateOperationalRecord',
    'review_moderation_escalated' => 'adminUpdateOperationalRecord',
    'order_flagged' => 'adminUpdateOperationalRecord',
    'order_reviewed' => 'adminUpdateOperationalRecord',
    'refund_resolved' => 'adminUpdateOperationalRecord',
    'refund_escalated' => 'adminUpdateOperationalRecord',
    'payment_mark_reviewed' => 'adminUpdateOperationalRecord',
    'payment_escalated' => 'adminUpdateOperationalRecord',
    'paymob_reconciliation_reviewed' => 'adminUpdateOperationalRecord',
    'paymob_reconciliation_escalated' => 'adminUpdateOperationalRecord',
    'support_ticket_assigned' => 'adminUpdateOperationalRecord',
    'support_ticket_resolved' => 'adminUpdateOperationalRecord',
    'support_ticket_escalated' => 'adminUpdateOperationalRecord',
    'promotion_activated' => 'adminUpdateOperationalRecord',
    'promotion_paused' => 'adminUpdateOperationalRecord',
    'risk_case_opened' => 'adminUpdateOperationalRecord',
    'risk_case_escalated' => 'adminUpdateOperationalRecord',
    'risk_case_resolved' => 'adminUpdateOperationalRecord',
    'product_featured' => 'adminUpdateOperationalRecord',
    'product_hidden' => 'adminUpdateOperationalRecord',
    _ => throw UnsupportedError('No trusted admin command for $action'),
  };
}

const adminNotificationFanoutLimit = 25;
