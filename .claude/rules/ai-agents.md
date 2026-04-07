---
paths:
  - "functions/agents/**/*.js"
  - "functions/helpers.js"
  - "functions/index.js"
---

# AI Agent Conventions (Cloud Functions)

## Agent Architecture

Each agent in `functions/agents/` follows an identical 10-step pattern:

```
1. Auth check (request.auth)
2. Burst limit check (checkBurstLimit)
3. Subscription tier lookup (getUserTier)
4. Usage limit check (checkUsageLimit)
5. Input validation (validateString, validateNumber, validateCategory, validateArray)
6. Prompt sanitization (sanitizeForPrompt) and construction
7. Gemini API call (model: "gemini-3-flash-preview")
8. Response parsing (parseGeminiJSON — strips markdown fences)
9. Output validation (whitelist enums, clamp numbers, truncate strings)
10. Usage recording (recordUsage)
```

All helper functions are imported from `../helpers.js`.

## Current Agents (9 total)

| Agent | Purpose |
|-------|---------|
| generateHabitSuggestions | AI habit recommendations based on user profile |
| generateWeeklyInsights | Weekly summary and performance analysis |
| generatePatternDiscovery | Detect patterns in completion data |
| generateHabitTips | Category-based evidence-based tips |
| generateActionItems | Personalized action items |
| generateHabitScore | Score habit across 4 dimensions (Consistency 40%, Momentum 25%, Resilience 20%, Engagement 15%) |
| generateDailyReview | Daily performance review and summary |
| generateHabitInsight | Single habit deep AI insight |
| generateHealthCorrelations | Health-habit correlation analysis |

## Adding a New Agent

1. Create `functions/agents/generateXxx.js` following the 10-step pattern
2. Import and register in `functions/index.js` using `onCall()` wrapper
3. Add secrets config: `{ secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 }`
4. Create corresponding Dart model in `lib/models/` with `toJson()`/`fromJson()`
5. Add Cloud Function call in the relevant provider via `FirebaseFunctions.instance.httpsCallable()`
6. Match the bilingual comment header style of existing agents

## Prompt Guidelines

- Use `sanitizeForPrompt()` on ALL user-provided strings before embedding in prompts
- Request JSON output in the prompt — never request markdown
- Always specify exact JSON keys and value types in the prompt
- Include user performance context (streaks, completion rates) for personalization
- Add behavioral psychology framing for habit-related prompts
- Keep prompts focused — one clear task per agent

## Output Validation (Critical)

- **Whitelist enums**: Only accept known category/status values, map unknowns to defaults
- **Clamp numbers**: Always clamp scores to 0-100 range
- **Truncate strings**: Enforce max lengths on all text fields
- **Handle failures**: Empty/null Gemini responses must return a sensible default, not crash
- **Never pass raw AI output** to the client without validation

## Constants (from helpers.js)

- **Valid categories**: health, learning, productivity, mindfulness, fitness
- **Tier limits**: starter (3 suggestions/day, 20 reports/month), growth (5/30), mastery (unlimited)
- **Burst limit**: Prevents rapid-fire calls from the same user
