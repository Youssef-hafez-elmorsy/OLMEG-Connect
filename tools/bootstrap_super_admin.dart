// One-time super_admin bootstrap documentation stub.
//
// This file intentionally does not contain client credentials. Run the real
// bootstrap from a trusted Firebase Admin SDK environment only.
//
// Required behavior:
// - Check whether a super_admin already exists.
// - If none exists, set Custom Claims:
//   { role: 'super_admin', admin: true, roles: ['super_admin'] }
// - Write admin_roles/{uid} metadata.
// - Write an audit log with action bootstrap_super_admin.
// - Block repeated bootstrap attempts.

void main(List<String> args) {
  throw UnsupportedError(
    'Use Firebase Admin SDK in a trusted backend environment for one-time '
    'super_admin bootstrap. See docs/admin-bootstrap.md.',
  );
}
