# Implementation Plan: Real-Time Chat Security UI

**Branch**: `014-realtime-chat-security-ui` | **Date**: 2026-06-07 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/014-realtime-chat-security-ui/spec.md`

## Summary

Improve marketplace chat so buyer/seller messages feel real-time, conversation writes are participant-safe, unsafe content can be reported and reviewed, and the chat list/detail UI becomes clearer across active, empty, failed, offline, and Arabic/RTL states.

This plan is deliberately phased. Each implementation phase must pause for user approval before code changes begin. The first implementation batch must be small enough to validate the chat data/security direction before broader UI polish.

## Technical Context

**Language/Version**: Dart SDK `>=3.0.0 <4.0.0`, Flutter 3.41.x, Node.js Cloud Functions  
**Primary Dependencies**: Flutter, Riverpod, GoRouter, Firebase Auth/Firestore/Storage/Functions/Hosting  
**Storage**: Cloud Firestore, Firebase Auth identity/custom claims, audit/report collections, optional Firebase Storage for future attachments  
**Testing**: root `flutter analyze`, root `flutter test`, targeted chat widget/provider tests, static Firestore Rules tests, emulator-backed security tests when available, public web build, APK build before release  
**Target Platform**: Flutter public app on mobile/web; standalone admin web for operations review only  
**Project Type**: Multi-app Flutter marketplace with Firebase backend  
**Performance Goals**: 95% of online messages visible to the other participant within 2 seconds; active conversations remain usable with 500 messages; chat list remains usable with 80 conversations  
**Constraints**: Public app must not expose admin affordances; participant identity must not be spoofable; protected chat metadata cannot be edited through normal message sends; all sensitive staff review/actions must remain role-scoped and auditable  
**Scale/Scope**: Product-context buyer/seller text conversations, reports, moderation evidence, unread/delivery states, polished UI states, Arabic/RTL regressions. Attachments and voice notes are out of scope for the first implementation unless the user expands scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution file is still a template and does not define enforceable project-specific rules. This plan therefore applies the active project guardrails from the existing UI/admin/security plan:

- Public buyer/seller chat remains in the public app and must not reintroduce public admin routes.
- Admin review surfaces, if added, remain in `apps/admin_web` and are role-scoped.
- Sensitive chat review, report, and moderation actions must be enforced by backend/rules, not UI hiding.
- Firestore reads and writes must be security-rule validated.
- Implementation must proceed by approval gates: no phase starts until the user approves the phase direction.

**Initial Gate Status**: Pass.

## Project Structure

### Documentation (this feature)

```text
specs/014-realtime-chat-security-ui/
|-- spec.md
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- chat-ui-security-contract.md
`-- checklists/
    `-- requirements.md
```

### Source Code (repository root)

```text
lib/features/chat/
|-- data/
|   |-- datasources/
|   `-- models/
|-- domain/
|   `-- entities/
`-- presentation/
    |-- providers/
    `-- screens/

lib/core/
|-- localization/
|-- router/
`-- widgets/

apps/admin_web/
|-- lib/
|   |-- features/
|   `-- core/
`-- test/

functions/
|-- adminCommands.js
|-- aiServices.js
`-- index.js

test/
|-- features/
|   `-- chat/
|-- security/
`-- presentation_screenshots_test.dart

firestore.rules
storage.rules
```

**Structure Decision**: Use the existing public chat feature boundary for buyer/seller messaging, existing admin web boundary for operations review, and existing Firebase rules/functions locations for security enforcement. Avoid creating new top-level apps or moving chat into legacy `lib/features/admin`.

## Implementation Phases and Approval Gates

### Phase 0 - Confirm Scope and Design Direction

**Goal**: Confirm the product direction before any implementation.

**Planned decisions for user approval**:

- Text-only real-time messaging first; attachments/voice deferred.
- Message history moves toward per-message records rather than a growing array on the conversation.
- Public chat UI shows buyer/seller safety cues, not admin controls.
- Admin review sees only reported/safety-relevant evidence, not broad private chat browsing.

**Exit Gate**: User explicitly approves the phase direction.

### Phase 1 - Security and Data Model Foundation

**Goal**: Make the chat data and access model safe before UI expansion.

**Work scope after approval**:

- Define conversation, message, participant state, report, and review record behavior.
- Harden participant-only reads/writes.
- Prevent sender spoofing and protected metadata edits.
- Add security tests before broad UI changes.

**Validation gate**:

- Static and/or emulator-backed Firestore rules tests for participants, non-participants, unauthenticated users, staff roles, message writes, hide/mute/block/report flows.
- Root `flutter analyze` for changed public code.

**Exit Gate**: User reviews validation evidence and approves moving to UI polish.

### Phase 2 - Real-Time Messaging Experience

**Goal**: Make message sending and receiving feel immediate and reliable.

**Work scope after approval**:

- Conversation stream updates.
- Pending/delivered/failed send states.
- Chronological ordering and scroll behavior.
- Chat list latest-message and unread state.
- Draft preservation on failure.

**Validation gate**:

- Chat provider/data tests.
- Widget tests for open conversation send/receive states.
- Manual two-session smoke test instructions in quickstart.

**Exit Gate**: User reviews chat behavior and approves moderation/reporting work.

### Phase 3 - Reporting, Blocking, and Staff Review

**Goal**: Add safety workflows without exposing private chat broadly.

**Work scope after approval**:

- Participant report flow for message/conversation.
- Hide, mute, block, or equivalent per-user protection.
- Staff review evidence contract in admin web.
- Auditable moderation/review actions.

**Validation gate**:

- Security tests for report visibility and staff access.
- Admin route/action tests if admin surfaces are added.
- Public admin separation tests remain green.

**Exit Gate**: User reviews safety workflow and approves final UI polish.

### Phase 4 - UI Polish and Arabic/RTL Regression

**Goal**: Improve chat list and conversation presentation across all major states.

**Work scope after approval**:

- Premium marketplace chat list rows.
- Product context bar and safe transaction cues.
- Message grouping, timestamps, unread markers, empty/loading/error/offline states.
- Arabic/RTL layout checks.

**Validation gate**:

- Chat widget tests.
- Screenshot or presentation regression tests where practical.
- Root `flutter test`.

**Exit Gate**: User approves release validation.

### Phase 5 - Release Validation

**Goal**: Verify the full feature before deployment.

**Validation gate**:

- Root `flutter analyze`.
- Root `flutter test`.
- Public `flutter build web`.
- Release APK build if mobile release is intended.
- Firebase rules dry-run and targeted security tests.
- Admin `flutter analyze/test/build web` only if admin review surfaces changed.

**Exit Gate**: User approves deployment.

## Review Protocol

- Before each phase, present the intended changes and tradeoffs in plain language.
- Ask for the user's opinion on UI direction, security behavior, and scope boundaries.
- Do not start code work for a phase until the user approves that phase.
- Keep each implementation batch small enough to test and review.
- Update this plan's validation log after every implementation batch.

## Validation Log

| Date | Phase | Evidence | Status |
|---|---|---|---|
| 2026-06-07 | Spec creation | Created [spec.md](./spec.md) and [requirements checklist](./checklists/requirements.md); no clarification markers remain | Complete |
| 2026-06-07 | Planning | Created phased plan, research, data model, quickstart, and UI/security contract; updated active agent context | Pending user approval |

## Complexity Tracking

No constitution violations identified. Complexity is justified by the security risk of real-time private messaging and the current need to separate normal participant actions from staff review workflows.
