# Note API rejects a Chat-validated token

Status: backend fix required; not applied or deployed from this Flutter repository.

The failing `POST https://note.piisiit.com/api/folder/save` reports a signature
rejection. The same app session is accepted by Chat (`accountValid`). Client
diagnostics show issuer `PiisiitChat`, audience `PiisiitClient`, no surrounding
whitespace, no duplicate Bearer prefix, and no expiry by the device clock.
The exact server exception and deployed configuration still need inspection.

Keep login, registration, refresh, and account operations on Chat. Note, folder,
and attachment requests continue using the logged-in user's bearer token.

## Required backend investigation and change

Inspect the authentication scheme used by Note's protected routes, its JWT
validation code, and the effective deployment configuration (including overrides
and all running instances). Configure the scheme to validate Chat access tokens:

| Validation setting | Intended value |
| --- | --- |
| Accepted issuer | `PiisiitChat` |
| Accepted audience | `PiisiitClient` |
| Verification key | Key corresponding to Chat's actual token-signing key |
| Signature algorithm | Algorithm actually used and permitted by Chat |
| Signature and lifetime checks | Enabled |

These are semantic settings, not confirmed configuration property names. The
backend source is needed to make the exact patch.

For HMAC tokens, the validator needs the exact same secret bytes and decoding
convention as the issuer. For asymmetric tokens, use Chat's trusted public
verification keys or authenticated key-discovery configuration. Check missing,
stale, or incorrectly decoded keys and rotation/key-ID handling. Match settings
across Note instances. Updating issuer/audience alone will not repair a
signature rejection. Keep keys in backend secret configuration, never Flutter.

Retain signature, issuer, audience, lifetime, and authorization checks. Do not
bypass authentication or replace the user's token with a shared sample token.
After signature validation succeeds, confirm Note maps Chat's authenticated user
and session claims correctly and enforces folder/note ownership.

This follows Microsoft's [JWT bearer validation guidance](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication),
which requires signature, issuer, audience, and expiration validation.

## Verification after applying the backend fix

Use a test account to log in through Chat, then send its unchanged bearer token
to Note. Verify note/folder reads, create and update a disposable test folder,
and test a disposable attachment through the normal application flow. A folder
save with `code: 200` and `data: null` is successful.

Confirm tampered, expired, wrong-issuer, and wrong-audience tokens are rejected,
and that a different user cannot access the test account's records. Check every
deployed instance. Do not log credentials or put signing secrets in tests.

The Flutter regression `Note signature rejection does not replay a folder save
or revoke a valid Chat session` reproduces the observed failure and protects the
valid session. Passing this test does not mean the backend rejection is fixed.
