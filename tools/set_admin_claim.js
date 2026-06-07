#!/usr/bin/env node

const admin = require('../functions/node_modules/firebase-admin');

const allowedRoles = new Set(['moderator', 'support', 'admin', 'super_admin']);

function arg(name) {
  const prefix = `--${name}=`;
  const found = process.argv.find((item) => item.startsWith(prefix));
  return found ? found.slice(prefix.length).trim() : undefined;
}

async function main() {
  const email = arg('email');
  const uidArg = arg('uid');
  const role = arg('role') || 'admin';
  const actor = arg('actor') || 'local-bootstrap';
  const reason = arg('reason') || 'Admin role assignment';
  const projectId = arg('project') || 'olmeg-connect';

  if (!email && !uidArg) {
    throw new Error('Pass --email=user@example.com or --uid=firebaseAuthUid');
  }
  if (!allowedRoles.has(role)) {
    throw new Error(
      `Invalid --role=${role}. Use one of: ${Array.from(allowedRoles).join(', ')}`,
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
  }

  const auth = admin.auth();
  const firestore = admin.firestore();
  const user = uidArg ? await auth.getUser(uidArg) : await auth.getUserByEmail(email);
  const previousClaims = user.customClaims || {};
  const previousRole = previousClaims.role || null;
  const hasFullAdminRole = role === 'admin' || role === 'super_admin';
  const claims = {
    ...previousClaims,
    admin: hasFullAdminRole,
    adminStaff: true,
    role,
    roles: [role],
  };

  await auth.setCustomUserClaims(user.uid, claims);

  await firestore.collection('admin_roles').doc(user.uid).set(
    {
      uid: user.uid,
      email: user.email || email || null,
      role,
      status: 'active',
      claimsUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await firestore.collection('audit_logs').add({
    actorUid: actor,
    actorRole: 'super_admin',
    action: previousRole ? 'admin_role_changed' : 'admin_role_assigned',
    targetType: 'admin_roles',
    targetId: user.uid,
    metadata: {
      email: user.email || email || null,
      previousRole,
      newRole: role,
      reason,
    },
    schemaVersion: 1,
    immutable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Updated ${user.email || user.uid} as ${role}.`);
  console.log('Ask the user to sign out and sign in again to refresh token claims.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
