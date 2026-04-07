---
name: deploy-functions
description: Deploy Firebase Cloud Functions with pre-flight validation checks
---

# Deploy Cloud Functions

Run a complete pre-flight validation and deployment workflow for Firebase Cloud Functions.

## Pre-flight Checks

Run ALL of these checks before deploying. Stop and report if any fail.

### 1. Syntax Validation
Run `node --check` on every JS file in `functions/`:
```bash
for f in functions/helpers.js functions/index.js functions/sendDailySummaries.js functions/submitSupportMessage.js functions/agents/*.js; do
  node --check "$f" || echo "FAIL: $f"
done
```

### 2. 10-Step Pattern Verification
For each agent in `functions/agents/`, verify these markers exist:
- `request.auth` (Step 1: Auth check)
- `checkBurstLimit` (Step 2)
- `getUserTier` (Step 3)
- `checkUsageLimit` (Step 4)
- `validateString` or `validateNumber` or `validateCategory` or `validateArray` (Step 5)
- `sanitizeForPrompt` (Step 6)
- `gemini-3-flash-preview` (Step 7: correct model)
- `parseGeminiJSON` (Step 8)
- `recordUsage` (Step 10)

Report any agents missing steps.

### 3. Secret Detection
Check for hardcoded secrets:
```bash
grep -rn "AIza\|sk-\|ghp_\|-----BEGIN" functions/ --include=*.js
```
If any matches found, STOP and report. Do NOT deploy.

### 4. Registration Check
Verify all agents in `functions/agents/` have a matching export in `functions/index.js`.

### 5. Empty Response Guards
Verify all agents check for empty Gemini responses before calling `parseGeminiJSON`:
```bash
grep -L "text.trim().length === 0\|!text\|text\.length === 0" functions/agents/*.js
```
Any files listed are missing the empty response check.

## Deployment

After all checks pass:
1. Show the user a summary of what will deploy
2. Ask for explicit confirmation
3. Run: `cd functions && npm install && cd .. && firebase deploy --only functions`
4. After deployment, check recent logs: `firebase functions:log --limit 10`

## On Failure

If any pre-flight check fails:
- Report exactly which check failed and which files
- Do NOT proceed with deployment
- Suggest specific fixes
