# Apple Account Sync Goal

## Goal

Ortio should gently require account ownership for profile and settings changes:

- Signed-out users see the placeholder profile and a single Apple sign-in entry.
- Signed-out users cannot edit profile details.
- Signed-out users do not see notifications or appearance controls.
- Signed-in Apple users can edit profile details and account-owned settings.
- Model files stay local. Supabase is only for compact user/profile data and an
  optional profile image reference.

## Current App Behavior

`SettingsView` uses native Sign in with Apple through `AuthenticationServices`.
On successful Apple authorization, Ortio stores only the compact identity fields
needed to unlock local account-owned settings:

- account provider: `apple`
- Apple stable user identifier
- optional email, only if Apple provides it
- optional display name, only if Apple provides it during first authorization
- local sign-in timestamp

Ortio does not store Apple identity tokens, refresh tokens, passwords, or model
files in SwiftData.

## Supabase Storage Contract

When a Supabase project is connected, keep the backend schema minimal:

### `profiles`

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `display_name text`
- `username text`
- `avatar_path text`
- `updated_at timestamptz not null default now()`

Do not store model metadata, local file paths, capture folders, or OAuth tokens
in this table.

### Storage Bucket

Use a private `profile-avatars` bucket only if remote profile pictures are
needed. Store objects under:

```text
{auth.users.id}/avatar.jpg
```

Keep profile image upload optional. The app can continue using the existing
local SwiftData external-storage image while Supabase is not configured.

## Row-Level Security Shape

- Users can select, insert, update, and delete only their own `profiles` row:
  `profiles.user_id = auth.uid()`.
- Storage objects are private by default.
- Users can access avatar objects only when the first path segment equals
  `auth.uid()`.
- Never ship the Supabase service-role key in the iOS app.

## Native Apple To Supabase Flow

Supabase documents the native Swift flow as:

1. Use `SignInWithAppleButton`.
2. Request `.email` and `.fullName`.
3. Extract `ASAuthorizationAppleIDCredential.identityToken`.
4. Pass the ID token to Supabase Swift `signInWithIdToken(provider: .apple)`.
5. If `credential.fullName` is present, save a compact display name to user
   metadata or the `profiles` table immediately because Apple only provides the
   name during the first authorization.

This repository does not yet contain Supabase URL/key configuration, so the
current implementation stops at native Apple sign-in and local compact account
state.

## Sources

- Supabase Apple Auth:
  https://supabase.com/docs/guides/auth/social-login/auth-apple
- Supabase Swift `signInWithIdToken`:
  https://supabase.com/docs/reference/swift/auth-signinwithidtoken
- Apple Sign in with Apple:
  https://developer.apple.com/documentation/authenticationservices/implementing-user-authentication-with-sign-in-with-apple
