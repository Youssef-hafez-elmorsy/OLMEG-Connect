# Data Model: Real-Time Chat Security UI

## Conversation

Represents a buyer-seller thread for one product.

**Core attributes**

- `id`: Stable conversation identifier.
- `productId`: Product connected to the conversation.
- `productTitle`: Display title for chat context.
- `buyerId`: Buyer participant.
- `buyerName`: Buyer display name snapshot.
- `sellerId`: Seller participant.
- `sellerName`: Seller display name snapshot.
- `participants`: Buyer and seller identifiers.
- `latestMessagePreview`: Safe preview for conversation list.
- `latestMessageAt`: Last message/activity time.
- `latestMessageSenderId`: Sender of latest message.
- `unreadBy`: Participant identifiers with unread content.
- `hiddenFor`: Participant identifiers who hid the conversation.
- `mutedFor`: Participant identifiers who muted notifications.
- `blockedBy`: Participant identifiers who blocked further interaction.
- `safetyStatus`: Normal, reported, under review, restricted, or closed.
- `createdAt`, `updatedAt`: Lifecycle timestamps.

**Validation rules**

- Buyer and seller must be distinct authenticated users.
- Participants cannot be changed by normal message sends.
- Product context cannot be changed by normal message sends.
- Per-user visibility state can only affect the requesting user unless staff action is authorized.
- Latest-message summary must reflect an accepted message.

**State transitions**

- `active` -> `hidden_for_user`: User hides their local view.
- `active` -> `muted_for_user`: User suppresses notifications.
- `active` -> `reported`: Participant reports content.
- `reported` -> `under_review`: Authorized staff begins review.
- `under_review` -> `restricted`: Staff restricts unsafe conversation.
- `under_review` -> `active`: Staff clears report.
- `active/reported/under_review` -> `closed`: Product/account state or staff decision ends messaging.

## Message

Represents one chat entry in a conversation.

**Core attributes**

- `id`: Stable message identifier.
- `conversationId`: Parent conversation.
- `senderId`: Authenticated sender.
- `senderName`: Sender display name snapshot.
- `content`: Text message body.
- `status`: Pending, delivered, failed, removed, or restricted.
- `moderationState`: Normal, reported, hidden, removed, or staff-only evidence.
- `createdAt`: Accepted creation time.
- `clientCreatedAt`: Client-side draft/sending time for local ordering.
- `editedAt`: Optional edit timestamp if editing is later approved.

**Validation rules**

- Sender must be one of the conversation participants.
- Sender identity cannot be supplied for another user.
- Content must be non-empty after trimming.
- Content must fit the maximum accepted length.
- Messages cannot mutate conversation participants or product context.
- Removed/restricted content must retain enough evidence for authorized review.

## Conversation Participant State

Represents per-user state that should not affect the other participant's history.

**Core attributes**

- `conversationId`
- `userId`
- `lastReadAt`
- `unreadCount`
- `hidden`
- `muted`
- `blocked`
- `draftText`
- `notificationPreference`

**Validation rules**

- Users can only modify their own participant state.
- Hiding or muting does not delete the conversation for other participants.
- Blocking protects the blocking user and may restrict new incoming notifications.

## Chat Report

Represents a safety or support report from a participant.

**Core attributes**

- `id`
- `conversationId`
- `messageId`
- `reporterId`
- `reportedUserId`
- `productId`
- `reason`
- `description`
- `evidenceSnapshot`
- `status`
- `createdAt`
- `updatedAt`

**Validation rules**

- Reporter must be a conversation participant.
- Reason is required.
- Evidence must be sufficient for review but not visible to unrelated users.
- Status changes require authorized staff or trusted system action.

## Staff Review Record

Represents an operations review of reported chat content.

**Core attributes**

- `id`
- `reportId`
- `conversationId`
- `reviewerId`
- `reviewerRole`
- `action`
- `reason`
- `createdAt`
- `auditReference`

**Validation rules**

- Only authorized staff roles can create review records.
- A reason is required for sensitive actions.
- Review records are immutable except for trusted audit maintenance.

## Product Chat Context

Represents product and transaction cues displayed in chat.

**Core attributes**

- `productId`
- `title`
- `availabilityState`
- `moderationState`
- `sellerId`
- `safeTransactionCue`

**Validation rules**

- Public users see only product context they are allowed to access.
- Removed or moderated products show a safe fallback rather than breaking the conversation.
