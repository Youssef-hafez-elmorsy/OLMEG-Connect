# Research: Olmeg Connect Admin Web Console

## Decision: Use Separate Flutter Web Admin App

**Rationale**: A separate app gives a clean deployment boundary, removes admin code from public navigation, and allows desktop-first admin UX.

**Alternatives considered**: Keeping admin screens in the public app and hiding navigation. Rejected because hiding UI is not a security boundary and keeps admin routes bundled with buyer/seller flows.

## Decision: Use Firebase Custom Claims as Primary Authorization

**Rationale**: Custom Claims are part of the authenticated token and can be evaluated by Firestore Security Rules. They are safer than trusting client UI state or regular user-editable documents.

**Alternatives considered**: Firestore-only role documents. Rejected as the sole authority because role documents can drift from token state and must be protected carefully from client tampering.

## Decision: Support Four Roles

**Rationale**: moderator, support, admin, and super_admin match the requested operating model and reduce excessive permissions.

**Alternatives considered**: A single `isAdmin` flag. Rejected because it grants too much access to support/moderation staff.

## Decision: Separate Firebase Hosting Targets

**Rationale**: Separate targets allow independent deploy/rollback for public and admin apps while using the same Firebase project.

**Alternatives considered**: One hosting target with admin routes under the public app. Rejected because it couples public and admin releases and increases accidental exposure risk.

## Decision: Firestore Rules Tests Are Required

**Rationale**: The feature explicitly requires security enforcement beyond UI hiding. Rules tests or emulator checks are the evidence that direct Firestore access is blocked.

**Alternatives considered**: Widget tests only. Rejected because widget tests cannot prove backend access control.
