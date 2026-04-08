# Known Errors & Lessons Learned

This file serves as a self-reinforcement log for Claude Code. When an error is encountered
and resolved, record it here so the same mistake is never repeated.

Format: Each entry has the error, root cause, and fix. Newest entries at the top.

---

## How to Use This File

**When you encounter an error during this session:**
1. Diagnose the root cause
2. Fix the issue
3. Append an entry to this file using the template below

**Template:**
```
### [YYYY-MM-DD] Brief error description
- **Error**: The exact error message or symptom
- **Root cause**: Why it happened
- **Fix**: What resolved it
- **Prevention**: How to avoid it in the future
```

---

## Error Log

### [2026-04-08] Pre-commit hook fails due to unformatted Dart files
- **Error**: `ERROR: These files need formatting: lib/providers/ai_coach_provider.dart` etc. Commit rejected by pre-commit hook
- **Root cause**: Edited Dart files without running `dart format` before committing. The project has a pre-commit hook that checks formatting
- **Fix**: Ran `dart format` on the flagged files, re-staged, and committed again as a NEW commit (not amend)
- **Prevention**: Always run `dart format` on modified Dart files before committing. After a formatting failure, re-stage and create a new commit — never amend, as the failed commit didn't actually happen

### [2026-04-07] Falsy zero converts health metrics to null in Cloud Functions
- **Error**: `Number(healthData.avgSteps) || null` converts legitimate `0` values to `null` because `0` is falsy in JavaScript. Users with 0 steps/sleep see "N/A" instead of "0"
- **Root cause**: Used `||` operator which treats `0` as falsy, falling through to `null`
- **Fix**: Replaced with explicit null check: `healthData.avgSteps != null ? Number(healthData.avgSteps) : null` in generateHabitScore.js and generateDailyReview.js
- **Prevention**: Never use `Number(x) || fallback` when `0` is a valid value. Always use explicit `!= null` checks for numeric conversions

### [2026-04-07] macOS entitlements missing network.client — Firebase fails silently
- **Error**: All Firebase/Firestore/HTTP calls fail on macOS because sandbox blocks outgoing network requests
- **Root cause**: DebugProfile.entitlements had `network.server` (incoming, wrong) instead of `network.client` (outgoing). Release.entitlements had no network access at all
- **Fix**: Added `com.apple.security.network.client` to both entitlement files. Replaced `network.server` with `network.client` in DebugProfile
- **Prevention**: When adding Firebase to a macOS Flutter app, always add `network.client` entitlement. macOS sandbox blocks all network by default

### [2026-04-07] ProgressProvider daysTracked fix from errors.md not applied
- **Error**: New users see "1 day tracked" instead of "0" — the fix documented in errors.md was never actually applied to the code
- **Root cause**: The `daysTracked > 0 ? daysTracked : 1` default was logged as fixed but the code still had `1`
- **Fix**: Changed default from `1` to `0` in progress_provider.dart
- **Prevention**: After documenting a fix in errors.md, always verify the code change was actually saved. Use grep to confirm

### [2026-04-07] ProgressScreen missing mounted check in addPostFrameCallback
- **Error**: If user navigates away before the post-frame callback fires, `_animationController.forward()` throws "disposed" error
- **Root cause**: No `mounted` guard in `addPostFrameCallback` in progress_screen.dart
- **Fix**: Added `if (!mounted) return;` as first line of the callback
- **Prevention**: ALWAYS check `mounted` in addPostFrameCallback, Timer callbacks, or any deferred execution that accesses context or controllers

### [2026-04-07] Empty habitName passes validation to Gemini AI agents
- **Error**: `validateString('   ', 'habitName', 100)` returns `''` — empty habit names reach Gemini prompts, degrading AI response quality
- **Root cause**: `validateString()` in helpers.js trims input but doesn't reject empty strings after trimming. Optional fields (deviceInfo, category) legitimately use empty strings
- **Fix**: Added `if (!habitName)` empty checks at call sites in generateHabitScore.js and generateHabitInsight.js rather than changing the shared helper (which would break optional fields)
- **Prevention**: For required string fields in AI agents, always add an explicit empty check after `validateString`. Don't rely on validateString alone for required fields

### [2026-04-07] Weekly habits without weeklyDays array counted in daily summary
- **Error**: When `frequencyType === 'weekly'` but `weeklyDays` is missing/null, the habit is incorrectly counted as due today, inflating notification counts
- **Root cause**: Guard condition `data.frequencyType === 'weekly' && Array.isArray(data.weeklyDays)` fails the Array.isArray check, so the continue is never reached
- **Fix**: Changed to `if (data.frequencyType === 'weekly') { if (!Array.isArray(data.weeklyDays) || !data.weeklyDays.includes(...)) continue; }`
- **Prevention**: When filtering by a type-specific field, always handle the case where the field is missing/malformed — don't AND the type check with the field check

### [2026-04-07] fcmTokens not validated as array in sendDailySummaries
- **Error**: If Firestore has corrupted `fcmTokens` data (string, number), `userData.fcmTokens || []` passes the `||` check and `.length` works on strings, but array operations break
- **Root cause**: Used `||` fallback without type validation
- **Fix**: Changed to `Array.isArray(userData.fcmTokens) ? userData.fcmTokens : []`
- **Prevention**: When reading array fields from Firestore, always use `Array.isArray()` check, not just `||` fallback

### [2026-04-07] Dead UTC+8 timezone fallback in sendDailySummaries
- **Error**: Unreachable UTC+8 fallback code on line 74-77 — timezone was already validated on line 53. If it ever DID execute, notifications would arrive at wrong time
- **Root cause**: Defensive try-catch added around already-validated timezone parse, with dangerous hardcoded UTC+8 fallback
- **Fix**: Removed the try-catch wrapper and UTC+8 fallback since timezone is already validated before the user enters the matching list
- **Prevention**: Don't add fallback logic around operations that use already-validated inputs. If validation passed earlier, trust it

### [2026-04-07] AICoachProvider clearUserData — cache removals not individually guarded
- **Error**: All 5 `prefs.remove()` calls in one try-catch — if the first throws, remaining cache keys are never cleared, violating cleanup atomicity principle
- **Root cause**: Same pattern as the provider logout bug (errors.md entry from 2026-03-29) — one failure blocks the rest
- **Fix**: Wrapped each `prefs.remove()` in its own try-catch using a loop
- **Prevention**: Cleanup/teardown code must use individual try-catch per operation. This applies to both provider cleanup and cache cleanup

### [2026-04-07] .gitignore missing private key file patterns
- **Error**: No exclusion for `*.pem`, `*.p8`, `*.p12` files — private keys/certificates could accidentally be committed
- **Root cause**: Defense-in-depth patterns not added when repo was set up
- **Fix**: Added `*.pem`, `*.p8`, `*.p12` to the "Local Environment & Secrets" section
- **Prevention**: When setting up a project, include all common secret file patterns in .gitignore even if they don't exist yet

### [2026-04-07] Help support form TextField missing maxLength
- **Error**: Form fields in help_support_sheets.dart have no client-side character limit, letting users type unlimited text. Server rejects at 5000 chars but wastes bandwidth
- **Root cause**: `maxLength` property not set on TextField widget
- **Fix**: Added `maxLength: 2000` to the `_buildFormField()` TextField
- **Prevention**: All user-facing text inputs should have `maxLength` matching or below the server-side limit

### [2026-03-29] bash-safety hook: rm -rf / not blocked at end-of-string
- **Error**: `rm -rf /` (with `/` at end of input, no trailing space/delimiter) was not blocked by the safety hook
- **Root cause**: Regex pattern expected `/` followed by `\s`, `;`, `&&`, or `|` — but not end-of-string `$`
- **Fix**: Added `$` as alternative in the character group: `/($|\s|;|&&|\|)`
- **Prevention**: When writing regex for command blocking, always include `$` (end-of-string) alongside delimiter alternatives

### [2026-03-29] SharedPreferences badge key collision between BadgeService and SettingsProvider
- **Error**: BadgeService used key `'badge_enabled'` while SettingsProvider used `'badgeEnabled'` for the same concept. Two independent copies of the same setting stored separately
- **Root cause**: No centralized key registry. Two developers/sessions independently chose different naming conventions
- **Fix**: Changed BadgeService key to `'badgeEnabled'` to match SettingsProvider
- **Prevention**: SharedPreferences keys should be centralized in one place or at minimum use consistent naming. When adding a new key, search for existing keys with similar names

### [2026-03-29] generateHabitScore.js missing empty Gemini response check
- **Error**: Unlike 8 other agents, generateHabitScore.js didn't check for empty text before parseGeminiJSON. Empty response gave generic "invalid response" error instead of specific "empty response"
- **Root cause**: Missed during the first-pass fix that added empty checks to 7 agents — generateHabitScore.js was thought to already have it
- **Fix**: Added `if (!text || text.trim().length === 0)` check before parseGeminiJSON
- **Prevention**: When applying the same fix to multiple files, verify ALL files are covered with a grep count check after: `grep -l "text.trim().length === 0" functions/agents/*.js | wc -l` should equal total agent count

### [2026-03-29] Home screen context access without mounted check
- **Error**: `_setupAIPreloading()` called in addPostFrameCallback accesses context without checking mounted. Crashes if widget disposed between frames
- **Root cause**: Missing `mounted` guard in post-frame callback
- **Fix**: Added `if (!mounted) return;` as first line
- **Prevention**: ALWAYS check `mounted` before accessing `context` in addPostFrameCallback, Timer callbacks, or any async gap

### [2026-03-29] Concurrent habit save on rapid double-tap
- **Error**: Two rapid taps on Save button can both pass the `_isSaving` check before the flag is set
- **Root cause**: `_isSaving` was set after `_validateForm()`, leaving a window for concurrent calls
- **Fix**: Added `if (_isSaving) return;` as the very first line of `_saveHabit()`, before validation
- **Prevention**: Guard flags must be checked AND set at the very top of async methods, before any other logic

### [2026-03-29] Completion toggle race condition on rapid tapping
- **Error**: Rapid toggle taps can bypass `_isToggling` check in `completeHabit()`
- **Root cause**: Although `_isToggling` was set, UI wasn't notified to disable the button before async work
- **Fix**: Added `_safeNotifyListeners()` immediately after setting `_isToggling = true` to update UI before async
- **Prevention**: When using boolean flags to guard async operations, always notify listeners immediately after setting the flag so UI reflects the disabled state

### [2026-03-29] Empty/whitespace name accepted in profile editing
- **Error**: User can save blank first/last name in profile, breaking display
- **Root cause**: Name fields not trimmed or validated before `updateProfile()` call
- **Fix**: Added `.trim()` on both name fields and empty check on firstName with SnackBar error
- **Prevention**: Always trim and validate all text inputs before saving. Empty string checks on required fields

### [2026-03-29] Unbounded goal value allows extremely large numbers
- **Error**: Goal value TextField accepts any integer size (999999999), breaking UI
- **Root cause**: `int.tryParse(val)` used without bounds checking
- **Fix**: Added `parsed > 0 && parsed <= 9999` validation in onChanged
- **Prevention**: All numeric inputs from users must have min/max bounds validated

### [2026-03-29] Support message submissions have no rate limiting
- **Error**: Users can spam support messages with no throttle or length limit
- **Root cause**: No cooldown between submissions, no maxLength on message body
- **Fix**: Added 5-second cooldown (`_lastSubmitTime`), 2000 character message limit, applied to all 3 support form types
- **Prevention**: All user-facing submission forms need rate limiting (cooldown) and input length limits

### [2026-03-29] Chart interval can be 0 causing fl_chart issues
- **Error**: `(trendData.length / 5).ceilToDouble()` can produce 0.0 for edge cases, confusing chart rendering
- **Root cause**: No minimum value enforced on chart interval
- **Fix**: Wrapped with `math.max(1.0, ...)` to ensure interval >= 1
- **Prevention**: Chart interval/step values must always be >= 1.0. Use `max()` wrapper on all calculated chart parameters

### [2026-03-29] Account deletion without re-authentication
- **Error**: Delete account only shows confirmation dialog, no password re-auth. Firebase throws `requires-recent-login` if session is stale
- **Root cause**: No handling for Firebase's re-authentication requirement
- **Fix**: Added typed `FirebaseAuthException` catch with `requires-recent-login` code check, showing user-friendly "Please log out and log back in" message
- **Prevention**: Any destructive Firebase Auth operation (delete, email change) must handle `requires-recent-login`. Show re-auth UI or instruct user to re-login

### [2026-03-29] CSV formula injection in export
- **Error**: Habit names starting with `=`, `+`, `-`, `@` are exported as formulas in CSV. Excel executes them (remote code execution)
- **Root cause**: `_escapeCSV()` only handled quotes/commas/newlines, not formula characters
- **Fix**: Prefix formula characters with single quote `'` at the start of `_escapeCSV()`
- **Prevention**: Any user-controlled string written to CSV must be formula-escaped. Check for `=+\-@\t\r` prefixes

### [2026-03-29] Provider logout cleanup skips remaining providers on exception
- **Error**: If any provider's `clearUserData()` throws, remaining providers and services are never cleaned, causing cross-user data leaks
- **Root cause**: All cleanup calls were in a single try block. One exception aborted the rest
- **Fix**: Wrapped each provider/service cleanup in its own try-catch using a loop, so all are always attempted
- **Prevention**: Cleanup/teardown code must NEVER let one failure block others. Always use individual try-catch per resource

### [2026-03-29] Splash screen Firebase init fails silently
- **Error**: If Firebase.initializeApp() throws, app still transitions to main screen with broken Firebase, causing cryptic crashes
- **Root cause**: Exception caught and debug-printed, but `_initComplete = true` set unconditionally
- **Fix**: Don't set `_initComplete` on error. Show retry UI with error message and Retry button
- **Prevention**: Fatal initialization errors must block app progression and show user-actionable error UI, never silently continue

### [2026-03-29] Streak calculation breaks at midnight due to timezone
- **Error**: At midnight, `DateTime.now()` rolls to next day while `lastCompletedDate` is still "yesterday". Streak resets instantly
- **Root cause**: Date comparison used `date_utils.isToday()` which may not handle the local/UTC boundary correctly
- **Fix**: Explicit `.toLocal()` conversion and year/month/day comparison in both `_isCompletedToday()` and `_wasCompletedYesterday()`
- **Prevention**: All date comparisons for "today"/"yesterday" must explicitly convert to local time and compare year/month/day individually

### [2026-03-29] AIScoringProvider blocks all habit scores with one in-progress key
- **Error**: Scoring Habit A blocks Habit B from being scored because both use generic `'score'` key in `_inProgressOps`
- **Root cause**: Used single key for all habits instead of per-habit keys
- **Fix**: Changed to `'score_${habit.id}'` for contains/add/remove operations
- **Prevention**: When using in-progress operation tracking, always use per-entity keys if the operation is entity-specific

### [2026-03-29] Daily review can be generated multiple times per day
- **Error**: No guard against generating duplicate daily reviews for the same date, wasting API calls and creating duplicate Firestore records
- **Root cause**: Only checked if review generation was in-progress, not if today's review already existed
- **Fix**: Added date comparison guard: if `_todaysReview?.date == todayStr`, return existing review instead of calling Cloud Function
- **Prevention**: For once-per-period operations (daily review, weekly insights), always check if the period's result already exists before making API calls

### [2026-03-29] ProgressProvider "All Time" only shows 90 days
- **Error**: getHabitHistory() defaults to 90 days. "All Time" view shows incomplete historical data
- **Root cause**: Hard-coded 90-day limit in `_fetchAllHistory()` regardless of selected date range
- **Fix**: Calculate `limitDays` from selected range start date, use max of calculated days and 90
- **Prevention**: When fetching data for user-selectable time ranges, dynamically calculate the fetch window from the selected range

### [2026-03-29] Missing iOS HealthKit entitlement
- **Error**: App declares health usage descriptions in Info.plist but has no HealthKit entitlement file. Health features completely broken on iOS
- **Root cause**: `Runner.entitlements` file was never created
- **Fix**: Created `ios/Runner/Runner.entitlements` with `com.apple.developer.healthkit` entitlement. Note: must also be wired up in Xcode
- **Prevention**: When adding platform capabilities (health, notifications, payments), always create BOTH the Info.plist entries AND the entitlements file

### [2026-03-29] iOS missing remote-notification background mode
- **Error**: FCM push notifications may not arrive when app is backgrounded because `remote-notification` background mode was missing
- **Root cause**: `UIBackgroundModes` only had `processing`, not `remote-notification`
- **Fix**: Added `remote-notification` to `UIBackgroundModes` array in Info.plist
- **Prevention**: Firebase Cloud Messaging requires `remote-notification` in UIBackgroundModes. Always add it alongside FCM setup

### [2026-03-29] Missing Health Connect ProGuard rules for Android release builds
- **Error**: Health Connect API could silently fail in release builds because R8 obfuscation breaks reflection
- **Root cause**: No ProGuard keep rules for health package classes
- **Fix**: Added keep rules for `androidx.health.connect.**` and `com.google.android.libraries.healthdata.**`
- **Prevention**: When adding packages that use reflection or JNI (health, payments, analytics), always add corresponding ProGuard rules

### [2026-03-29] flutter_timezone pinned without caret — won't get patches
- **Error**: `flutter_timezone: 5.0.1` won't receive patch updates (security fixes, bug fixes)
- **Root cause**: Missing `^` caret in version constraint
- **Fix**: Changed to `flutter_timezone: ^5.0.1`
- **Prevention**: Use `^` caret for all dependencies unless there's a specific reason to pin

### [2026-03-29] Missing Firestore composite indexes — queries fail in production
- **Error**: Queries using `orderBy` on subcollections (dailyReviews, habitScores/history, healthCorrelations) fail with "The query requires an index" in production
- **Root cause**: `firestore.indexes.json` was empty (`"indexes": []`). Firestore auto-creates indexes for top-level collections but not always for subcollection group queries or complex range filters
- **Fix**: Added composite indexes for dailyReviews (date DESC), history (date DESC), healthCorrelations (savedAt DESC)
- **Prevention**: When adding a new Firestore query with `orderBy` or `where` on a subcollection, always add the corresponding index to `firestore.indexes.json` and deploy with `firebase deploy --only firestore:indexes`

### [2026-03-29] Missing field validation in Firestore security rules
- **Error**: Client could write arbitrary values for `healthIntegrationEnabled` (non-boolean), `reminderHour` (>23), `reminderMinute` (>59) without server-side validation
- **Root cause**: `isValidHabit()` only validated name and category. User document update rule only blocked protected fields but didn't validate value types
- **Fix**: Extended `isValidHabit()` to validate reminderHour (0-23) and reminderMinute (0-59) when present. Added `isValidUserUpdate()` helper that validates `healthIntegrationEnabled` as boolean
- **Prevention**: When adding a new writable field to a Firestore document, always add corresponding validation to the security rules. Field-level validation is the last line of defense

### [2026-03-29] Dead code after refactor — ThemeProvider._loadThemeMode()
- **Error**: `_loadThemeMode()` method remained in ThemeProvider after theme pre-loading was moved to `main()`. Dead code increases maintenance burden
- **Root cause**: When fixing the theme flash bug, the constructor was changed to accept `initialMode` but the old async loading method was left behind
- **Fix**: Removed the unused `_loadThemeMode()` method
- **Prevention**: When refactoring initialization from async-in-constructor to pre-loaded parameter, always remove the old async method to avoid dead code

### [2026-03-29] Services not cleaned up on logout — cross-user data leak
- **Error**: BadgeService badge count and SubscriptionService AI quotas persisted across different users after logout/login
- **Root cause**: `_clearAllProviderData()` in main.dart only cleared providers, not singleton services. `BadgeService.resetOnLogout()` and `SubscriptionService.logoutUser()` were never called
- **Fix**: Added `BadgeService().resetOnLogout()` and `SubscriptionService().logoutUser()` to `_clearAllProviderData()` in main.dart
- **Prevention**: When adding a singleton service with user-specific state, always add its cleanup to the logout flow in `_clearAllProviderData()`

### [2026-03-29] SharedPreferences pre-load crash — no try-catch in main()
- **Error**: If `SharedPreferences.getInstance()` throws (rare, but possible on some devices), the app crashes on startup with no recovery
- **Root cause**: The theme pre-load added to `main()` had no error handling around the SharedPreferences call
- **Fix**: Wrapped in try-catch with fallback to `ThemeMode.light`
- **Prevention**: Any code in `main()` before `runApp()` must be wrapped in try-catch. A crash here is unrecoverable

### [2026-03-29] sendDailySummaries — TOCTOU race sends duplicate notifications
- **Error**: Two parallel scheduled function executions could both read `lastDailySummaryDate !== today`, both pass the guard, and both send notifications to the same user
- **Root cause**: The duplicate check (read) and the date update (write) were separate non-atomic Firestore operations
- **Fix**: Replaced with `db.runTransaction()` that atomically checks and sets `lastDailySummaryDate`, returning false if already set
- **Prevention**: Any check-then-act pattern on shared data must use Firestore transactions. Non-transactional reads followed by writes are ALWAYS race-prone in Cloud Functions

### [2026-03-29] generateHabitScore — missing breakdown field defaults
- **Error**: If Gemini returns `breakdown: null` or omits it entirely, `parsed.breakdown?.consistency` returns undefined, and `validateBreakdown(undefined)` creates `{score: 0, analysis: ''}` — but the Dart client may not handle missing top-level breakdown object
- **Root cause**: No explicit fallback for `parsed.breakdown` being null/undefined before accessing sub-fields
- **Fix**: Added `const breakdown = parsed.breakdown || {};` so all four fields always exist even if Gemini omits the breakdown entirely
- **Prevention**: When validating AI output, always default parent objects before accessing nested fields. Use `const obj = parsed.x || {}` pattern

### [2026-03-29] Burst limit — negative time permanently rate-limits user
- **Error**: If server clock skew makes `lastRequest` timestamp in the future, `Date.now() - lastRequest.getTime()` becomes negative, which is always `< cooldownMs`, permanently blocking the user
- **Root cause**: No check for negative time difference in burst limit calculation
- **Fix**: Added `timeSinceLastRequest >= 0 &&` guard so negative values (clock skew) are treated as expired
- **Prevention**: When comparing timestamps from different sources (client vs server), always handle negative differences as expired/invalid

### [2026-03-29] login_screen FormState force unwrap crash
- **Error**: `_formKey.currentState!.validate()` force unwrap could crash if FormState is null in edge cases (widget tree rebuild, hot reload)
- **Root cause**: Used `!` operator instead of null-safe access
- **Fix**: Replaced with `final formState = _formKey.currentState; if (formState == null || !formState.validate()) return;`
- **Prevention**: Never use `!` on `.currentState` — always null-check first. This applies to all GlobalKey.currentState, GlobalKey.currentContext, etc.

### [2026-03-29] Account deletion — Firestore data orphaned on partial failure
- **Error**: If `user.delete()` succeeds but `deleteAllUserData()` fails, user auth is gone but Firestore data remains forever
- **Root cause**: No try-catch between the two-step delete in `settings_provider.dart`. The second step was not wrapped for independent failure handling
- **Fix**: Wrapped Firestore delete in separate try-catch. If it fails after auth delete, logs a warning with userId for manual cleanup instead of throwing
- **Prevention**: When doing multi-step destructive operations, always handle each step independently. If step 1 is irreversible, step 2 must be best-effort with error logging

### [2026-03-29] AICoachProvider — corrupted cache causes repeated failures
- **Error**: If SharedPreferences contains corrupted JSON for suggestions, every app restart retries the same bad cache, falls through to API call each time
- **Root cause**: The catch block at line 302 logged the error but never removed the corrupted cache entry
- **Fix**: Added `prefs.remove(_suggestionsCacheKey)` in the catch block to clear bad data
- **Prevention**: When catching cache parse errors, always remove the corrupted entry. Never leave bad data in persistent storage expecting it to fix itself

### [2026-03-29] ThemeProvider — flash of light theme on startup
- **Error**: Users who saved dark mode see a brief flash of light theme every time the app launches
- **Root cause**: ThemeProvider constructor called async `_loadThemeMode()` without await. First build used default `ThemeMode.light` before SharedPreferences loaded
- **Fix**: Pre-load theme synchronously in `main()` via `SharedPreferences.getInstance()` before `runApp()`, pass `initialThemeMode` to MyApp and ThemeProvider
- **Prevention**: Any user preference that affects initial render (theme, locale, font size) must be loaded BEFORE runApp, not asynchronously in a provider constructor

### [2026-03-29] Cloud Functions — empty Gemini response crashes agents
- **Error**: If Gemini API returns empty content, `parseGeminiJSON('')` crashes with `JSON.parse('')` error. Only 2 of 9 agents checked for empty text
- **Root cause**: Most agents called `parseGeminiJSON(response.text())` directly without verifying the response was non-empty
- **Fix**: Added `if (!text || text.trim().length === 0)` check before `parseGeminiJSON()` in all 7 missing agents, throwing `HttpsError("internal", "AI service returned empty response")`
- **Prevention**: ALWAYS check for empty/null responses from external APIs before parsing. Add the check to every new agent created

### [2026-03-29] parseGeminiJSON — error details swallowed
- **Error**: When Gemini returns malformed JSON, developers see only "AI returned invalid response" with no details about what was actually returned
- **Root cause**: The catch block in `parseGeminiJSON()` threw a generic error without logging the raw input
- **Fix**: Added `console.error('parseGeminiJSON failed:', e.message, '| Raw input (first 500 chars):', jsonStr.substring(0, 500))` before the throw
- **Prevention**: When catching parse/validation errors from external services, always log the raw input (truncated) for debugging. Generic error messages to users are fine, but developers need the details in logs

### [2026-03-29] ProgressProvider — daysTracked defaults to 1 instead of 0
- **Error**: New users with no completions see "1 day tracked" instead of "0 days tracked"
- **Root cause**: `daysTracked` was initialized to `1` as a default, but should be `0` when there's no tracking history
- **Fix**: Changed default from `1` to `0`. The value is correctly set to `now.difference(firstDate).inDays + 1` when `uniqueDates.isNotEmpty`
- **Prevention**: Default values for counters/statistics should always be 0, not 1. Only set non-zero defaults when there's a mathematical reason (e.g., avoiding division by zero)

### [2026-03-29] ProgressProvider — getTrendChange returns 100% for 0 to N
- **Error**: Going from 0 completions to any number shows "100% improvement" regardless of actual amount. 0→1 and 0→50 both show 100%
- **Root cause**: When `firstHalfAvg == 0`, the formula returned `100.0` if `secondHalfAvg > 0`. This is mathematically undefined (division by zero) disguised as a constant
- **Fix**: Changed to return `0.0` when `firstHalfAvg == 0` — no baseline means no meaningful trend comparison
- **Prevention**: When calculating percentage change, handle the zero-baseline case explicitly. Don't invent a number — return 0 or N/A

### [2026-03-29] sendDailySummaries — timezone fallback hardcoded to UTC+8
- **Error**: Users with unparseable timezone strings receive notifications at wrong times (based on UTC+8 guess)
- **Root cause**: The catch block for timezone parsing fell back to UTC+8, assuming most users are in East Asia
- **Fix**: Changed to skip the user entirely with a warning log instead of guessing wrong
- **Prevention**: Never guess timezone. If timezone is unknown, skip the time-sensitive operation and log it. Wrong-time notifications are worse than no notification

### [2026-03-29] HabitDetailProvider — stale AI insight overwrites new habit
- **Error**: If user switches from habit A to habit B quickly, the AI insight load for habit A may complete and overwrite habit B's data
- **Root cause**: `_loadAIInsight()` was fire-and-forget with no check that the current habit still matched when the response arrived
- **Fix**: Added `_loadingInsightForHabitId` field. On AI response, check `if (_habit?.id != _loadingInsightForHabitId) return` before setting state
- **Prevention**: Any fire-and-forget async operation must capture the context (ID, version) at start and validate it still matches before applying results. This applies to all async loads tied to user-navigable state

### [2026-03-29] Cloud Functions — inconsistent error types (Error vs HttpsError)
- **Error**: Some agents threw `new Error(...)` instead of `new HttpsError(...)`. Generic Error doesn't map to HTTP status codes, giving clients unhelpful error messages
- **Root cause**: Copy-paste inconsistency across agent files
- **Fix**: Replaced all `throw new Error(...)` with `throw new HttpsError("internal", ...)` in generatePatternDiscovery, generateActionItems, generateHabitTips, generateHabitSuggestions
- **Prevention**: In Cloud Functions, ALWAYS use `HttpsError` for errors that reach the client. `Error` is for internal-only failures. Grep for `new Error(` periodically to catch drift

### [2026-03-29] Flutter/Dart not found in PATH
- **Error**: `command not found: flutter` and `dart not found` when running `flutter analyze` or `dart format`
- **Root cause**: Flutter SDK is not installed on this machine or is not in the shell PATH. The project was likely developed on a different machine.
- **Fix**: Cannot run flutter/dart CLI commands in this session. Verify changes manually or ask the user to run `flutter analyze` on their dev machine.
- **Prevention**: Before running flutter/dart commands, check `which flutter` first. If not found, skip and inform the user to run the verification locally.
