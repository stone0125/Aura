// =============================================================================
// generateHabitSuggestions.js — AI Habit Suggestion Agent
// AI 习惯建议代理
//
// Uses Gemini to generate personalized, evidence-based habit recommendations
// based on the user's interest categories, existing habits, and performance
// metrics. Applies behavioral psychology principles (Fogg Behavior Model,
// habit stacking) to tailor suggestions to the user's demonstrated capacity.
//
// 使用 Gemini 根据用户的兴趣类别、现有习惯和绩效指标生成个性化的、
// 基于证据的习惯建议。应用行为心理学原理（福格行为模型、习惯叠加）
// 来量身定制适合用户实际能力水平的建议。
// =============================================================================

const {
  HttpsError,
  VALID_CATEGORIES,
  getGenAI,
  SchemaType,
  validateArray,
  validateCategory,
  sanitizeForPrompt,
  validateNumber,
  checkBurstLimit,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  validateGeminiResponse,
  parseGeminiJSON,
} = require("../helpers");

const RESPONSE_SCHEMA = {
  type: SchemaType.ARRAY,
  description: "3 personalized habit recommendations",
  items: {
    type: SchemaType.OBJECT,
    properties: {
      habitName: { type: SchemaType.STRING, description: "The habit name" },
      category: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["health", "learning", "productivity", "mindfulness", "fitness"],
      },
      explanation: { type: SchemaType.STRING, description: "What the habit is and how to do it" },
      reason: { type: SchemaType.STRING, description: "Why this helps the user" },
      frequencyType: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["daily", "weekly"],
      },
      weeklyDays: {
        type: SchemaType.ARRAY,
        nullable: true,
        description: "Array of day numbers 0-6 (0=Sunday) if frequencyType is weekly, null if daily",
        items: { type: SchemaType.INTEGER },
      },
      goalType: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["none", "time", "count"],
      },
      goalValue: { type: SchemaType.NUMBER, nullable: true, description: "Numeric target if goalType is not none, null otherwise" },
      goalUnit: { type: SchemaType.STRING, nullable: true, description: "Unit string if goalType is not none, null otherwise" },
      estimatedMinutes: { type: SchemaType.INTEGER, description: "Realistic daily time commitment in minutes (1-120)" },
      estimatedImpact: {
        type: SchemaType.STRING,
        format: "enum",
        enum: ["High", "Medium", "Low"],
      },
      suggestedReminderHour: { type: SchemaType.INTEGER, nullable: true, description: "0-23 hour for best time, null if no recommendation" },
      suggestedReminderMinute: { type: SchemaType.INTEGER, nullable: true, description: "0-59 minute, null if no recommendation" },
    },
    required: ["habitName", "category", "explanation", "reason", "frequencyType", "goalType", "estimatedMinutes", "estimatedImpact"],
  },
};

async function generateHabitSuggestions(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'suggestions'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'suggestion');

  // Input validation
  const { categories, currentHabits, userStats } = request.data || {};

  const validatedCategories = validateArray(categories || [], 'categories', 10)
    .map(c => validateCategory(c));

  const validatedHabits = validateArray(currentHabits || [], 'currentHabits', 50)
    .map(h => sanitizeForPrompt(h))
    .filter(h => h.length > 0);

  // Extract user stats for personalization (with defaults)
  const completionRate = validateNumber(userStats?.completionRate ?? 0, 'completionRate', 0, 100);
  const bestStreak = validateNumber(userStats?.bestStreak ?? 0, 'bestStreak', 0, 10000);
  const totalHabits = validateNumber(userStats?.totalHabits ?? 0, 'totalHabits', 0, 100);

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

  // Build personalized prompt based on user data
  let userContext = '';
  if (totalHabits > 0) {
    userContext = `
    Current User Performance Metrics:
    - Active habit portfolio: ${totalHabits} habits
    - Overall completion rate: ${completionRate.toFixed(1)}%
    - Best streak achieved: ${bestStreak} days
    - Performance tier: ${completionRate >= 80 ? 'High Performer' : completionRate >= 50 ? 'Building Consistency' : 'Foundation Phase'}
    `;
  }

  const prompt = `
    You are a behavioral psychologist and habit formation specialist. Analyze the user's profile and provide evidence-based habit recommendations.

    USER PROFILE:
    - Interest categories: ${validatedCategories.join(", ")}
    - Current habits: ${validatedHabits.length > 0 ? validatedHabits.join(", ") : "No habits yet (new user)"}
    ${userContext}

    ANALYSIS REQUIREMENTS:
    1. Apply habit stacking principles (Fogg Behavior Model) to suggest habits that complement existing routines
    2. Consider the user's current capacity based on completion rate
    3. Ensure variety across categories while maintaining focus
    ${completionRate < 50 ? '4. IMPORTANT: User shows inconsistency patterns. Recommend micro-habits (2-5 min) with low friction.' : ''}
    ${completionRate > 80 ? '4. IMPORTANT: User demonstrates strong consistency. Recommend challenging habits that build on existing momentum.' : ''}
    ${totalHabits === 0 ? '4. IMPORTANT: First-time user. Recommend beginner-friendly habits with immediate rewards and clear implementation intentions.' : ''}

    Suggest exactly 3 new, specific habits that:
    - Have clear implementation triggers
    - Build on existing habits when possible
    - Match the user's demonstrated capacity level

    Format as JSON array with keys:
    - "habitName": string (the habit name)
    - "category": one of "health", "learning", "productivity", "mindfulness", "fitness"
    - "explanation": string (what the habit is and how to do it)
    - "reason": string (why this helps the user)
    - "frequencyType": "daily" or "weekly"
    - "weeklyDays": array of day numbers [0-6] (0=Sunday) ONLY if frequencyType is "weekly", otherwise null
    - "goalType": "none", "time", or "count"
    - "goalValue": numeric target (e.g. 10 for 10 minutes) ONLY if goalType is "time" or "count", otherwise null
    - "goalUnit": string unit (e.g. "minutes", "pages", "glasses") ONLY if goalType is "time" or "count", otherwise null
    - "estimatedMinutes": realistic daily time commitment in minutes (1-120)
    - "estimatedImpact": "High", "Medium", or "Low" based on expected life impact
    - "suggestedReminderHour": 0-23 hour for best time to do this habit, null if no recommendation
    - "suggestedReminderMinute": 0-59 minute, null if no recommendation

  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    validateGeminiResponse(text, "generateHabitSuggestions");

    const parsed = parseGeminiJSON(text);

    if (!Array.isArray(parsed)) throw new HttpsError("internal", "Expected array, got: " + typeof parsed);
    if (parsed.length === 0) {
      console.warn("Gemini returned empty suggestions array");
      throw new HttpsError("internal", "Gemini returned 0 suggestions");
    }

    const VALID_FREQUENCY_TYPES = ['daily', 'weekly'];
    const VALID_GOAL_TYPES = ['none', 'time', 'count'];
    const VALID_IMPACTS = ['High', 'Medium', 'Low'];
    returnValue = parsed.filter(item => item && typeof item === 'object').slice(0, 5).map(item => ({
      habitName: String(item.habitName || '').substring(0, 100),
      category: VALID_CATEGORIES.includes(item.category) ? item.category : 'health',
      explanation: String(item.explanation || '').substring(0, 500),
      reason: String(item.reason || '').substring(0, 500),
      frequencyType: VALID_FREQUENCY_TYPES.includes(item.frequencyType) ? item.frequencyType : 'daily',
      weeklyDays: item.frequencyType === 'weekly' && Array.isArray(item.weeklyDays)
        ? item.weeklyDays.filter(d => Number.isInteger(d) && d >= 0 && d <= 6).slice(0, 7)
        : null,
      goalType: VALID_GOAL_TYPES.includes(item.goalType) ? item.goalType : 'none',
      goalValue: item.goalType && item.goalType !== 'none' && Number.isFinite(Number(item.goalValue))
        ? Math.min(10000, Math.max(1, Number(item.goalValue)))
        : null,
      goalUnit: item.goalType && item.goalType !== 'none' && item.goalUnit
        ? String(item.goalUnit).substring(0, 50)
        : null,
      estimatedMinutes: Math.min(120, Math.max(1, Number(item.estimatedMinutes) || 15)),
      estimatedImpact: VALID_IMPACTS.includes(item.estimatedImpact) ? item.estimatedImpact : 'Medium',
      suggestedReminderHour: Number.isInteger(item.suggestedReminderHour) && item.suggestedReminderHour >= 0 && item.suggestedReminderHour <= 23
        ? item.suggestedReminderHour
        : null,
      suggestedReminderMinute: Number.isInteger(item.suggestedReminderMinute) && item.suggestedReminderMinute >= 0 && item.suggestedReminderMinute <= 59
        ? item.suggestedReminderMinute
        : null,
    }));
  } catch (error) {
    console.error(`[generateHabitSuggestions] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate suggestions. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'suggestion');
  } catch (usageError) {
    console.error(`[generateHabitSuggestions] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateHabitSuggestions;
