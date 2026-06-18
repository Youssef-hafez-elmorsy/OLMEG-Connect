# Tasks: Real-Time Chat Security UI

**Input**: Design documents from `/specs/014-realtime-chat-security-ui/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Tests**: Required by the feature specification for security, provider/data behavior, widget states, and release validation.
**Organization**: Tasks are grouped by user story so each story remains independently testable.

## Phase 1: Setup

**Purpose**: Confirm active feature context and reusable project boundaries.

- [X] T001 Verify active Spec Kit feature context in `.specify/feature.json`
- [X] T002 Verify public chat source boundaries in `lib/features/chat/`
- [X] T003 Verify Firebase security source boundaries in `firestore.rules` and `functions/index.js`

---

## Phase 2: Foundational

**Purpose**: Shared chat model, repository, and security primitives that block all user stories.

- [X] T004 [P] Add message-level chat model fields and helpers in `lib/features/chat/data/models/chat_model.dart`
- [X] T005 [P] Add participant/report state model fields and helpers in `lib/features/chat/data/models/chat_model.dart`
- [X] T006 Harden chat datasource validation and stream shape in `lib/features/chat/data/datasources/chat_remote_datasource.dart`
- [X] T007 Harden chat provider state and draft/error handling in `lib/features/chat/presentation/providers/chat_provider.dart`
- [X] T008 Add participant-only chat and report rule coverage in `firestore.rules`
- [X] T009 Add targeted chat security tests in `test/security/chat_rules_test.dart`

---

## Phase 3: User Story 1 - Real-Time Marketplace Messaging (Priority: P1) MVP

**Goal**: Buyers and sellers see new product-context messages without refresh and get clear send state.
**Independent Test**: Open one conversation in two sessions, send from either side, and verify ordered updates within the active conversation and chat list.

### Tests for User Story 1

- [X] T010 [P] [US1] Add chat datasource/provider behavior tests in `test/features/chat/chat_realtime_test.dart`
- [X] T011 [P] [US1] Add conversation widget state tests in `test/features/chat/chat_ui_contract_test.dart`

### Implementation for User Story 1

- [X] T012 [US1] Implement message subcollection streaming and latest preview updates in `lib/features/chat/data/datasources/chat_remote_datasource.dart`
- [X] T013 [US1] Implement pending, delivered, and failed send state handling in `lib/features/chat/presentation/providers/chat_provider.dart`
- [X] T014 [US1] Update conversation screen ordering, send box, failed draft preservation, and scroll behavior in `lib/features/chat/presentation/screens/chat_detail_screen.dart`
- [X] T015 [US1] Update chat list latest activity and unread presentation in `lib/features/chat/presentation/screens/chat_list_screen.dart`

---

## Phase 4: User Story 2 - Secure Participant-Only Conversations (Priority: P1)

**Goal**: Only participants and authorized staff can read or act on chat data, and participants cannot spoof sender or protected metadata.
**Independent Test**: Try reads/writes as unauthenticated user, buyer, seller, non-participant, and staff.

### Tests for User Story 2

- [X] T016 [P] [US2] Add participant access and spoofing cases in `test/security/chat_rules_test.dart`
- [X] T017 [P] [US2] Add public admin separation regression for chat in `test/features/chat/chat_ui_contract_test.dart`

### Implementation for User Story 2

- [X] T018 [US2] Enforce authenticated sender and protected metadata behavior in `lib/features/chat/data/datasources/chat_remote_datasource.dart`
- [X] T019 [US2] Enforce participant-only conversation and message access in `firestore.rules`
- [X] T020 [US2] Add hide, mute, and block participant state writes in `lib/features/chat/data/datasources/chat_remote_datasource.dart`
- [X] T021 [US2] Expose hide, mute, and block actions without admin affordances in `lib/features/chat/presentation/screens/chat_detail_screen.dart`

---

## Phase 5: User Story 3 - Safer Chat Moderation and Reporting (Priority: P2)

**Goal**: Participants can report unsafe chat content and staff review sees only report-tied evidence with auditability.
**Independent Test**: Submit a report as participant, verify confirmation, verify unauthorized report evidence denial, and verify role-scoped staff access.

### Tests for User Story 3

- [X] T022 [P] [US3] Add report creation/security tests in `test/security/chat_rules_test.dart`
- [X] T023 [P] [US3] Add report flow widget test in `test/features/chat/chat_ui_contract_test.dart`

### Implementation for User Story 3

- [X] T024 [US3] Implement report creation with evidence snapshot in `lib/features/chat/data/datasources/chat_remote_datasource.dart`
- [X] T025 [US3] Add report flow provider actions in `lib/features/chat/presentation/providers/chat_provider.dart`
- [X] T026 [US3] Add report message/conversation UI in `lib/features/chat/presentation/screens/chat_detail_screen.dart`
- [X] T027 [US3] Add role-scoped chat report review surface in `apps/admin_web/lib/features/reports/reports_screen.dart`
- [X] T028 [US3] Add staff report access rules in `firestore.rules`

---

## Phase 6: User Story 4 - Polished Chat Experience Across App States (Priority: P3)

**Goal**: Chat list and conversation screens are clear across active, empty, loading, error, offline, long-history, and Arabic/RTL states.
**Independent Test**: View list/detail in normal, empty, failed-send, hidden/muted/blocked, long conversation, and Arabic/RTL layouts.

### Tests for User Story 4

- [X] T029 [P] [US4] Add chat list UI state tests in `test/features/chat/chat_ui_contract_test.dart`
- [X] T030 [P] [US4] Add RTL chat layout regression coverage in `test/features/chat/chat_ui_contract_test.dart`

### Implementation for User Story 4

- [X] T031 [US4] Polish chat list row layout and state handling in `lib/features/chat/presentation/screens/chat_list_screen.dart`
- [X] T032 [US4] Polish product context, safety cue, grouping, timestamps, and action placement in `lib/features/chat/presentation/screens/chat_detail_screen.dart`
- [X] T033 [US4] Add Arabic/RTL-safe chat strings and alignment in `lib/core/localization/app_localizations.dart`

---

## Phase 7: Release Validation

**Purpose**: Validate the full feature against the plan.

- [X] T034 Run `flutter analyze`
- [X] T035 Run `flutter test`
- [X] T036 Run targeted chat/security tests from `test/features/chat/` and `test/security/chat_rules_test.dart`
- [X] T037 Run `flutter build web`
- [X] T038 Update validation log in `specs/014-realtime-chat-security-ui/plan.md`

---

## Dependencies & Execution Order

- Phase 1 must complete before Phase 2.
- Phase 2 blocks all user story implementation.
- US1 and US2 are both P1 and must complete before US3 reporting and US4 polish.
- US3 depends on the report/security foundation from US2.
- US4 depends on the visible list/detail flows from US1 and participant states from US2.
- Release validation depends on all selected implementation tasks.

## Parallel Opportunities

- T004 and T005 can run in parallel.
- T010 and T011 can run in parallel.
- T016 and T017 can run in parallel.
- T022 and T023 can run in parallel.
- T029 and T030 can run in parallel.

## Implementation Strategy

1. Complete setup and foundation first.
2. Deliver P1 real-time messaging and security together.
3. Add reporting and staff review only after participant access rules are hardened.
4. Finish with UI/RTL polish and release validation.
