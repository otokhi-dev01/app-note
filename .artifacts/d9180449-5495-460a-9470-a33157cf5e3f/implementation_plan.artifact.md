# Fix Persistent 401 Unauthorized Errors on Note Server

The user is experiencing persistent 401 errors when accessing `https://note.piisiit.com/api/folder` and `https://note.piisiit.com/api/note`. The logs indicate that the app identifies these as `note_rejected_renewed_token` and `accountValid`, but the user remains logged in and requests continue to fail.

## User Review Required

> [!IMPORTANT]
> This change modifies the core networking logic for handling session recovery. It introduces a retry mechanism for cases where the account server says a token is valid but the note server rejects it.

## Proposed Changes

### Core Network

#### [MODIFY] [api_client.dart](file:///Users/apple/Documents/Apps/app-note/lib/core/network/api_client.dart)

- **Allow Retries for `accountValid` results**: Currently, the interceptor only retries the original request if a token was explicitly refreshed. If the account server says the current token is valid (`accountValid`), the request is not retried, leading to a visible error even if the session is healthy. We will now allow a single retry in this case as well.
- **Reduce Note-side Backoff**: Shorten the backoff duration from 30 seconds to 5 seconds when the Note server rejects a renewed token. This prevents the app from being stuck in a failure state for too long if the rejection was transient (e.g., clock skew or propagation lag).
- **Add Diagnostic Logging**: Log when a retry is attempted for a valid account session to help debug Note-side authorization issues.

## Verification Plan

### Automated Tests
- Run existing session recovery tests: `flutter test test/session_recovery_test.dart`
- Verify that `Concurrent 401s` still pass.
- Verify that `Note rejecting a renewed token` still reports failure but follows the new backoff.

### Manual Verification
- Test the app by navigating to the Folder or Note lists after a period of inactivity to trigger a 401.
- Observe the logs to ensure "Recovered ..." messages appear when the account is valid.
