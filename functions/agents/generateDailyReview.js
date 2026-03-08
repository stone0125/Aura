// =============================================================================
// generateDailyReview.js — Daily Review AI Agent
// 每日回顾 AI 代理
//
// Generates a comprehensive daily performance review using Gemini AI.
// Scores each habit, provides coach commentary, health insights,
// motivational messages, and tomorrow's focus recommendation.
//
// 使用 Gemini AI 生成综合每日表现回顾。
// 为每个习惯评分，提供教练评语、健康洞察、
// 励志信息和明日重点建议。
// =============================================================================

const { HttpsError } = require("firebase-functions/v2/https");
const {
  getGenAI,
  validateString,
  validateArray,
  validateNumber,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkAndRecordUsage,
  VALID_CATEGORIES,
} = require("../helpers");

/// Generate a daily performance review with AI coach commentary
/// 生成带 AI 教练评语的每日表现回顾
async function generateDailyReview(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'review');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  const data = request.data || {};

  // Input validation
  const date = validateString(data.date || new Date().toISOString().split('T')[0], 'date', 20);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    throw new HttpsError('invalid-argument', 'Invalid date format. Expected YYYY-MM-DD.');
  }
  const habits = validateArray(data.habits || [], 'habits', 50);
  const weeklyTrend = validateArray(data.weeklyTrend || [], 'weeklyTrend', 7);
  const healthData = data.healthData || null;
  const previousScore = validateNumber(data.previousScore ?? 0, 'previousScore', 0, 100);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Calculate summary metrics
  const totalHabits = habits.length;
  const completedHabits = habits.filter(h => h.completed === true).length;
  const completionRate = totalHabits > 0 ? ((completedHabits / totalHabits) * 100).toFixed(1) : 0;
  const sanitizedTrend = weeklyTrend.map(x => Number(x) || 0);
  const weeklyAvg = sanitizedTrend.length > 0
    ? (sanitizedTrend.reduce((a, b) => a + b, 0) / sanitizedTrend.length).toFixed(1)
    : 0;

  let healthContext = '';
  if (healthData) {
    const steps = Number(healthData.steps) || null;
    const sleepHours = Number(healthData.sleepHours) || null;
    const sleepQuality = sanitizeForPrompt(String(healthData.sleepQuality || '')) || 'N/A';
    const heartRate = Number(healthData.heartRate) || null;
    const activeMinutes = Number(healthData.activeMinutes) || null;
    healthContext = `
    TODAY'S HEALTH METRICS:
    - Steps: ${steps ?? 'N/A'}
    - Sleep: ${sleepHours ?? 'N/A'} hours (quality: ${sleepQuality})
    - Average heart rate: ${heartRate ?? 'N/A'} bpm
    - Active minutes: ${activeMinutes ?? 'N/A'}
    Analyze how these correlate with habit performance.
    `;
  }

  const habitsDetail = habits.map(h => {
    let detail = `- ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): ${h.completed ? 'Completed' : 'Incomplete'}, Streak: ${Number(h.streak) || 0}`;
    if (h.goalType && h.goalType !== 'none') {
      detail += `, Goal: ${Number(h.goalValue) || 0} ${sanitizeForPrompt(h.goalUnit || '')} (${h.goalType})`;
    }
    return detail;
  }).join('\n');

  const prompt = `
    You are an elite behavioral coach providing a personalized daily performance review.

    DATE: ${date}

    DAILY METRICS:
    - Habits completed: ${completedHabits}/${totalHabits} (${completionRate}%)
    - Previous day's score: ${previousScore}
    - 7-day trend: ${JSON.stringify(sanitizedTrend)} (avg: ${weeklyAvg}%)

    TODAY'S HABITS:
    ${habitsDetail}
    ${healthContext}

    ANALYSIS REQUIREMENTS:
    1. Calculate an overall daily score (0-100) based on completion rate, streak maintenance, and trend
    2. Provide scores and brief comments for each habit
    3. Generate professional coach commentary with specific observations
    4. If health data provided, identify correlations

    SCORING CRITERIA:
    - Base score from completion rate (0-100)
    - Bonus (+5) for maintaining streaks > 7 days
    - Bonus (+10) for perfect completion day
    - Penalty (-5) for breaking streaks > 7 days
    - Trend adjustment: +/-10 based on improvement/decline vs weekly average

    Return JSON:
    {
      "overallScore": <number 0-100>,
      "scoreChange": <number, difference from previousScore>,
      "grade": "<A+, A, B+, B, C, D, F>",
      "habitScores": [
        {
          "habitId": "<habit id or name>",
          "score": <0-100>,
          "status": "<completed|missed|streak_milestone|streak_broken>",
          "comment": "<brief personalized observation>"
        }
      ],
      "coachComments": {
        "summary": "<2-3 sentence overall analysis with specific metrics>",
        "highlight": "<most notable positive achievement today>",
        "concern": "<area that needs attention, null if none>",
        "actionItem": "<specific recommendation for tomorrow>"
      },
      "healthInsights": {
        "correlation": "<observed health-habit correlation, null if no health data>",
        "recommendation": "<health-based recommendation, null if no data>"
      },
      "motivationalMessage": "<personalized encouragement based on performance>",
      "tomorrowFocus": "<specific habit or behavior to prioritize tomorrow>"
    }

    Use professional, data-driven language. Reference specific numbers.
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    const VALID_GRADES = ['A+', 'A', 'B+', 'B', 'C', 'D', 'F'];
    const VALID_STATUSES = ['completed', 'missed', 'streak_milestone', 'streak_broken'];
    return {
      overallScore: Math.min(100, Math.max(0, Number(parsed.overallScore) || 0)),
      scoreChange: Math.min(100, Math.max(-100, Number(parsed.scoreChange) || 0)),
      grade: VALID_GRADES.includes(parsed.grade) ? parsed.grade : 'C',
      habitScores: Array.isArray(parsed.habitScores) ? parsed.habitScores.slice(0, 50).map(h => ({
        habitId: String(h.habitId || '').substring(0, 100),
        score: Math.min(100, Math.max(0, Number(h.score) || 0)),
        status: VALID_STATUSES.includes(h.status) ? h.status : 'missed',
        comment: String(h.comment || '').substring(0, 300),
      })) : [],
      coachComments: {
        summary: String(parsed.coachComments?.summary || '').substring(0, 500),
        highlight: String(parsed.coachComments?.highlight || '').substring(0, 300),
        concern: parsed.coachComments?.concern ? String(parsed.coachComments.concern).substring(0, 300) : null,
        actionItem: String(parsed.coachComments?.actionItem || '').substring(0, 300),
      },
      healthInsights: {
        correlation: parsed.healthInsights?.correlation ? String(parsed.healthInsights.correlation).substring(0, 500) : null,
        recommendation: parsed.healthInsights?.recommendation ? String(parsed.healthInsights.recommendation).substring(0, 500) : null,
      },
      motivationalMessage: String(parsed.motivationalMessage || '').substring(0, 500),
      tomorrowFocus: String(parsed.tomorrowFocus || '').substring(0, 300),
    };
  } catch (error) {
    console.error("Error generating daily review:", error.message || error);
    throw new HttpsError("internal", `Failed to generate daily review: ${error.message || 'Unknown error'}`);
  }
}

module.exports = generateDailyReview;
