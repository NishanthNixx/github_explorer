# GitHub Explorer — Starter App

This is the starting point for the Flutter senior developer take-home assignment.
It is intentionally minimal and unpolished — see `lib/main.dart` for notes on
exactly what's missing and what you're expected to build.

## Requirements
- A Flutter stable release that ships Dart 3.12+ (required by Riverpod 3)
- Developed on Flutter 3.47.0 / Dart 3.13.0

## Project structure

Feature-first, with each feature split into layers:

```
lib/
  main.dart            # entry point, runApp only
  app.dart             # MaterialApp / app-wide wiring
  core/                # shared, feature-agnostic code
    config/            # compile-time config (dart-define)
    network/           # Dio client, interceptors, failure types
    providers/         # app-wide Riverpod providers (Dio, storage, ...)
    router/            # route table, guards
    theme/             # ThemeData
    widgets/           # reusable widgets
  features/
    search/            # user search + pagination
    user_detail/       # GET /users/{username}
    auth/              # mock JWT login
    favorites/         # locally persisted favorites
      data/            # API/DB sources, DTOs, repository implementations
      domain/          # entities, repository interfaces (pure Dart, no Flutter)
      presentation/    # providers (Riverpod notifiers), pages, widgets
test/                  # mirrors lib/
```

Dependencies point inward: `presentation → domain ← data`. Widgets never call
HTTP or the database directly.

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
2. Copy `env.example.json` to `env.json` (gitignored) and put the token in it.
3. Run with:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```
   The app reads it via `AppConfig.githubToken` and sends it as a Bearer token.

Note: the **search** endpoint has its own stricter limit — 10 requests/minute
unauthenticated, 30/minute with a token.

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
