# Contract: Chat UI and Security Behavior

## Purpose

This contract defines observable behavior for public chat, safety reporting, and staff review. It is not an implementation API contract; it is the behavior future code and tests must satisfy.

## Public Chat List Contract

- Shows only conversations where the signed-in user is a participant.
- Excludes conversations hidden by the signed-in user unless an explicit recovery view is later added.
- Orders conversations by latest accepted activity.
- Shows product context, other participant name, latest safe preview, relative time, role context, and unread state.
- Does not expose admin moderation controls.
- Shows loading, empty, search-empty, denied, and retry states.

## Public Conversation Contract

- Shows only messages from conversations the signed-in user can access.
- Displays new accepted messages without manual refresh.
- Preserves chronological order when messages arrive close together.
- Shows pending, delivered, and failed states for the current user's send attempts.
- Preserves unsent draft text on failure.
- Shows product context and safe transaction cues.
- Provides participant actions for hide, mute/block where available, and report.
- Handles removed product or disabled participant states with safe fallback copy.
- Supports Arabic/RTL alignment and action placement.

## Message Write Contract

- A participant can send a message only as themselves.
- A send action can create message content and update allowed conversation summary fields.
- A send action cannot change participants, product context, staff review state, report state, or audit fields.
- Empty or over-limit content is rejected with user-readable feedback.
- Failed sends are visible to the sender and retryable where feasible.

## Report Contract

- A participant can report a message or conversation they are allowed to view.
- A report requires a reason.
- The reporter receives confirmation after submission.
- Report evidence is available only to authorized staff review workflows.
- The report flow does not delete the conversation for either participant by default.

## Staff Review Contract

- Staff review access is role-scoped and tied to reports, support cases, or safety queues.
- Staff actions require a reason.
- Review actions produce audit evidence.
- Staff review does not create public admin affordances in buyer/seller chat screens.

## Security Test Contract

The feature is not ready unless tests cover:

- Unauthenticated user denied.
- Non-participant denied.
- Buyer participant allowed for their conversations.
- Seller participant allowed for their conversations.
- Participant cannot spoof sender.
- Participant cannot alter protected conversation metadata.
- Participant can modify only their own hidden/muted/block state.
- Participant can create a valid report.
- Unauthorized user cannot read report evidence.
- Authorized staff can review only role-appropriate report evidence.
