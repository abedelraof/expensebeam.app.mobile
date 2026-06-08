# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>
flutter devices  # list available devices

# Build
flutter build apk          # Android
flutter build ios          # iOS

# Lint / static analysis
flutter analyze

# Tests
flutter test                          # all tests
flutter test test/widget_test.dart    # single file

# Get dependencies
flutter pub get
```

## Architecture

**State management:** Provider (`package:provider`). Two global providers are registered at the root in `main.dart`:
- `AuthProvider` — JWT auth state; gates the entire app (unauthenticated → `AuthScreen`, authenticated → `MainShell`)
- `ThemeProvider` — light/dark mode toggle persisted via `shared_preferences`

All other data fetching is done locally inside each screen's `StatefulWidget` (no screen-level providers), calling `ApiClient` directly.

**API layer:** `lib/core/api/api_client.dart` — a thin static wrapper around `dio`. It reads a JWT from `flutter_secure_storage` and injects it as a `Bearer` token on every request. Base URL is `https://expensebeam.com/api`. All screens call `ApiClient.get/post/put/delete` directly.

**Navigation:** `MainShell` uses an `IndexedStack` (not a Navigator) to keep all 5 tabs alive. Navigation between tabs is an index change, not a route push. Drawer handles the tab switching. Sub-screens (edit/history/etc.) are pushed via `Navigator.push` from within their parent tab screen.

**Screens:** Organized by feature under `lib/screens/`:
- `auth/` — login, signup (shown before auth)
- `dashboard/` — summary stats, quick expense entry, AI chat assistant, goals preview, receipt scan
- `transactions/` — expense list + edit/create form
- `reports/` — charts using `fl_chart`
- `accounts/` — account balances + history
- `settings/` — categories, budgets, theme toggle, profile

**Models:** Plain Dart classes in `lib/core/models/` with `fromJson` factories — no code generation.

**Theme:** All colors and `ThemeData` live in `lib/core/theme/app_theme.dart`. Use `AppTheme.primary`, `AppTheme.accent`, `AppTheme.success`, `AppTheme.danger`, `AppTheme.warning` constants rather than hardcoding colors. Both light and dark themes are fully defined there.

**Formatters:** Currency and date utilities in `lib/core/utils/formatters.dart`.
