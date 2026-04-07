// =============================================================================
// generateActionItems.js — Action Items Generation Agent
// 行动项生成代理
//
// Analyzes the user's habit data, completion rate, and streaks to produce
// personalized daily, weekly, and challenge action items via Gemini AI.
//
// 分析用户的习惯数据、完成率和连续记录，通过 Gemini AI 生成
// 个性化的每日、每周和挑战行动项。
// =============================================================================

const {
  HttpsError,
  getGenAI,
  SchemaType,
  validateArray,
  validateNumber,
  sanitizeForPrompt,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  checkBurstLimit,
  VALID_CATEGORIES,
  validateGeminiResponse,
  parseGeminiJSON,
} = require("../helpers");

const RESPONSE_SCHEMA = {
  type: SchemaType.ARRAY,
  description: "5-7 personalized action items",
  items: {
    type: SchemaType.OBJECT,
    properties: {
      title: { type: SchemaType.STRING, description: "Specific actionable title" },
      description: { type: SchemaType.STRING, description: "Why this matters, 1-2 sentences" },
      type: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["daily", "weekly", "challenge"],
      },
      priority: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["high", "medium", "low"],
      },
      relatedHabit: { type: SchemaType.STRING, nullable: true, description: "Name of related habit or null" },
      relatedHabitId: { type: SchemaType.STRING, nullable: true, description: "Exact ID from [ID:xxx] tags in habit data, or null" },
      metric: { type: SchemaType.STRING, description: "Specific measurable target" },
    },
    required: ["title", "description", "type", "priority", "metric"],
  },
};

/**
 * Generate personalized action items based on user habit data.
 * 根据用户习惯数据生成个性化行动项。
 *
 * @param {Object} request - The callable function request (must include auth and data).
 * @returns {Array<Object>} Array of action item objects.
 */
async function generateActionItems(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'actions'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  const { habits, completionRate, bestStreak } = request.data || {};

  const validatedHabits = validateArray(habits || [], 'habits', 50);
  const rate = validateNumber(completionRate ?? 0, 'completionRate', 0, 100);
  const streak = validateNumber(bestStreak ?? 0, 'bestStreak', 0, 10000);

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

  const habitsDetail = validatedHabits.filter(h => h && typeof h === 'object').map(h =>
    `- [ID:${sanitizeForPrompt(h.id || '')}] ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): streak ${Number(h.streak) || 0}, ${h.completed ? 'completed' : 'incomplete'}`
  ).join('\n');

  // Build a lookup map for validating relatedHabitId in response
  const habitIdSet = new Set(validatedHabits.filter(h => h && h.id).map(h => h.id));

  const performanceTier = rate >= 80 ? 'High Performer' : rate >= 50 ? 'Developing' : 'Foundation Building';

  const prompt = `
    You are a behavioral coach creating personalized daily and weekly action items based on the user's actual habit data.

    USER PROFILE:
    - Performance tier: ${performanceTier}
    - Completion rate: ${rate.toFixed(1)}%
    - Best streak: ${streak} days
    - Active habits:
    ${habitsDetail || 'No habits yet'}

    Generate exactly 5-7 personalized action items:
    - 3 daily actions (things to do today)
    - 2 weekly actions (goals for this week)
    - 1-2 challenge actions (stretch goals)

    Each action must be:
    - Specific and measurable (not vague)
    - Based on the user's actual habits and performance
    - Achievable given their current level

    ${rate < 50 ? 'Focus on building consistency with micro-habits and reducing friction.' : ''}
    ${rate >= 80 ? 'Include advanced optimization and stretch goals.' : ''}
    ${streak < 3 ? 'Emphasize streak building and habit anchoring.' : ''}

    IMPORTANT: For relatedHabitId, use the exact ID value from the [ID:xxx] tags shown in the habit list above. If no habit is related, use null.

    Format as JSON array:
    [
      {
        "title": "<specific actionable title>",
        "description": "<why this matters, 1-2 sentences>",
        "type": "daily" | "weekly" | "challenge",
        "priority": "high" | "medium" | "low",
        "relatedHabit": "<name of related habit or null>",
        "relatedHabitId": "<ID from the habit data [ID:xxx] or null>",
        "metric": "<specific measurable target>"
      }
    ]
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    validateGeminiResponse(text, "generateActionItems");
    const parsed = parseGeminiJSON(text);

    const VALID_ACTION_TYPES = ['daily', 'weekly', 'challenge'];
    const VALID_PRIORITIES = ['high', 'medium', 'low'];
    if (!Array.isArray(parsed)) throw new HttpsError("internal", "Expected array");
    returnValue = parsed.filter(item => item && typeof item === 'object').slice(0, 10).map(item => ({
      title: String(item.title || '').substring(0, 200),
      description: String(item.description || '').substring(0, 500),
      type: VALID_ACTION_TYPES.includes(item.type) ? item.type : 'daily',
      priority: VALID_PRIORITIES.includes(item.priority) ? item.priority : 'medium',
      relatedHabit: item.relatedHabit ? String(item.relatedHabit).substring(0, 100) : null,
      relatedHabitId: item.relatedHabitId && habitIdSet.has(item.relatedHabitId)
        ? String(item.relatedHabitId).substring(0, 100)
        : null,
      metric: String(item.metric || '').substring(0, 200),
    }));
  } catch (error) {
    console.error(`[generateActionItems] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate action items. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateActionItems] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateActionItems;
