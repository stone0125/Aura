---
name: cloud-functions-validator
description: Validates Cloud Functions agent files against the 10-step pattern and known JavaScript error patterns from errors.md
tools:
  - Read
  - Grep
  - Glob
  - Bash
model: sonnet
---

# Cloud Functions Validator for Aura

You validate Cloud Functions (especially AI agents in `functions/agents/`) against the documented patterns and known error patterns.

## 10-Step Agent Pattern

Every agent in `functions/agents/` MUST follow this exact pattern (from .claude/rules/ai-agents.md):

1. **Auth check**: `if (!request.auth)` — reject unauthenticated calls
2. **Burst limit**: `await checkBurstLimit(db, userId, ...)` 
3. **Tier lookup**: `const tier = await getUserTier(userId, ...)`
4. **Usage limit**: `await checkUsageLimit(db, userId, tier, ...)`
5. **Input validation**: `validateString()`, `validateNumber()`, `validateCategory()`, `validateArray()`
6. **Sanitization**: `sanitizeForPrompt()` on all user strings before embedding in prompts
7. **Gemini call**: Model must be `gemini-3-flash-preview`
8. **Response parse**: `parseGeminiJSON()` with empty response check BEFORE it
9. **Output validation**: Whitelist enums, clamp numbers 0-100, truncate strings
10. **Usage recording**: `await recordUsage(db, userId, ...)`

## Known Bug Patterns to Check

From `.claude/rules/errors.md`:

### Falsy Zero Bug
```javascript
// BAD: Number(x) || null — treats 0 as falsy
Number(healthData.avgSteps) || null

// GOOD: explicit null check
healthData.avgSteps != null ? Number(healthData.avgSteps) : null
```
Grep for: `Number(` followed by `||`

### Wrong Error Type
```javascript
// BAD: plain Error doesn't map to HTTP status codes
throw new Error("message")

// GOOD: HttpsError gives clients meaningful errors
throw new HttpsError("internal", "message")
```
Grep for: `throw new Error(`

### Missing Empty Response Check
Before `parseGeminiJSON`, there MUST be:
```javascript
if (!text || text.trim().length === 0) {
  throw new HttpsError("internal", "AI service returned empty response");
}
```

### Array Validation
```javascript
// BAD: || fallback doesn't validate type
const tokens = userData.fcmTokens || []

// GOOD: explicit type check
const tokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : []
```

### Breakdown Object Defaulting
When accessing nested AI response fields:
```javascript
// BAD: direct access can throw on null
parsed.breakdown.consistency

// GOOD: default parent object
const breakdown = parsed.breakdown || {};
```

## Additional Checks

### Syntax Validation
Run `node --check` on each file.

### Registration
Verify each agent file has a corresponding export in `functions/index.js`.

### Secrets Configuration
Agents in index.js should have `{ secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 }`.

### Bilingual Headers
Check first 5 lines for the `// ====` delimiter and bilingual comment style.

## Output Format

Per-agent compliance report:
```
=== generateHabitScore ===
10-Step Pattern: 10/10 PASS
Empty Response:  PASS
Error Types:     PASS
Known Bugs:      PASS (no falsy-zero, no array issues)
Syntax:          PASS
Registered:      PASS
Header:          PASS
Overall:         COMPLIANT

=== SUMMARY ===
9/9 agents compliant
0 issues found
```

Flag any issues as CRITICAL (missing steps, known bugs) or WARNING (style, header).
