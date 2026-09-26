# Note authentication verification

Client normalization, access-token selection, and terminal-401 handling are
implemented in this Flutter repository. A deployed backend signing-key problem
has not been fixed or verified here; backend source/configuration and a live
authenticated test account were not available.

## Actual request and storage path

`AuthController.login` → `Login` → `AuthRepositoryImpl` →
`AuthRemoteDataSource` → `ApiClient` sends login to
`POST https://chat.piisiit.com/api/auth/login`. The repository persists the
response through `SessionStorage`; Note requests use the same raw access token
at `https://note.piisiit.com/api/note`. There are no classes named `ApiService`,
`AuthService`, or `SessionService` in this checkout; the classes above perform
those roles.

The user confirmed keeping Chat login and FlutterSecureStorage. Only the raw
access token is saved under `token`; GetStorage holds preferences/local data,
not a second credential copy. Explicit access-token fields take precedence over
legacy generic token fields. Refresh and ID token fields are never used as the
access token. Empty/non-string access-token candidates are ignored.

Chat's public Swagger was checked on 2026-09-26: it documents login and
`POST /api/auth/refresh-token` with a `refreshToken` request field. Its successful
response schema does not specify token fields, so live response selection still
needs verification with a test account. Automated fixtures cover supported
response envelopes and the complete login → persistence → Note request flow.

## Clear the old token and check a fresh login

1. Restart the app with the updated code. Existing stored Bearer prefixes and
   outer whitespace are normalized during session restore.
2. To explicitly remove the old access token, run this once from a development
   action/debugger after app initialization:

   ```dart
   await Get.find<SessionStorage>().invalidateToken();
   Get.offAllNamed('/login');
   ```

   This synchronizes in-memory state and deletes only `token` from secure
   storage. Do not call `GetStorage().erase()` or secure-storage `deleteAll()`.
3. Sign in through the normal login screen. Check that login reports HTTP 200
   and `[SESSION] Saving token` reports `tokenExists: true`. The persisted value
   and the `AuthSession` returned by login have no Bearer prefix. A prefix-only
   response is rejected as a missing token.
4. Open the notes list, or call the same configured client in a development
   action after login:

   ```dart
   final response = await Get.find<ApiClient>().dio.get('/api/note');
   debugPrint('Notes HTTP status: ${response.statusCode}');
   ```

5. Verify the debug log contains
   `GET https://note.piisiit.com/api/note status=200`. The interceptor sends
   exactly one `Authorization: Bearer <raw-token>` header. Do not print the
   token or the complete request headers to inspect this.

Automated tests verify HTTP 200 through a fake HTTP adapter. That result is not
proof the deployed Note server accepts a newly issued token.

## What a 401 now does

Login/public endpoint failures leave existing credentials untouched. A protected
request with no token redirects to login without an invented refresh request.
When a saved refresh token and configured endpoint exist, ordinary protected
401s share a single refresh attempt and retry at most once with a changed token.
`ApiClient(refreshTokenEndpoint: null)` disables refresh; a refresh 404/405 also
disables further attempts for that client. A refresh outage keeps credentials
and applies a short cooldown.

A signature/issuer/audience rejection, absent refresh credentials, rejected
renewal, or another 401 after renewal invalidates the access token and redirects
to login. Only the `token` key is deleted. Retained account/refresh metadata is
not loaded into an authenticated session without that key. Notes, preferences,
identity records, and encryption keys remain intact. Old requests and pending
refreshes cannot overwrite a newer login or resurrect a signed-out session.

Diagnostics distinguish missing, malformed, expired, not-yet-valid, duplicated
Bearer prefixes, and server signature rejection. JWT decoding supplies metadata
only; it does not authenticate the token. Logs omit tokens, signatures, user
claims, raw response bodies, and raw authentication challenge descriptions.

## If a fresh login still reports `signature_rejected`

This is probably a backend JWT configuration problem. The provided logs show
issuer `PiisiitChat`, audience `PiisiitClient`, and Note rejecting the signature
while the earlier client reported Chat's account as valid. Neither those logs
nor JWT decoding reveal the backend verification key or exact configuration.

Compare the authentication issuer and every deployed Note instance:

| Setting | Backend verification required |
| --- | --- |
| Signing/verification key | For HMAC, identical secret bytes and decoding convention; for asymmetric JWTs, the public key corresponding to Chat's private signing key |
| Algorithm | Actual signing algorithm matches Note's permitted algorithms |
| Issuer | Note accepts the intended `PiisiitChat` issuer |
| Audience | Note accepts the intended `PiisiitClient` audience |
| Environment | Both services use the intended production issuer and keys; inspect deployment overrides, rotation/key IDs, and all instances |

The backend source and effective deployment configuration are needed to check
these values. No secret values should be copied into Flutter or diagnostic logs.
Changing issuer/audience alone cannot repair a mismatched signing key. Retain
signature, issuer, audience, expiration, and ownership validation. This follows
Microsoft's [JWT bearer validation guidance](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication).

After applying a backend fix, log in through Chat and send the unchanged token
to Note. Confirm HTTP 200 for note/folder reads, then verify tampered, expired,
wrong-issuer, and wrong-audience tokens still fail and cross-account access is
rejected. Perform this check against every deployed instance.
