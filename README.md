# GitHub Explorer — Starter App

This is the starting point for the Flutter senior developer take-home assignment.
It is intentionally minimal and unpolished — see `lib/main.dart` for notes on
exactly what's missing and what you're expected to build.

## Requirements
- Flutter SDK 3.3+ (any recent stable channel is fine)
- Dart 3.3+

## Setup

This zip ships with `lib/`, `pubspec.yaml`, and config files only — it does
**not** include the generated `android/` and `ios/` platform folders (those
depend on your local Flutter SDK version, so we generate them fresh on your
machine rather than shipping a possibly-mismatched copy).

**Step 1 — generate platform folders** (safe: it will not overwrite `lib/`
or `pubspec.yaml`):
```bash
flutter create .
```

**Step 2 — install dependencies and run:**
```bash
flutter pub get
flutter run
```

That's it — there's no backend to stand up. The app talks directly to the
public GitHub REST API (`https://api.github.com`).

If `flutter create .` complains about the package name (org/bundle id), you
can safely ignore it or rerun with `flutter create --org com.example .` —
it won't affect the assignment.

## GitHub API rate limits

Unauthenticated requests are limited to **60 requests/hour** per IP. If you
hit this while testing (easy to do without debouncing — which is one of the
things you're asked to fix), you can raise the limit to 5,000/hour:

1. Generate a personal access token at https://github.com/settings/tokens
   (no scopes/permissions need to be checked — a basic token is enough for
   read-only public endpoints).
2. Pass it as a header on your requests:
   ```dart
   headers: {'Authorization': 'token YOUR_TOKEN_HERE'}
   ```
3. **Do not commit this token.** Add it to a gitignored file or pass it via
   `--dart-define` if you want to be tidy about it.

## Relevant endpoints for this assignment

- Search users: `GET /search/users?q={query}&page={page}&per_page={n}`
- User detail: `GET /users/{username}`

Full API docs: https://docs.github.com/en/rest

## What to do from here

See the main assignment document for full requirements. In short: refactor
this into a properly architected app with real state management, pagination,
error handling, local persistence (favorites), proper navigation with deep
linking, and one native platform integration.

Good luck!
