---
paths:
  - "functions/**/*.js"
  - "firestore.rules"
  - "firestore.indexes.json"
  - "firebase.json"
  - "lib/services/**/*.dart"
---

# Firebase & Firestore Conventions for Aura

## Firestore Data Structure

```
users/{userId}                             — User profile
  habits/{habitId}                         — Habit documents
    history/{YYYY-MM-DD}                   — Completion records (immutable)
  dailyReviews/{YYYY-MM-DD}               — AI daily reviews
  habitScores/{habitId}/history/{YYYY-MM-DD} — AI score history (immutable)
  healthCorrelations/{id}                  — Health analysis results
  usageCounters/{type_period}             — Rate limiting (server-write only)
```

## Firestore Patterns

- **Timestamps**: Use `FieldValue.serverTimestamp()` for write timestamps, never `DateTime.now()`
- **Date conversion**: `Timestamp.fromDate()` to write, `.toDate()` to read
- **Date doc IDs**: Format as `YYYY-MM-DD` string
- **Partial updates**: Use `SetOptions(merge: true)` for fields that should not overwrite the full document
- **Batch writes**: Chunk at 400 documents (Firestore limit is 500 per batch)
- **Auth safety**: Always check `_userId != null` before any Firestore operation
- **Null handling**: Use `data?['field']` pattern when reading documents that may not exist

## Security Rules Principles

- **User isolation**: `request.auth.uid == userId` — users can only access their own data
- **Input validation**: Habits require valid name (1-100 chars) and category from whitelist
- **Immutability**: History records (completion, scores) can be created and deleted but NOT updated
- **Server-only**: `usageCounters` collection is write-only for admin SDK (Cloud Functions)
- **Default deny**: All unmatched paths return denied

## Cloud Functions Registration

- AI agents: registered in `index.js` via `onCall()` wrapper with `{ secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 }`
- Scheduled functions: use `onSchedule()` wrapper
- Global options set in `index.js`: region `us-central1`, maxInstances 10, timeout 60s default
- Secrets managed via `defineSecret()` in helpers.js — never hardcode

## Firebase Auth

- Supported methods: Email/Password, Google Sign-In, Apple Sign-In
- Auth state managed via `FirebaseAuth.instance.authStateChanges()` stream in main.dart
- User creation: `FirestoreService.createUserIfNotExists()` called on provider init
- Account deletion: Batch deletes all subcollections before deleting auth user
