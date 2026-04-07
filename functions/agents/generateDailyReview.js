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

const {
  HttpsError,
  getGenAI,
  SchemaType,
  validateString,
  validateArray,
  validateNumber,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  VALID_CATEGORIES,
  validateGeminiResponse,
  parseGeminiJSON,
} = require("../helpers");

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    overallScore: { type: SchemaType.INTEGER, description: "Overall daily score 0-100" },
    grade: {
      type: SchemaType.STRING,
      format: "enum",
      enum: ["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F"],
    },
    habitScores: {
      type: SchemaType.ARRAY,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          habitId: { type: SchemaType.STRING, description: "Habit identifier" },
          score: { type: SchemaType.INTEGER, description: "Score 0-100" },
          status: {
            type: SchemaType.STRING,
            format: "enum",
            enum: ["completed", "missed", "streak_milestone", "streak_broken"],
          },
          comment: { type: SchemaType.STRING, description: "Brief personalized observation" },
        },
        required: ["habitId", "score", "status", "comment"],
      },
    },
    coachComments: {
      type: SchemaType.OBJECT,
      properties: {
        summary: { type: SchemaType.STRING, description: "2-3 sentence overall analysis" },
        highlight: { type: SchemaType.STRING, description: "Most notable positive achievement" },
        concern: { type: SchemaType.STRING, nullable: true, description: "Area needing attention, or null" },
        actionItem: { type: SchemaType.STRING, description: "Specific recommendation for tomorrow" },
      },
      required: ["summary", "highlight", "actionItem"],
    },
    healthInsights: {
      type: SchemaType.OBJECT,
      properties: {
        correlation: { type: SchemaType.STRING, nullable: true, description: "Health-habit correlation, null if no data" },
        recommendation: { type: SchemaType.STRING, nullable: true, description: "Health recommendation, null if no data" },
      },
    },
    motivationalMessage: { type: SchemaType.STRING, description: "Personalized encouragement" },
    tomorrowFocus: { type: SchemaType.STRING, description: "Specific habit to prioritize tomorrow" },
  },
  required: ["overallScore", "grade", "habitScores", "coachComments", "motivationalMessage", "tomorrowFocus"],
};

/// Generate a daily performance review with AI coach commentary
/// 生成带 AI 教练评语的每日表现回顾
async function generateDailyReview(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'review'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'report');

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

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

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
    const steps = healthData.steps != null ? Number(healthData.steps) : null;
    const sleepHours = healthData.sleepHours != null ? Number(healthData.sleepHours) : null;
    const sleepQuality = sanitizeForPrompt(String(healthData.sleepQuality || '')) || 'N/A';
    const heartRate = healthData.heartRate != null ? Number(healthData.heartRate) : null;
    const activeMinutes = healthData.activeMinutes != null ? Number(healthData.activeMinutes) : null;
    healthContext = `
    TODAY'S HEALTH METRICS:
    - Steps: ${steps ?? 'N/A'}
    - Sleep: ${sleepHours ?? 'N/A'} hours (quality: ${sleepQuality})
    - Average heart rate: ${heartRate ?? 'N/A'} bpm
    - Active minutes: ${activeMinutes ?? 'N/A'}
    Analyze how these correlate with habit performance.
    `;
  }

  const habitsDetail = habits.filter(h => h && typeof h === 'object').map(h => {
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
      "grade": "<A+, A, A-, B+, B, B-, C+, C, C-, D, F>",
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
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    validateGeminiResponse(text, "generateDailyReview");
    const parsed = parseGeminiJSON(text);

    const VALID_GRADES = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'];
    const VALID_STATUSES = ['completed', 'missed', 'streak_milestone', 'streak_broken'];
    returnValue = {
      overallScore: Math.min(100, Math.max(0, Number(parsed.overallScore) || 0)),
      scoreChange: Math.min(100, Math.max(-100, Math.min(100, Math.max(0, Number(parsed.overallScore) || 0)) - previousScore)),
      grade: VALID_GRADES.includes(parsed.grade) ? parsed.grade : 'C',
      habitScores: Array.isArray(parsed.habitScores) ? parsed.habitScores.filter(h => h && typeof h === 'object').slice(0, 50).map(h => ({
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
    console.error(`[generateDailyReview] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate daily review. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateDailyReview] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateDailyReview;
