// =============================================================================
// generatePatternDiscovery.js — Pattern Discovery AI Agent
// 模式发现 AI 代理
//
// Analyzes user habit completion data to discover 2-4 behavioral patterns
// using Gemini AI. Pattern types: time-of-day, day-of-week, sequence, trigger.
// Includes a lite fallback path for users with minimal data.
//
// 使用 Gemini AI 分析用户习惯完成数据，发现 2-4 个行为模式。
// 模式类型：时间段、星期几、序列、触发器。
// 为数据较少的用户提供轻量级回退路径。
// =============================================================================

const { HttpsError } = require("firebase-functions/v2/https");
const {
  getGenAI,
  validateArray,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkAndRecordUsage,
  VALID_CATEGORIES,
} = require("../helpers");

const VALID_PATTERN_TYPES = ['timeOfDay', 'dayOfWeek', 'sequence', 'trigger'];
const VALID_ICON_NAMES = ['schedule', 'wb_sunny', 'nightlight', 'calendar_today', 'weekend', 'link', 'repeat', 'bolt', 'insights'];

/// Discover behavioral patterns from habit completion data
/// 从习惯完成数据中发现行为模式
async function generatePatternDiscovery(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'patterns');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  const { habits } = request.data || {};
  const validatedHabits = validateArray(habits || [], 'habits', 50);

  // Collect all completion dates for threshold checks
  let totalCompletions = 0;
  const allDates = [];
  const habitsDetail = validatedHabits.map(h => {
    const dates = Array.isArray(h.completionDates)
      ? h.completionDates.filter(d => typeof d === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d))
      : [];
    totalCompletions += dates.length;
    allDates.push(...dates);
    return `- ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): streak ${Number(h.streak) || 0}, reminder ${sanitizeForPrompt(h.reminderTime || 'none')}, completions: [${dates.slice(0, 60).join(', ')}]`;
  }).join('\n');

  // Hard minimum: need at least 1 habit with some completions
  if (validatedHabits.length < 1 || totalCompletions < 3) {
    return { patterns: [], reason: 'insufficient_data' };
  }

  // Lite path: 1 habit + 3 completions OR <2 habits + <5 completions
  // Return a simple day-of-week pattern without calling Gemini
  if (validatedHabits.length < 2 || totalCompletions < 5) {
    let weekdayCount = 0;
    let weekendCount = 0;
    for (const dateStr of allDates) {
      const date = new Date(dateStr + 'T00:00:00');
      const day = date.getDay();
      if (day === 0 || day === 6) {
        weekendCount++;
      } else {
        weekdayCount++;
      }
    }
    const isWeekdayStronger = weekdayCount >= weekendCount;
    const patterns = [{
      title: isWeekdayStronger ? 'Weekday Momentum' : 'Weekend Warrior',
      description: isWeekdayStronger
        ? `You completed ${weekdayCount} of ${totalCompletions} habits on weekdays.`
        : `You completed ${weekendCount} of ${totalCompletions} habits on weekends.`,
      insight: isWeekdayStronger
        ? 'Try maintaining your weekday routine through the weekend too.'
        : 'Build on your weekend energy by adding a small weekday habit.',
      type: 'dayOfWeek',
      confidence: 0.5,
      iconName: isWeekdayStronger ? 'calendar_today' : 'weekend',
    }];
    return { patterns };
  }

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  const prompt = `
    You are a behavioral analytics engine. Analyze the user's habit completion data and discover 2-4 behavioral patterns.

    HABIT DATA:
    ${habitsDetail}

    Find patterns of these types:
    - timeOfDay: When the user is most/least productive (morning, afternoon, evening)
    - dayOfWeek: Which days the user is most/least consistent
    - sequence: Habits that are often completed together or one after another
    - trigger: External factors or habits that seem to trigger other completions

    For each pattern provide:
    - title: Short descriptive title (max 50 chars)
    - description: One sentence explanation (max 150 chars)
    - insight: Actionable advice based on this pattern (max 200 chars)
    - type: One of "timeOfDay", "dayOfWeek", "sequence", "trigger"
    - confidence: 0.0 to 1.0 based on data strength
    - iconName: One of "schedule", "wb_sunny", "nightlight", "calendar_today", "weekend", "link", "repeat", "bolt"

    Format as JSON array. Do not include markdown formatting.
    [
      {
        "title": "<short title>",
        "description": "<explanation>",
        "insight": "<actionable advice>",
        "type": "timeOfDay" | "dayOfWeek" | "sequence" | "trigger",
        "confidence": 0.85,
        "iconName": "schedule"
      }
    ]
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    if (!Array.isArray(parsed)) {
      throw new Error("Response is not an array");
    }

    const patterns = parsed.slice(0, 4).map(p => ({
      title: String(p.title || 'Pattern').slice(0, 50),
      description: String(p.description || '').slice(0, 150),
      insight: String(p.insight || '').slice(0, 200),
      type: VALID_PATTERN_TYPES.includes(p.type) ? p.type : 'timeOfDay',
      confidence: Math.min(1.0, Math.max(0.0, Number(p.confidence) || 0.5)),
      iconName: VALID_ICON_NAMES.includes(p.iconName) ? p.iconName : 'insights',
    }));

    return { patterns };
  } catch (error) {
    console.error("Error generating pattern discovery:", error.message || error);
    throw new HttpsError("internal", `Failed to generate pattern discovery: ${error.message || 'Unknown error'}`);
  }
}

module.exports = generatePatternDiscovery;
