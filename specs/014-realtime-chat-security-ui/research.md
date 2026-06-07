# Research: Real-Time Chat Security UI

## Decision: Use phased approval before implementation

**Rationale**: The user explicitly requested phases before any work and asked to give opinions on everything. Chat changes affect security, data shape, UI, and admin review, so approval gates reduce the risk of implementing the wrong scope.

**Alternatives considered**:

- Implement UI first: rejected because the current security model allows broad participant updates and message arrays, so UI polish alone could preserve unsafe behavior.
- Implement everything in one batch: rejected because it would be hard to review and validate.

## Decision: Prioritize data/security before UI polish

**Rationale**: Real-time chat can expose private buyer/seller content. Access control, sender identity, report evidence, and protected metadata must be settled before polishing screens.

**Alternatives considered**:

- Start with visual redesign: rejected because it does not address participant spoofing, message write boundaries, or staff review controls.

## Decision: Move toward individual message records

**Rationale**: Current chat stores messages as an array on the conversation. This can become slow for long histories and makes message-level rules, reporting, delivery state, and moderation harder. Individual messages support chronological pagination, safer writes, and message-level evidence.

**Alternatives considered**:

- Keep messages embedded in the conversation: simpler but weak for 500-message conversations, report targeting, and write validation.
- Split messages only for reported chats: more complex migration logic and inconsistent behavior.

## Decision: Keep normal chat participant-only

**Rationale**: Buyers and sellers should only see conversations they participate in. Operations staff should not get broad private chat browsing in the public app. Staff review should be tied to valid reports, support cases, safety queues, and audit controls.

**Alternatives considered**:

- Admins can read every chat directly: rejected as too broad for private user conversation data.
- Reports contain no evidence: rejected because moderation cannot act reliably without evidence.

## Decision: Text messaging first

**Rationale**: The user's main request is real-time "massage" / message behavior, security, and UI. Text messaging provides immediate user value and the lowest security/storage surface for the first release.

**Alternatives considered**:

- Add attachments immediately: deferred because storage rules, content moderation, upload UX, and abuse handling require separate review.
- Add voice/video: out of scope for current marketplace chat reliability work.

## Decision: UI must remain marketplace-specific

**Rationale**: Chat exists to help buyers and sellers decide safely around a product. Product context, seller/buyer role, safe transaction cues, delivery/payment reminders, unread states, and report/block actions matter more than generic social chat patterns.

**Alternatives considered**:

- Generic messenger UI: rejected because it hides marketplace safety context.
