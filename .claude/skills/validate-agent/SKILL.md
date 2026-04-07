---
name: validate-agent
description: Validate Cloud Functions AI agents against the 10-step pattern from ai-agents.md
---

# Validate AI Agent

Validate one or all Cloud Functions agents against the documented 10-step pattern.

## Usage

- With argument (agent name): validate that specific agent, e.g. `generateHabitScore`
- Without argument: validate ALL 9 agents in `functions/agents/`

## Validation Steps

For each agent file, check for the presence and correctness of all 10 steps:

| Step | Check | Grep Pattern |
|------|-------|-------------|
| 1. Auth check | `request.auth` exists | `request\.auth` |
| 2. Burst limit | `checkBurstLimit` called | `checkBurstLimit` |
| 3. Tier lookup | `getUserTier` called | `getUserTier` |
| 4. Usage limit | `checkUsageLimit` called | `checkUsageLimit` |
| 5. Input validation | At least one `validate*` call | `validateString\|validateNumber\|validateCategory\|validateArray` |
| 6. Sanitization | `sanitizeForPrompt` used | `sanitizeForPrompt` |
| 7. Gemini call | Correct model string | `gemini-3-flash-preview` |
| 8. Response parse | `parseGeminiJSON` called | `parseGeminiJSON` |
| 9. Output validation | Clamping/whitelist/truncate present | `Math.max\|Math.min\|Math.round\|substring\|slice\|includes` |
| 10. Usage recording | `recordUsage` called | `recordUsage` |

## Additional Checks

### Empty Response Guard
Every agent MUST check for empty Gemini responses before `parseGeminiJSON`:
```
if (!text || text.trim().length === 0)
```
Flag any agent missing this check.

### Error Type Consistency
All thrown errors should use `HttpsError`, not plain `Error`:
```bash
grep -n "throw new Error" functions/agents/*.js
```
Any matches are violations.

### Registration in index.js
Read `functions/index.js` and verify the agent is exported.

### Bilingual Header
Check first 5 lines for the bilingual comment block format.

### Known Bug Patterns (from errors.md)
- `Number(x) || null` — falsy zero bug (should use explicit `!= null` check)
- `parsed.breakdown` accessed without defaulting parent object
- Missing `const breakdown = parsed.breakdown || {}` pattern

## Output Format

Report as a table per agent:
```
=== generateHabitScore ===
Step 1 (Auth):        PASS
Step 2 (Burst):       PASS
...
Step 10 (Record):     PASS
Empty response guard: PASS
Error types:          PASS
Registered:           PASS
Header:               PASS
---
Overall: 13/13 PASS
```

At the end, show a summary: `X/9 agents fully compliant`
