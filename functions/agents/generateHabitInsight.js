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
  validateString,
  validateNumber,
  validateCategory,
  sanitizeForPrompt,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  checkBurstLimit,
  parseGeminiJSON,
} = require("../helpers");

async function generateHabitInsight(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'habitInsight');
  const tier = await getUserTier(request.auth.uid);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  // Input validation
  const data = request.data || {};

  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak ?? 0, 'currentStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions ?? 0, 'totalCompletions', 0, 100000);
  const recentDays = validateNumber(data.recentDays ?? 0, 'recentDays', 0, 7);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Calculate performance metrics
  const recentCompletionRate = recentDays > 0 ? ((recentDays / 7) * 100).toFixed(0) : 0;

  const prompt = `
    You are a behavioral analytics specialist. Analyze this habit's performance data and provide a data-driven insight.

    HABIT METRICS:
    - Habit: "${habitName}"
    - Category: ${category}
    - Current streak: ${currentStreak} days
    - Total completions: ${totalCompletions}
    - 7-day completion rate: ${recentCompletionRate}% (${recentDays}/7 days)

    ANALYSIS REQUIREMENTS:
    Generate a concise, professional insight (1-2 sentences) that:
    1. References specific metrics from the data
    2. Identifies the current behavioral pattern
    3. Provides one evidence-based recommendation or acknowledgment

    Use professional language (e.g., "Your data shows...", "Based on your ${recentCompletionRate}% weekly rate...").

    Format as JSON:
    - "text": The analytical insight (include at least one specific number)
    - "icon": Select based on insight type:
      * "trending_up" - positive momentum/improvement
      * "emoji_events" - milestone achievement
      * "psychology" - behavioral insight
      * "timer" - consistency/timing related
      * "favorite" - engagement/commitment
    - "confidence": "high" if streak >= 7 or totalCompletions >= 20, otherwise "medium"

    Do not include markdown formatting.
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const parsed = parseGeminiJSON(text);

    const VALID_ICONS = ['trending_up', 'emoji_events', 'psychology', 'timer', 'favorite'];
    returnValue = {
      text: String(parsed.text || '').substring(0, 500),
      icon: VALID_ICONS.includes(parsed.icon) ? parsed.icon : 'psychology',
      confidence: ['high', 'medium'].includes(parsed.confidence) ? parsed.confidence : 'medium',
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
