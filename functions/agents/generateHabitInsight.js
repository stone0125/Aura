// =============================================================================
// generateHabitInsight.js — Habit Performance Insight Agent
// 习惯表现洞察代理
//
// Analyzes a habit's metrics (streak, completions, recent activity) using
// Gemini AI and returns a data-driven, professional insight with an icon
// and confidence level.
//
// 使用 Gemini AI 分析习惯的指标（连续天数、完成次数、近期活动），
// 返回基于数据的专业洞察，包含图标和置信度。
// =============================================================================

const {
  HttpsError,
  getGenAI,
  SchemaType,
  validateString,
  validateNumber,
  validateCategory,
  sanitizeForPrompt,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  checkBurstLimit,
  validateGeminiResponse,
  parseGeminiJSON,
} = require("../helpers");

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    text: { type: SchemaType.STRING, description: "Analytical insight text" },
    icon: {
      type: SchemaType.STRING,
      format: "enum",
      enum: ["trending_up", "emoji_events", "psychology", "timer", "favorite"],
      description: "Icon type based on insight category",
    },
  },
  required: ["text", "icon"],
};

async function generateHabitInsight(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'habitInsight'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  // Input validation
  const data = request.data || {};

  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  if (!habitName) {
    throw new HttpsError('invalid-argument', 'habitName must not be empty');
  }
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak ?? 0, 'currentStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions ?? 0, 'totalCompletions', 0, 100000);
  const recentDays = validateNumber(data.recentDays ?? 0, 'recentDays', 0, 7);
  const daysSinceCreation = validateNumber(data.daysSinceCreation ?? 7, 'daysSinceCreation', 1, 10000);

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

  // Calculate performance metrics using actual active days (not hardcoded 7)
  const activeDays = Math.min(7, daysSinceCreation);
  const recentCompletionRate = recentDays > 0 ? ((recentDays / activeDays) * 100).toFixed(0) : 0;

  const prompt = `
    You are a behavioral analytics specialist. Analyze this habit's performance data and provide a data-driven insight.

    HABIT METRICS:
    - Habit: "${habitName}"
    - Category: ${category}
    - Current streak: ${currentStreak} days
    - Total completions: ${totalCompletions}
    - Completion rate: ${recentCompletionRate}% (${recentDays}/${activeDays} days)

    ANALYSIS REQUIREMENTS:
    Generate a concise, professional insight (1-2 sentences) that:
    1. References specific metrics from the data
    2. Identifies the current behavioral pattern
    3. Provides one evidence-based recommendation or acknowledgment

    Use professional language (e.g., "Your data shows...", "Based on your ${recentCompletionRate}% weekly rate...").

    Format as JSON with these keys:
    - "text": The analytical insight (include at least one specific number)
    - "icon": Select based on insight type:
      * "trending_up" - positive momentum/improvement
      * "emoji_events" - milestone achievement
      * "psychology" - behavioral insight
      * "timer" - consistency/timing related
      * "favorite" - engagement/commitment
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    validateGeminiResponse(text, "generateHabitInsight");
    const parsed = parseGeminiJSON(text);

    const VALID_ICONS = ['trending_up', 'emoji_events', 'psychology', 'timer', 'favorite'];
    returnValue = {
      text: String(parsed.text || '').substring(0, 500),
      icon: VALID_ICONS.includes(parsed.icon) ? parsed.icon : 'psychology',
      confidence: (currentStreak >= 7 || totalCompletions >= 20) ? 'high' : 'medium',
    };
  } catch (error) {
    console.error(`[generateHabitInsight] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate habit insight. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateHabitInsight] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateHabitInsight;
