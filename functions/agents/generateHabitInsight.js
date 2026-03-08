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

const { HttpsError } = require("firebase-functions/v2/https");
const {
  getGenAI,
  validateString,
  validateNumber,
  validateCategory,
  sanitizeForPrompt,
  getUserTier,
  checkAndRecordUsage,
  checkBurstLimit,
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
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  // Input validation
  const data = request.data || {};

  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak, 'currentStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions, 'totalCompletions', 0, 100000);
  const recentDays = validateNumber(data.recentDays, 'recentDays', 0, 7);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Calculate performance metrics
  const recentCompletionRate = recentDays > 0 ? ((recentDays / 7) * 100).toFixed(0) : 0;
  const avgCompletionsPerWeek = totalCompletions > 0 ? (totalCompletions / Math.max(1, Math.ceil(currentStreak / 7))).toFixed(1) : 0;

  const prompt = `
    You are a behavioral analytics specialist. Analyze this habit's performance data and provide a data-driven insight.

    HABIT METRICS:
    - Habit: "${habitName}"
    - Category: ${category}
    - Current streak: ${currentStreak} days
    - Total completions: ${totalCompletions}
    - 7-day completion rate: ${recentCompletionRate}% (${recentDays}/7 days)
    - Avg weekly completions: ${avgCompletionsPerWeek}

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

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    const VALID_ICONS = ['trending_up', 'emoji_events', 'psychology', 'timer', 'favorite'];
    return {
      text: String(parsed.text || '').substring(0, 500),
      icon: VALID_ICONS.includes(parsed.icon) ? parsed.icon : 'psychology',
      confidence: ['high', 'medium'].includes(parsed.confidence) ? parsed.confidence : 'medium',
    };
  } catch (error) {
    console.error("Error generating habit insight:", error.message || error);
    throw new HttpsError("internal", `Failed to generate habit insight: ${error.message || 'Unknown error'}`);
  }
}

module.exports = generateHabitInsight;
