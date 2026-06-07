# Quickstart: Real-Time Chat Security UI

## Approval-First Workflow

Before implementation, review [plan.md](./plan.md) and confirm Phase 0 decisions:

1. Text-only real-time messaging first.
2. Move toward message-level records instead of growing message arrays.
3. Public chat has buyer/seller controls only.
4. Staff review is tied to reports/support/safety workflows.

No code phase should start until the user approves the phase.

## Local Validation Commands

Run public app checks from the repository root:

```powershell
flutter analyze
flutter test
flutter test test/features/qa/admin_separation_test.dart
flutter test test/security/admin_rules_test.dart test/security/storage_rules_test.dart
flutter build web
```

Run admin checks only if admin review surfaces change:

```powershell
cd apps/admin_web
flutter analyze
flutter test
flutter build web
```

Run Firebase/security checks when rules or functions change:

```powershell
firebase emulators:exec --only firestore,auth "flutter test test/security"
firebase deploy --only firestore:rules --dry-run
```

## Manual Smoke Tests

1. Sign in as buyer in one browser/session.
2. Sign in as seller in another browser/session.
3. Open the same product conversation in both sessions.
4. Send messages from each side.
5. Confirm messages appear without refresh and remain ordered.
6. Confirm chat list latest preview and unread state update.
7. Attempt to open the conversation as a third user and confirm denial.
8. Report a message and confirm the reporter receives confirmation.
9. Check Arabic/RTL layout for message alignment and actions.

## Release Gate

Release is blocked until:

- User approves all completed phases.
- Chat security tests pass.
- Chat UI state tests pass.
- Public app analyze/test/build pass.
- Admin tests/build pass if admin review surfaces changed.
- Firebase rules dry-run or equivalent validation passes if rules changed.
