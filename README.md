# GitHub Explorer

A Flutter app for searching GitHub users, viewing profiles and saving favorites.
It is built on top of the provided starter. The single `setState` screen has been
replaced with a layered, tested app that covers every core requirement of the
assignment, plus the bonus items listed below.

| | |
|---|---|
| Flutter | 3.47.0 (stable) |
| Dart | 3.13.0 (requires Dart 3.12+, which Riverpod 3 needs) |
| Platforms | Android, iOS |
| State management | Riverpod 3, written by hand without code generation |
| Networking | Dio |
| Navigation | go_router |
| Persistence | sqflite (favorites), flutter_secure_storage (JWT) |
| Native integration | Native share sheet (`share_plus`) |
| Tests | 191 tests across 28 files (`flutter test`) |

## Running the app

```bash
flutter pub get
flutter run
```

Sign in with the demo account:

- **Username:** `demo`
- **Password:** `flutter123`

### Optional configuration

Copy `env.example.json` to `env.json`. `env.json` is gitignored. Then run:

```bash
flutter run --dart-define-from-file=env.json
```

| Key | Default | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | empty | A personal access token, with no scopes needed. Raises GitHub's rate limits. |
| `AUTH_TOKEN_TTL_SECONDS` | `300` | Lifetime of the mock JWT. Set it to `30` to see expiry handling quickly. |

### Tests

```bash
flutter analyze
flutter test
```

## Features

- **Search.** Requests are debounced by 400 ms. Typing a new query cancels the
  request that is still in flight, and a late response for an old query is
  ignored. Pressing Enter searches immediately.
- **Pagination.** Results load with infinite scroll, 30 users per page. The list
  stops at GitHub's 1,000-result search limit and says so. If loading a page
  fails, the results already loaded stay on screen and a Retry row appears.
- **Distinct states.** Idle, loading, results, empty ("No users found for…") and
  error each have their own screen. Errors are split further: offline, timeout,
  rate limited (with a live countdown to the reset time), invalid query, not
  found and server error. Retry is hidden where it cannot help, such as an
  invalid query or while still rate limited.
- **Profile screen.** Calls `GET /users/{username}` and shows the avatar, name,
  bio, follower/following/repository counts, company, location, website, email,
  Twitter and join date.
- **Mock JWT login.** See [Authentication](#authentication).
- **Favorites.** Star a user from the results or from the profile screen. They
  are saved in SQLite, survive restarts, and the Favorites tab works with no
  network connection.
- **Responsive layout.**
  - Phones: bottom navigation bar.
  - 600 px and wider: a side navigation rail.
  - 840 px and wider: the list and the profile side by side.
- **Deep links.** `myapp://user/{username}` opens a profile, including from a cold
  start and when signed out. `myapp://favorites` opens the Favorites tab.
- **Native share.** Shares a profile's GitHub URL through the system share sheet.
- **Bonus items.**
  - Light and dark theme, following the system setting.
  - An offline banner.
  - Searches and profiles that failed while offline retry automatically when
    the connection returns.
  - Unit and widget tests across every layer.

## Architecture

The code is organized by feature, and each feature is split into three layers:

```
lib/
  main.dart                ProviderScope + App
  app.dart                 MaterialApp.router, themes, offline banner
  core/
    config/                compile-time config (--dart-define)
    database/              SQLite database, versioned schema and migrations
    layout/                breakpoints, master-detail layout
    network/               Dio client, error mapping, AppFailure, connectivity
    platform/              native share service
    providers/             app-wide providers (Dio)
    router/                routes, auth and deep-link redirects, tab shell
    theme/                 light and dark ThemeData
    widgets/               shared UI: status/failure views, avatar, offline banner
  features/
    search/                user search and pagination
    user_detail/           profile screen and share content
    auth/                  mock JWT login, token storage, session handling
    favorites/             favorites in SQLite
      data/                API/DB data sources, DTOs, repository implementations
      domain/              entities and repository interfaces (pure Dart)
      presentation/        Riverpod notifiers/providers, pages, widgets
test/                      mirrors lib/, plus test/helpers (fakes and harness)
```

Dependencies point inward: `presentation → domain ← data`.

- **Widgets contain no business logic.** They render state and forward user
  actions to notifiers.
- **Repositories never leak Dio or SQLite exceptions.** Every error becomes one
  case of a sealed `AppFailure` type. The UI switches on it exhaustively, so
  each case gets its own message rather than a generic "Something went wrong".
- **Cancellation stays out of the domain layer.** The domain uses its own
  `CancellationToken`. The data layer converts it to Dio's `CancelToken`, so the
  domain does not import Dio.
- **Providers are the dependency injection.** Each repository is exposed through
  a provider, and tests replace it with `overrideWithValue`. No service locator
  is used.

### Why Riverpod (over Bloc)

- **Easy test setup.** Swapping a repository, the clock, the database or the
  connectivity source in a test is a one-line override. The test suite relies
  heavily on this.
- **Automatic cleanup.** The profile screen uses
  `FutureProvider.autoDispose.family`, keyed by username. Leaving the page
  disposes the provider, which cancels its HTTP request. Each username gets its
  own cached state.
- **Precise rebuilds.** `select` means each star button rebuilds only when its
  own user's favorite status changes.
- **The router reads state directly.** The router's redirect reads the auth
  state and is refreshed through `ref.listen`, without any `BuildContext`
  plumbing.
- **Less boilerplate at this size.** There are no separate event classes.
  Notifiers expose methods such as `onQueryChanged`, `loadMore`, `retry`,
  `login` and `toggle`, and states are sealed classes.

The trade-off is that Bloc's event transformers (`debounce`, `restartable`) give
debounce and cancellation for free. Here they are written explicitly in
`SearchNotifier` with a `Timer` and the `CancellationToken`, and covered by
`fake_async` tests.

I chose not to use code generation (`riverpod_generator`). It keeps the
dependencies small and means reviewers read the real code rather than generated
`.g.dart` files.

## Authentication

There is no real backend. `MockAuthServer` is a Dio `HttpClientAdapter`, so the
app's real Dio pipeline and interceptors run unchanged against it.

- **`POST /auth/login`** checks the demo credentials. On success it returns a
  JWT signed with HS256, with `sub`, `iat` and `exp` claims.
- **`GET /auth/me`** is the protected call. It verifies the token's signature,
  issuer and expiry, and returns **401** if any check fails. The Account page
  (person icon in the search app bar) shows its result.
- **Storage.** The token is kept in `flutter_secure_storage`: Keychain on iOS,
  encrypted storage on Android. It survives restarts.
- **`AuthInterceptor`.** Only requests marked as protected get
  `Authorization: Bearer <jwt>`. A missing or expired token stops the request
  before it is sent. A 401 from the server signs the user out.
- **Expiry is detected in four places:**
  - at startup, when restoring the saved token
  - by a timer that fires at the token's `exp`
  - before each protected call
  - when the server returns 401

  Each of these sends the user to login with a "session expired" message.
- **The router guard** redirects to `/splash` while the session is restored, and
  to `/login?from=<target>` when signed out. After signing in, the user lands on
  the original target. `from` only accepts in-app paths, so it cannot be used
  to redirect outside the app.
- **Layering.** The data layer reports a 401 as a `SessionEvents` event, and
  `AuthNotifier` listens to it. Data code never imports presentation code.

GitHub API calls are not behind the JWT. They use the optional GitHub personal
access token instead.

## Persistence

- **One SQLite database** (`github_explorer.db`) with a versioned schema and a
  migration hook (`AppDatabase._migrate`).
- **The `favorites` table:**
  - GitHub user `id` as the primary key
  - `login`, unique
  - avatar URL and profile URL
  - optional `name`
  - `added_at`, indexed for newest-first ordering
- **Saving uses `INSERT OR REPLACE`**, so favoriting a user again
  updates the row instead of duplicating it. Favoriting from the profile screen
  also stores the full name.
- **`FavoritesNotifier` is the single source of truth.** Changes appear on screen
  immediately and are written to SQLite. If the write fails, only that one
  change is rolled back and a snackbar explains why.

## Native integration: share sheet

The profile screen has a Share button, which uses the platform's share icon on
iOS and Android. It opens the system share sheet with:

> Check out The Octocat (@octocat) on GitHub: https://github.com/octocat

The subject, "The Octocat on GitHub", is used when sharing by email.

- **The button passes its on-screen position** to the share sheet. iPad requires
  this, or the app crashes, and it also works when the profile is in the right
  pane on a tablet.
- **`share_plus` sits behind a small `ShareService` interface.** Failures return
  a result instead of throwing, and the user sees a snackbar.
- **Tests cover the real `share_plus` path.** They mock the plugin's method
  channel and check the exact payload sent, including the iPad anchor
  rectangle.

## Deep links

Registered for the `myapp` scheme:

- **Android:** a `VIEW`/`BROWSABLE` intent filter.
- **iOS:** `CFBundleURLTypes` in `Info.plist`.

```bash
adb shell am start -a android.intent.action.VIEW -d "myapp://user/octocat"
xcrun simctl openurl booted "myapp://user/octocat"
```

**The host problem.** Flutter passes the full URL to the app: Android sends
`data.toString()` and iOS sends `url.absoluteString`. In
`myapp://user/octocat`, `user` is the URL's **host**, so go_router would only
match `/octocat` and the user would land on "Page not found".
`DeepLinks.toLocation` reads the host plus the path segments and rewrites the
link in the router's top-level redirect, before the auth check runs.

- **Usernames are validated** against GitHub's format. Invalid or unknown links
  land on search.
- **The triple-slash form** (`myapp:///user/octocat`) also works.

## Testing

191 tests in 28 files. They run without a device or network.

- **Data layer.** Repositories run against a fake Dio adapter. They cover status
  code and rate-limit mapping, parsing, cancellation and malformed bodies.
  Favorites run against **real SQLite through `sqflite_common_ffi`**, including
  closing and reopening the database to prove favorites persist.
- **State.** Notifier tests use `fake_async` and `package:clock`. They cover
  exact debounce timing, stale responses, pagination edge cases, token expiry
  timers and rollback of optimistic updates.
- **Widgets and flows.** These run the full app (`test/helpers/test_app.dart`)
  signed in with fake repositories. They cover search states, the
  rate-limit countdown, login and redirect flows, expiry mid-session, favorites
  across tabs, three screen sizes (including resizing from tablet to phone) and
  the offline banner.
- **Platform boundaries.** Deep links are fed through the real
  `flutter/navigation` channel and the cold-start route. Share and connectivity
  tests mock the plugins' channels.

## Known limitations

- **The mock auth signing key ships inside the app.** That is acceptable only
  because it is a mock. A real backend signs tokens on the server, and the
  client never verifies signatures. There are no refresh tokens: when the
  session expires, the user signs in again.
- **GitHub's limits apply.** Search returns at most 1,000 results. The search
  endpoint allows 10 requests per minute without a token and 30 with one.
  Hitting the limit shows the rate-limit screen with a countdown.
- **Offline detection checks for a network connection,** such as Wi-Fi or mobile
  data, not whether the internet is actually reachable. A captive portal looks
  "online" and surfaces as a network error instead.
- **Profiles are not cached.** Opening a profile offline shows the offline state
  and reloads automatically on reconnect. Avatars are not cached either:
  offline, they fall back to the user's initial.
- **Favorites store a snapshot** of login, name and avatar URL, taken when the
  user is starred. It is not refreshed later.
- **Custom scheme only.** Deep links use `myapp://`. Android App Links and iOS
  Universal Links would need a verified domain.
- **Device verification is partial.**
  - iOS: scheme registration was checked on a simulator, where iOS showed its
    "Open in …?" prompt for the app. Tapping through to the profile was not
    checked on a device; the tests cover that routing.
  - Android: built, and covered by tests, but not run on an emulator.
- **English only.** No localization.

## Assumptions

- **"Protected simulated call"** means a call to the in-app mock server (`GET
  /auth/me`). The GitHub API is public and not behind the JWT.
- **Favorites are identified by GitHub user `id`,** which never changes, rather
  than by `login`, which users can rename.
- **Values chosen by judgment:**
  - debounce: 400 ms
  - page size: 30
  - breakpoints: 600 / 840 px (Material 3 window size classes)
  - mock token lifetime: 5 minutes
- **Riverpod 3 retries failed providers automatically by default.** That retry
  is turned off for the profile, account and favorites providers, so a 404 or a
  rate limit does not keep firing requests. Explicit Retry buttons and
  retry-on-reconnect are used instead.
