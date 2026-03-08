// =============================================================================
// generateHabitTips.js — AI Habit Tips Agent
// AI 习惯建议代理
//
// Generates 15 evidence-based coaching insights organized by skill level,
// personalized to the user's behavioral profile (active habits, consistency,
// streaks, and total completions). Uses Gemini to produce structured JSON
// tips across five categories: Getting Started, Staying Consistent,
// Overcoming Challenges, Advanced Strategies, and Mindset & Motivation.
//
// 生成 15 条按技能级别组织的循证辅导建议，根据用户的行为档案（活跃习惯、
// 一致性、连续打卡天数和总完成次数）进行个性化。使用 Gemini 生成涵盖五个
// 类别的结构化 JSON 建议：入门、保持一致、克服挑战、高级策略和心态与动力。
// =============================================================================

const {
  HttpsError,
  getGenAI,
  validateArray,
  validateNumber,
  sanitizeForPrompt,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  checkBurstLimit,
  parseGeminiJSON,
} = require("../helpers");

/**
 * Generate personalized, evidence-based habit tips for the authenticated user.
 * 为已认证用户生成个性化的循证习惯建议。
 *
 * @param {Object} request - Firebase callable request object.
 * @returns {Array<Object>} Array of tip objects with title, content, category, keyPoints, and actionable fields.
 */
async function generateHabitTips(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'tips');
  const tier = await getUserTier(request.auth.uid);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  // Extract user data for personalization (optional)
  const { userHabits, completionRate, bestStreak, totalCompletions } = request.data || {};

  const habits = validateArray(userHabits || [], 'userHabits', 50)
    .map(h => sanitizeForPrompt(h))
    .filter(h => h.length > 0);
  const rate = validateNumber(completionRate ?? 0, 'completionRate', 0, 100);
  const streak = validateNumber(bestStreak ?? 0, 'bestStreak', 0, 10000);
  const completions = validateNumber(totalCompletions ?? 0, 'totalCompletions', 0, 100000);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Build personalized context if user has enough data
  let personalizationContext = '';
  const hasEnoughData = habits.length >= 3 || completions >= 10;

  if (hasEnoughData) {
    const performanceTier = rate >= 80 ? 'High Performer' : rate >= 50 ? 'Developing' : 'Foundation Building';
    personalizationContext = `
    USER BEHAVIORAL PROFILE:
    - Active habits: ${habits.join(', ')}
    - Consistency index: ${rate.toFixed(1)}%
    - Peak streak: ${streak} days
    - Total completions: ${completions}
    - Performance tier: ${performanceTier}

    PERSONALIZATION REQUIREMENTS:
    ${rate < 40 ? '- PRIORITY: Focus on friction reduction and micro-commitment strategies (user shows early-stage consistency patterns)' : ''}
    ${rate >= 40 && rate < 70 ? '- Focus on habit stacking and environmental design (user is building momentum)' : ''}
    ${rate >= 70 ? '- Include advanced optimization techniques (user demonstrates strong behavioral control)' : ''}
    ${streak < 7 ? '- Emphasize streak psychology and loss aversion principles' : ''}
    ${streak >= 30 ? '- Include plateau prevention and intrinsic motivation development' : ''}

    Reference their specific habits when providing examples.
    `;
  }

  const prompt = `
    You are a behavioral scientist and habit formation expert. Generate 15 evidence-based coaching insights organized by skill level.

    ${personalizationContext}

    CONTENT STRUCTURE (3 tips per category):
    1. Getting Started - Implementation intentions, environment design, minimum viable habits
    2. Staying Consistent - Habit stacking, temptation bundling, identity-based habits
    3. Overcoming Challenges - Contingency planning, self-compassion strategies, momentum recovery
    4. Advanced Strategies - Variable reward schedules, habit graduation, behavioral economics
    5. Mindset & Motivation - Growth mindset, intrinsic vs extrinsic motivation, self-efficacy

    Each tip must include:
    - "title": Concise, action-oriented title (max 6 words)
    - "content": Evidence-based explanation citing behavioral principles (2-3 sentences)
    - "category": one of ["gettingStarted", "stayingConsistent", "overcomingChallenges", "advancedStrategies", "mindsetAndMotivation"]
    - "keyPoints": 3 specific, measurable takeaways
    - "actionable": One concrete next step with timeframe (e.g., "This week, try...")

    Use professional, scientific language while remaining accessible.
    Format as JSON array. Do not include markdown formatting.
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const parsed = parseGeminiJSON(text);

    const VALID_TIP_CATEGORIES = ['gettingStarted', 'stayingConsistent', 'overcomingChallenges', 'advancedStrategies', 'mindsetAndMotivation'];
    if (!Array.isArray(parsed)) throw new Error('Expected array');
    returnValue = parsed.slice(0, 20).map(item => ({
      title: String(item.title || '').substring(0, 100),
      content: String(item.content || '').substring(0, 500),
      category: VALID_TIP_CATEGORIES.includes(item.category) ? item.category : 'gettingStarted',
      keyPoints: Array.isArray(item.keyPoints) ? item.keyPoints.slice(0, 5).map(p => String(p).substring(0, 200)) : [],
      actionable: String(item.actionable || '').substring(0, 300),
    }));
  } catch (error) {
    console.error(`[generateHabitTips] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate tips. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateHabitTips] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateHabitTips;
