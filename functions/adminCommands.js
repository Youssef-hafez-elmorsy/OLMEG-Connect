const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const ROLES = {
  MODERATOR: 'moderator',
  SUPPORT: 'support',
  ADMIN: 'admin',
  SUPER_ADMIN: 'super_admin',
};

const COMMANDS = {
  adminBlockUser: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'users',
    targetType: 'users',
    action: 'user_banned',
    fields: () => ({
      accountStatus: 'banned',
      blockedAt: FieldValue.serverTimestamp(),
    }),
  },
  adminUnblockUser: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'users',
    targetType: 'users',
    action: 'user_unblocked',
    fields: () => ({
      accountStatus: 'active',
      blockedAt: FieldValue.delete(),
    }),
  },
  adminRestrictUserPosting: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'users',
    targetType: 'users',
    action: 'user_posting_restriction_changed',
    fields: (data) => ({ postingRestricted: data.enabled === true }),
  },
  adminMuteUserChat: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'users',
    targetType: 'users',
    action: 'user_chat_mute_changed',
    fields: (data) => ({ chatMuted: data.enabled === true }),
  },
  adminSoftDeleteUser: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'users',
    targetType: 'users',
    action: 'user_soft_deleted',
    fields: () => ({
      accountStatus: 'deleted',
      deletedAt: FieldValue.serverTimestamp(),
    }),
  },
  adminApproveMerchant: merchantCommand('approved'),
  adminRejectMerchant: merchantCommand('rejected'),
  adminSuspendMerchant: merchantCommand('suspended'),
  adminApproveProduct: productCommand('approved'),
  adminRejectProduct: productCommand('rejected'),
  adminHideProduct: productCommand('hidden'),
  adminEscalateProduct: productCommand('escalated'),
  adminResolveReport: reportCommand('resolved'),
  adminDismissReport: reportCommand('dismissed'),
  adminEscalateReport: reportCommand('escalated'),
  adminCancelNotificationCampaign: {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'admin_notifications',
    targetType: 'admin_notifications',
    action: 'notification_cancelled',
    fields: () => ({ status: 'cancelled' }),
  },
};

const OPERATIONAL_COLLECTIONS = {
  categories: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  reviews: [ROLES.MODERATOR, ROLES.ADMIN, ROLES.SUPER_ADMIN],
  orders: [ROLES.SUPPORT, ROLES.ADMIN, ROLES.SUPER_ADMIN],
  refunds: [ROLES.SUPPORT, ROLES.ADMIN, ROLES.SUPER_ADMIN],
  payments: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  payment_reconciliations: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  support_tickets: [ROLES.SUPPORT, ROLES.ADMIN, ROLES.SUPER_ADMIN],
  promotions: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  risk_cases: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  products: [ROLES.MODERATOR, ROLES.ADMIN, ROLES.SUPER_ADMIN],
  users: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  merchant_verifications: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
  reports: [ROLES.MODERATOR, ROLES.SUPPORT, ROLES.ADMIN, ROLES.SUPER_ADMIN],
};

const OPERATIONAL_ACTIONS = new Set([
  'users_note_added',
  'merchant_verifications_note_added',
  'orders_note_added',
  'reports_note_added',
  'products_note_added',
  'category_visible',
  'category_hidden',
  'review_moderation_approved',
  'review_moderation_hidden',
  'review_moderation_escalated',
  'order_flagged',
  'order_reviewed',
  'refund_resolved',
  'refund_escalated',
  'payment_mark_reviewed',
  'payment_escalated',
  'paymob_reconciliation_reviewed',
  'paymob_reconciliation_escalated',
  'support_ticket_assigned',
  'support_ticket_resolved',
  'support_ticket_escalated',
  'promotion_activated',
  'promotion_paused',
  'risk_case_opened',
  'risk_case_escalated',
  'risk_case_resolved',
  'product_featured',
  'product_hidden',
]);

function merchantCommand(status) {
  return {
    roles: [ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'merchant_verifications',
    targetType: 'merchant_verifications',
    action: `merchant_verification_${status}`,
    fields: () => ({
      status,
      reviewedAt: FieldValue.serverTimestamp(),
    }),
    after: async ({ targetId, batch, reason, actor }) => {
      const userRef = db.collection('users').doc(targetId);
      batch.set(userRef, {
        accountType: 'merchant',
        merchantVerificationStatus: status,
        isApprovedMerchant: status === 'approved',
        updatedAt: FieldValue.serverTimestamp(),
        adminReviewedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      batch.set(db.collection('audit_logs').doc(), auditData({
        actor,
        action: `merchant_user_status_${status}`,
        targetType: 'users',
        targetId,
        metadata: { reason },
      }));
    },
  };
}

function productCommand(status) {
  return {
    roles: [ROLES.MODERATOR, ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'product_submissions',
    targetType: 'product_submissions',
    action: `product_moderation_${status}`,
    fields: () => ({
      moderationStatus: status,
      moderationDecision: `admin_${status}`,
    }),
  };
}

function reportCommand(status) {
  return {
    roles: [ROLES.MODERATOR, ROLES.SUPPORT, ROLES.ADMIN, ROLES.SUPER_ADMIN],
    collection: 'reports',
    targetType: 'reports',
    action: `report_${status}`,
    fields: () => ({ status }),
  };
}

function roleFromContext(context) {
  const token = context.auth && context.auth.token;
  if (!token) return null;
  if (token.role) return token.role;
  if (Array.isArray(token.roles) && token.roles.length > 0) return token.roles[0];
  if (token.admin === true) return ROLES.ADMIN;
  return null;
}

function assertAllowed(context, allowedRoles) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required.');
  }
  const role = roleFromContext(context);
  if (!role || !allowedRoles.includes(role)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'This admin role cannot run this command.',
    );
  }
  return { uid: context.auth.uid, role };
}

function requiredString(value, name) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `${name} is required.`,
    );
  }
  return value.trim();
}

function auditData({ actor, action, targetType, targetId, metadata }) {
  return {
    actorUid: actor.uid,
    actorRole: actor.role,
    action,
    targetType,
    targetId,
    metadata: metadata || {},
    schemaVersion: 1,
    immutable: true,
    createdAt: FieldValue.serverTimestamp(),
  };
}

async function runDocumentCommand(commandName, data, context) {
  const command = COMMANDS[commandName];
  if (!command) {
    throw new functions.https.HttpsError('not-found', 'Unknown admin command.');
  }

  const actor = assertAllowed(context, command.roles);
  const targetId = requiredString(data.targetId, 'targetId');
  const reason = requiredString(data.reason, 'reason');
  const targetRef = db.collection(command.collection).doc(targetId);
  const target = await targetRef.get();

  if (!target.exists) {
    throw new functions.https.HttpsError('not-found', 'Target record not found.');
  }

  const batch = db.batch();
  batch.set(targetRef, {
    ...command.fields(data),
    updatedAt: FieldValue.serverTimestamp(),
    adminReviewedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action: command.action,
    targetType: command.targetType,
    targetId,
    metadata: {
      reason,
      command: commandName,
    },
  }));

  if (command.after) {
    await command.after({ targetId, batch, reason, actor, data });
  }

  await batch.commit();
  return { ok: true, targetId, action: command.action };
}

async function runDeleteNotificationCampaign(data, context) {
  const actor = assertAllowed(context, [ROLES.ADMIN, ROLES.SUPER_ADMIN]);
  const targetId = requiredString(data.targetId, 'targetId');
  const reason = requiredString(data.reason, 'reason');
  const targetRef = db.collection('admin_notifications').doc(targetId);
  const target = await targetRef.get();

  if (!target.exists) {
    throw new functions.https.HttpsError('not-found', 'Notification not found.');
  }

  const batch = db.batch();
  batch.delete(targetRef);
  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action: 'notification_deleted',
    targetType: 'admin_notifications',
    targetId,
    metadata: { reason },
  }));
  await batch.commit();
  return { ok: true, targetId, action: 'notification_deleted' };
}

async function runCreateNotificationCampaign(data, context) {
  const actor = assertAllowed(context, [ROLES.ADMIN, ROLES.SUPER_ADMIN]);
  const title = requiredString(data.title, 'title');
  const body = requiredString(data.body, 'body');
  const reason = requiredString(data.reason, 'reason');
  const audience = typeof data.audience === 'string' ? data.audience : 'all';
  const limit = Math.min(Math.max(Number(data.limit || 25), 1), 100);
  let query = db.collection('users');

  if (audience === 'buyers') {
    query = query.where('accountType', '==', 'buyer');
  } else if (audience === 'merchants') {
    query = query.where('accountType', '==', 'merchant');
  }

  const recipients = await query.limit(limit).get();
  const campaignRef = db.collection('admin_notifications').doc();
  const batch = db.batch();

  batch.set(campaignRef, {
    title,
    body,
    audience,
    target: 'admin_command',
    source: 'admin_command',
    status: recipients.empty ? 'no_recipients' : 'sent',
    type: 'manual',
    createdBy: actor.uid,
    sentCount: recipients.size,
    fanoutLimit: limit,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  recipients.docs.forEach((userDoc) => {
    batch.set(db.collection('notifications').doc(), {
      userId: userDoc.id,
      title,
      message: body,
      body,
      type: 'admin_campaign',
      campaignId: campaignRef.id,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action: 'notification_campaign',
    targetType: 'admin_notifications',
    targetId: campaignRef.id,
    metadata: {
      reason,
      audience,
      sentCount: recipients.size,
      fanoutLimit: limit,
    },
  }));

  await batch.commit();
  return { ok: true, targetId: campaignRef.id, sentCount: recipients.size };
}

function targetPathParts(data) {
  const targetPath = requiredString(data.targetPath, 'targetPath');
  const parts = targetPath.split('/').filter(Boolean);
  if (parts.length !== 2) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Only top-level admin operational records are supported.',
    );
  }
  return { collection: parts[0], targetId: parts[1] };
}

function sanitizedOperationalFields(fields) {
  if (!fields || typeof fields !== 'object' || Array.isArray(fields)) {
    throw new functions.https.HttpsError('invalid-argument', 'fields are required.');
  }
  const blocked = new Set([
    'role',
    'roles',
    'admin',
    'adminStaff',
    'adminDisabled',
    'customClaims',
    'createdAt',
    'createdBy',
    'ownerUid',
    'sellerId',
    'buyerId',
    'userId',
  ]);
  const clean = {};
  Object.entries(fields).forEach(([key, value]) => {
    if (blocked.has(key)) {
      throw new functions.https.HttpsError(
        'permission-denied',
        `Field ${key} cannot be changed by this generic command.`,
      );
    }
    clean[key] = value;
  });
  return clean;
}

async function runUpdateOperationalRecord(data, context) {
  const { collection, targetId } = targetPathParts(data);
  const allowedRoles = OPERATIONAL_COLLECTIONS[collection];
  if (!allowedRoles) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'This collection is not supported by the operational command layer.',
    );
  }
  const actor = assertAllowed(context, allowedRoles);
  const action = requiredString(data.action, 'action');
  const reason = requiredString(data.reason, 'reason');
  if (!OPERATIONAL_ACTIONS.has(action)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'This operational action is not allowlisted.',
    );
  }

  const fields = sanitizedOperationalFields(data.fields || data);
  delete fields.targetPath;
  delete fields.targetType;
  delete fields.reason;
  delete fields.action;
  delete fields.metadata;

  const targetRef = db.collection(collection).doc(targetId);
  const target = await targetRef.get();
  if (!target.exists) {
    throw new functions.https.HttpsError('not-found', 'Target record not found.');
  }

  const batch = db.batch();
  batch.set(targetRef, {
    ...fields,
    lastAdminAction: action,
    updatedAt: FieldValue.serverTimestamp(),
    adminReviewedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action,
    targetType: collection,
    targetId,
    metadata: {
      reason,
      command: 'adminUpdateOperationalRecord',
      fields: Object.keys(fields),
      ...(data.metadata || {}),
    },
  }));
  await batch.commit();
  return { ok: true, targetId, action };
}

async function runRefreshAdminSummary(data, context) {
  const actor = assertAllowed(context, [ROLES.ADMIN, ROLES.SUPER_ADMIN]);
  const sources = [
    'users',
    'merchant_verifications',
    'products',
    'orders',
    'reports',
    'support_tickets',
    'payments',
    'refunds',
    'risk_cases',
  ];
  const counts = {};

  for (const source of sources) {
    const snapshot = await db.collection(source).limit(25).get();
    counts[source] = {
      cappedCount: snapshot.size,
      cappedAt: 25,
    };
  }

  await db.collection('admin_summaries').doc('command_center').set({
    counts,
    refreshedBy: actor.uid,
    refreshedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('audit_logs').doc().set(auditData({
    actor,
    action: 'admin_summary_refreshed',
    targetType: 'admin_summaries',
    targetId: 'command_center',
    metadata: { sources },
  }));

  return { ok: true, targetId: 'command_center', counts };
}

function validateRole(role) {
  if (!Object.values(ROLES).includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'role must be moderator, support, admin, or super_admin.',
    );
  }
  return role;
}

function claimsForActiveRole(previousClaims, role) {
  return {
    ...previousClaims,
    admin: role === ROLES.ADMIN || role === ROLES.SUPER_ADMIN,
    adminStaff: true,
    adminDisabled: false,
    role,
    roles: [role],
  };
}

function claimsForDisabledStaff(previousClaims) {
  const nextClaims = {
    ...previousClaims,
    admin: false,
    adminStaff: false,
    adminDisabled: true,
  };
  delete nextClaims.role;
  delete nextClaims.roles;
  return nextClaims;
}

async function assertLastSuperAdminSafe(targetId, previousRole) {
  if (previousRole !== ROLES.SUPER_ADMIN) return;

  const activeSuperAdmins = await db.collection('admin_roles')
    .where('role', '==', ROLES.SUPER_ADMIN)
    .where('status', '==', 'active')
    .limit(25)
    .get();
  const activeSuperAdminIds = activeSuperAdmins.docs.map((doc) => doc.id);

  if (activeSuperAdminIds.length <= 1 && activeSuperAdminIds.includes(targetId)) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Cannot remove or disable the last active super_admin.',
    );
  }
}

async function runAssignStaffRole(data, context) {
  const actor = assertAllowed(context, [ROLES.SUPER_ADMIN]);
  const targetId = requiredString(data.targetId, 'targetId');
  const role = validateRole(requiredString(data.role, 'role'));
  const reason = requiredString(data.reason, 'reason');
  const authUser = await admin.auth().getUser(targetId);
  const roleRef = db.collection('admin_roles').doc(targetId);
  const roleDoc = await roleRef.get();
  const previousClaims = authUser.customClaims || {};
  const previousRole = roleDoc.data()?.role || previousClaims.role || null;

  if (previousRole === ROLES.SUPER_ADMIN && role !== ROLES.SUPER_ADMIN) {
    await assertLastSuperAdminSafe(targetId, previousRole);
  }

  await admin.auth().setCustomUserClaims(
    targetId,
    claimsForActiveRole(previousClaims, role),
  );

  const batch = db.batch();
  batch.set(roleRef, {
    uid: targetId,
    email: authUser.email || null,
    role,
    status: 'active',
    disabled: false,
    assignedBy: actor.uid,
    claimsUpdatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action: previousRole ? 'admin_role_changed' : 'admin_role_assigned',
    targetType: 'admin_roles',
    targetId,
    metadata: {
      email: authUser.email || null,
      previousRole,
      newRole: role,
      reason,
      command: 'adminAssignStaffRole',
    },
  }));
  await batch.commit();

  return { ok: true, targetId, action: previousRole ? 'admin_role_changed' : 'admin_role_assigned' };
}

async function runDisableStaff(data, context) {
  const actor = assertAllowed(context, [ROLES.SUPER_ADMIN]);
  const targetId = requiredString(data.targetId, 'targetId');
  const reason = requiredString(data.reason, 'reason');

  if (actor.uid === targetId) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'A super_admin cannot disable their own staff account.',
    );
  }

  const authUser = await admin.auth().getUser(targetId);
  const roleRef = db.collection('admin_roles').doc(targetId);
  const roleDoc = await roleRef.get();
  const previousClaims = authUser.customClaims || {};
  const previousRole = roleDoc.data()?.role || previousClaims.role || null;

  await assertLastSuperAdminSafe(targetId, previousRole);

  await admin.auth().setCustomUserClaims(
    targetId,
    claimsForDisabledStaff(previousClaims),
  );
  await admin.auth().revokeRefreshTokens(targetId);

  const batch = db.batch();
  batch.set(roleRef, {
    uid: targetId,
    email: authUser.email || null,
    status: 'disabled',
    disabled: true,
    disabledBy: actor.uid,
    disabledAt: FieldValue.serverTimestamp(),
    claimsUpdatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(db.collection('audit_logs').doc(), auditData({
    actor,
    action: 'admin_staff_disabled',
    targetType: 'admin_roles',
    targetId,
    metadata: {
      email: authUser.email || null,
      previousRole,
      reason,
      command: 'adminDisableStaff',
    },
  }));
  await batch.commit();

  return { ok: true, targetId, action: 'admin_staff_disabled' };
}

function exportDocumentCommand(name) {
  return functions.https.onCall((data, context) => runDocumentCommand(name, data || {}, context));
}

module.exports = {
  adminBlockUser: exportDocumentCommand('adminBlockUser'),
  adminUnblockUser: exportDocumentCommand('adminUnblockUser'),
  adminRestrictUserPosting: exportDocumentCommand('adminRestrictUserPosting'),
  adminMuteUserChat: exportDocumentCommand('adminMuteUserChat'),
  adminSoftDeleteUser: exportDocumentCommand('adminSoftDeleteUser'),
  adminApproveMerchant: exportDocumentCommand('adminApproveMerchant'),
  adminRejectMerchant: exportDocumentCommand('adminRejectMerchant'),
  adminSuspendMerchant: exportDocumentCommand('adminSuspendMerchant'),
  adminApproveProduct: exportDocumentCommand('adminApproveProduct'),
  adminRejectProduct: exportDocumentCommand('adminRejectProduct'),
  adminHideProduct: exportDocumentCommand('adminHideProduct'),
  adminEscalateProduct: exportDocumentCommand('adminEscalateProduct'),
  adminResolveReport: exportDocumentCommand('adminResolveReport'),
  adminDismissReport: exportDocumentCommand('adminDismissReport'),
  adminEscalateReport: exportDocumentCommand('adminEscalateReport'),
  adminCancelNotificationCampaign: exportDocumentCommand('adminCancelNotificationCampaign'),
  adminDeleteNotificationCampaign: functions.https.onCall(runDeleteNotificationCampaign),
  adminCreateNotificationCampaign: functions.https.onCall(runCreateNotificationCampaign),
  adminUpdateOperationalRecord: functions.https.onCall(runUpdateOperationalRecord),
  adminRefreshAdminSummary: functions.https.onCall(runRefreshAdminSummary),
  adminAssignStaffRole: functions.https.onCall(runAssignStaffRole),
  adminDisableStaff: functions.https.onCall(runDisableStaff),
};
