// Trusted role manager contract for Admin Web Console.
//
// Only super_admin may assign, revoke, disable, or escalate admin roles.
// The implementation must run with Firebase Admin SDK credentials, never in
// the public Flutter client.
//
// Every successful role change must:
// - update Firebase Custom Claims
// - update admin_roles/{uid} metadata
// - write an immutable audit log with actor, target, old role, new role,
//   reason, and timestamp
//
// Every denied or failed role change must avoid partial access grants.

const allowedRoles = ['moderator', 'support', 'admin', 'super_admin'];

bool canAssignRole(String actorRole) => actorRole == 'super_admin';

void main(List<String> args) {
  throw UnsupportedError(
    'Run role assignment from a trusted Firebase Admin SDK process only.',
  );
}
