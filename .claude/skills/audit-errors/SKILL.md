---
name: audit-errors
description: Audit errors.md knowledge base — verify documented fixes were actually applied to the codebase
---

# Audit Error Fixes

Read `.claude/rules/errors.md` and verify that each documented fix was actually applied to the codebase. This catches regressions and "documented but not applied" bugs.

## Background

On 2026-04-07, the `daysTracked` fix was found documented in errors.md but never actually applied to the code. This skill exists to prevent that from happening again.

## Process

### 1. Parse errors.md
Read `.claude/rules/errors.md` and extract each entry's:
- Date
- Brief description
- Fix description
- File(s) affected (infer from context)

### 2. For Each Verifiable Entry

Try to verify the fix was applied by grepping the codebase. Examples:

| Fix Description | Verification |
|----------------|-------------|
| "Added `if (!mounted) return;`" | Grep for `mounted` in the referenced file |
| "Changed key to `'badgeEnabled'`" | Grep for the old key `badge_enabled` — should NOT exist |
| "Added `Math.max(1.0, ...)`" | Grep for `Math.max` in the chart code |
| "Wrapped each cleanup in try-catch" | Read the cleanup function and verify |
| "Added `Array.isArray()` check" | Grep for `Array.isArray` in the referenced function |

### 3. Classification

Classify each entry as:
- **VERIFIED** — Fix confirmed present in code
- **REGRESSION** — Fix was documented but code doesn't match (CRITICAL)
- **UNVERIFIABLE** — Can't confirm programmatically (e.g., UI changes, removed code)
- **OBSOLETE** — Referenced code no longer exists

### 4. Output

```
=== Errors.md Audit Report ===

Total entries: XX
Verified:      XX
Regressions:   XX  (CRITICAL — fixes documented but not applied!)
Unverifiable:  XX
Obsolete:      XX

--- REGRESSIONS (fix these!) ---
[2026-XX-XX] Description
  Expected: <what the fix should look like>
  Found: <what the code actually has>
  File: <path>

--- VERIFIED ---
[2026-XX-XX] Description — confirmed in <file>
...
```

### 5. Priority

Always report REGRESSIONS first — these are bugs hiding behind documentation that says they're fixed.
