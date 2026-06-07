# Quickstart: Enterprise Roadmap Spec Kit

Use this feature to drive roadmap execution without rereading the original chat.

## 1. Read the Roadmap Source

```powershell
Get-Content docs/master-enterprise-roadmap.md
Get-Content docs/master-enterprise-roadmap-tasks.md
```

## 2. Read the Spec Kit Feature

```powershell
Get-Content specs/003-enterprise-roadmap/spec.md
Get-Content specs/003-enterprise-roadmap/plan.md
Get-Content specs/003-enterprise-roadmap/tasks.md
```

## 3. Start With Phase 0 Only

Do not start Paymob, AI, fulfillment, or analytics work until Phase 0 and Phase 1 pass.

First validation commands:

```powershell
flutter analyze
flutter test test\features\qa\admin_separation_test.dart test\security\admin_commands_test.dart test\security\admin_rules_test.dart test\security\admin_role_assignment_test.dart test\security\admin_bootstrap_test.dart test\security\admin_v2_hardening_test.dart
Set-Location apps/admin_web
flutter analyze
flutter test
flutter build web
Set-Location ../..
```

## 4. Payment Scope

Only Paymob is in scope for production payment implementation.

Do not add PayPal, Stripe, Apple Pay, Google Pay, or multi-provider abstraction until a later approved Spec Kit feature.

## 5. Completion Rule

Before checking off any phase:

- Verify every task is complete.
- Attach evidence for the exit gate.
- Confirm no later phase started early.

