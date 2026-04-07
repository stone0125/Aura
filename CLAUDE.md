# Aura — AI-Powered Habit Tracker

## Project Overview

Flutter 3.9+ / Dart mobile app with Firebase backend and 9 Gemini AI Cloud Functions.
Helps users build habits through AI coaching, streak tracking, health data integration, gamification, and analytics.

- **Package**: `habit_tracker` (pubspec.yaml)
- **Dart SDK**: ^3.9.2
- **State management**: Provider (ChangeNotifier)
- **Backend**: Firebase (Firestore, Auth, Cloud Messaging, Cloud Functions, Analytics)
- **AI**: Google Gemini (`gemini-3-flash-preview`) via Cloud Functions
- **Platforms**: iOS, Android, macOS, Linux, Windows, Web
- **Dissertation project** — see Dissertation Rules section below

## Architecture

### Directory Structure

```
lib/
  main.dart              — App entry, MultiProvider setup, AuthWrapper
  config/                — Theme (app_colors, app_theme), constants, icons (NO app logic imports)
  models/                — Data classes: Habit, HabitCategory, AI models, health models (NO service/provider/screen imports)
  services/              — Firebase/platform integrations (imports: models, utils, config ONLY)
  providers/             — ChangeNotifier state management (imports: models, services, utils)
  screens/               — Full-page UI widgets (imports: anything)
  widgets/               — Reusable components: home/, progress/, settings/ (imports: models, providers, config)
  utils/                 — Pure helpers: date_utils.dart (imports: NOTHING from this app)

functions/
  index.js               — Cloud Function registration (onCall/onSchedule wrappers)
  helpers.js             — Shared validation, auth, rate limiting, Gemini client
  sendDailySummaries.js  — Scheduled push notification function
  submitSupportMessage.js — Support email function
  agents/                — 9 AI agent modules (one file per agent)
```

### Dependency Layering (ENFORCED by hooks)

```
utils → config → models → services → providers → screens/widgets
```

- `models/` MUST NOT import from services/, providers/, screens/, or widgets/
- `services/` MUST NOT import from providers/, screens/, or widgets/
- `providers/` MUST NOT import from screens/ or widgets/
- `config/` MUST NOT import from models/, services/, providers/, screens/, or widgets/
- `utils/` MUST NOT import from any app-level code (only dart:* and packages)
- `widgets/` can import models, providers, config but NOT screens

### State Management (Provider)

- 7 providers registered in MultiProvider in main.dart:
  ThemeProvider, HabitProvider, HabitDetailProvider, AICoachProvider,
  ProgressProvider (ProxyProvider depending on HabitProvider),
  SettingsProvider, AIScoringProvider
- Use `context.read<T>()` for one-time reads, `context.watch<T>()` for rebuilds
- Use `context.select<T, R>()` when only a subset of provider data is needed
- Providers implement `clearUserData()` for logout — prevents cross-user data leaks
- Always cancel `StreamSubscription`s in `dispose()`
- HabitProvider uses optimistic UI updates with rollback on Firestore error

## Coding Conventions

### Dart Style
See @.claude/rules/dart-conventions.md for full conventions.
Key rules: bilingual headers, snake_case files, `const` constructors, safe JSON parsing `(json['x'] as num?)?.toInt()`, theme colors from `AppColors`, sizes from `UIConstants`.

### Firebase / Firestore
See @.claude/rules/firebase-rules.md for data structure, patterns, and security.
Key rules: `FieldValue.serverTimestamp()` for writes, `YYYY-MM-DD` doc IDs, batch at 400, always check `_userId != null`.

### Cloud Functions / AI Agents
See @.claude/rules/ai-agents.md for the 10-step agent pattern and all 9 agent details.
Every agent follows: auth -> burst limit -> tier -> usage limit -> validate -> sanitize -> Gemini -> parse -> validate output -> record usage.

### Known Errors
See @.claude/rules/errors.md for 50+ documented error patterns with root causes and fixes.
Always check this before claiming an error is new or proposing a fix that's already been tried.

### Testing

- Use `mocktail` for mocking (NOT mockito)
- Mock Firebase services, use `SharedPreferences.setMockInitialValues` for cache
- Test file mirrors lib/ structure: `test/providers/x_test.dart` for `lib/providers/x.dart`
- Group tests by feature within each file

## Common Pitfalls

- **NEVER** use deprecated `Habit.toggleCompletion()` — use `FirestoreService.toggleHabitCompletion()` instead
- **DateTime comparisons** must use `.toLocal()` before comparing dates
- **Streak calculation** is server-side (FirestoreService), not in the model
- **`isCompleted`** on Habit means "completed TODAY", not "ever completed"
- **Always cancel** StreamSubscriptions in `dispose()`
- **Clear provider data** on logout (see `_clearAllProviderData` in main.dart)
- **JSON number parsing**: `(json['x'] as num?)?.toInt()` — direct `as int` throws on doubles from Firestore
- **RevenueCat/subscription** code exists but is future work — do NOT mention in dissertation context

## Skills & Agents

### Skills (slash commands)
- `/deploy-functions` — Pre-flight validation + deploy Cloud Functions
- `/validate-agent` — Verify agents follow the 10-step pattern
- `/check-layers` — Scan all Dart files for dependency layer violations
- `/audit-errors` — Verify documented error fixes were actually applied

### Custom Subagents
- `flutter-reviewer` — Reviews Dart code for Aura conventions, layering, and known pitfalls
- `cloud-functions-validator` — Validates agent files against the 10-step pattern and known JS error patterns

## Dissertation Rules

When assisting with dissertation-related writing, do NOT mention or include the following topics unless the user explicitly requests them:
- RevenueCat
- Payment functions / in-app purchases
- Uploading / publishing to Google Play Store or Apple App Store

## Run Commands

```bash
flutter pub get                          # Install Dart dependencies
cd functions && npm install              # Install Cloud Function dependencies
flutter run                              # Run the app (requires Firebase configured)
flutter analyze                          # Static analysis
dart format .                            # Format all Dart files
flutter test                             # Run tests
cd functions && npm test                 # Run Cloud Function tests
firebase deploy --only functions         # Deploy Cloud Functions
firebase deploy --only firestore:rules   # Deploy security rules
```
