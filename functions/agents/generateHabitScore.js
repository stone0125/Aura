// =============================================================================
// generateHabitScore.js — Habit Scoring AI Agent
// 习惯评分 AI 代理
//
// Scores a single habit across 4 dimensions (0-100) using Gemini AI:
// Consistency (40%), Momentum (25%), Resilience (20%), Engagement (15%).
// Assigns a letter grade (A+ to F) and provides strength/weakness analysis.
//
// 使用 Gemini AI 在 4 个维度（0-100）上评分单个习惯：
// 一致性（40%）、动力（25%）、韧性（20%）、参与度（15%）。
// 分配字母等级（A+ 到 F）并提供优势/劣势分析。
// =============================================================================

const { HttpsError } = require("firebase-functions/v2/https");
const {
  getGenAI,
  validateString,
  validateNumber,
  validateCategory,
  validateArray,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkAndRecordUsage,
} = require("../helpers");

/// Generate a comprehensive performance score for a single habit
/// 为单个习惯生成综合表现评分
async function generateHabitScore(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'score');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  const data = request.data || {};

  // Input validation
  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak ?? 0, 'currentStreak', 0, 10000);
  const longestStreak = validateNumber(data.longestStreak ?? 0, 'longestStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions ?? 0, 'totalCompletions', 0, 100000);
  const completionHistory = validateArray(data.completionHistory || [], 'completionHistory', 30);
  const healthData = data.healthData || null;
  const goalType = data.goalType || null;
  const goalValue = data.goalValue ? Number(data.goalValue) : null;
  const goalUnit = data.goalUnit ? sanitizeForPrompt(String(data.goalUnit)).substring(0, 50) : null;

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Calculate derived metrics
  const daysWithHistory = completionHistory.length;
  const completedDays = completionHistory.filter(d => d === true || d === 1).length;
  const historyCompletionRate = daysWithHistory > 0 ? ((completedDays / daysWithHistory) * 100).toFixed(1) : 0;
  const streakRetentionRate = longestStreak > 0 ? ((currentStreak / longestStreak) * 100).toFixed(1) : 0;

  let healthContext = '';
  if (healthData) {
    const avgSteps = Number(healthData.avgSteps) || null;
    const avgSleep = Number(healthData.avgSleep) || null;
    const avgHeartRate = Number(healthData.avgHeartRate) || null;
    healthContext = `
    HEALTH DATA CORRELATION:
    - Average daily steps: ${avgSteps ?? 'N/A'}
    - Average sleep hours: ${avgSleep ?? 'N/A'}
    - Average heart rate: ${avgHeartRate ?? 'N/A'}
    Analyze correlations between health metrics and habit completion patterns.
    `;
  }

  let goalContext = '';
  if (goalType && goalType !== 'none' && goalValue) {
    goalContext = `
    - Goal: ${goalValue} ${goalUnit || ''} (${goalType})
    Consider whether the user's completion patterns suggest they are meeting their goal target.`;
  }

  const prompt = `
    You are a behavioral analytics expert. Generate a comprehensive performance score for this habit.

    HABIT DATA:
    - Name: "${habitName}"
    - Category: ${category}${goalContext}
    - Current streak: ${currentStreak} days
    - Longest streak ever: ${longestStreak} days
    - Total completions: ${totalCompletions}
    - 30-day completion rate: ${historyCompletionRate}%
    - Streak retention rate: ${streakRetentionRate}%
    - Completion pattern (last 30 days, 1=done, 0=missed): ${JSON.stringify(completionHistory.map(d => Boolean(d) ? 1 : 0))}
    ${healthContext}

    SCORING METHODOLOGY:
    Calculate scores (0-100) for each dimension:

    1. CONSISTENCY (40% weight): Based on completion rate, streak length, and pattern regularity
       - 90-100: >90% completion rate with minimal gaps
       - 70-89: 70-90% completion with occasional gaps
       - 50-69: 50-70% completion with irregular patterns
       - Below 50: Significant consistency challenges

    2. MOMENTUM (25% weight): Current trajectory and recent performance vs historical
       - Compare last 7 days to last 30 days
       - Factor in streak growth/decline
       - Consider acceleration/deceleration patterns

    3. RESILIENCE (20% weight): Ability to recover from breaks
       - Analyze gaps in completion history
       - Measure recovery speed after missed days
       - Compare current streak to longest streak

    4. ENGAGEMENT (15% weight): Overall commitment level
       - Total completions relative to time period
       - Pattern of sustained effort
       - Category-specific benchmarks

    GRADE SCALE:
    - A+ (95-100), A (90-94), A- (87-89)
    - B+ (83-86), B (80-82), B- (77-79)
    - C+ (73-76), C (70-72), C- (67-69)
    - D (60-66), F (below 60)

    Return JSON with structure:
    {
      "overallScore": <number 1-100>,
      "grade": "<letter grade>",
      "breakdown": {
        "consistency": { "score": <number>, "analysis": "<1-2 sentence explanation>" },
        "momentum": { "score": <number>, "analysis": "<1-2 sentence explanation>" },
        "resilience": { "score": <number>, "analysis": "<1-2 sentence explanation>" },
        "engagement": { "score": <number>, "analysis": "<1-2 sentence explanation>" }
      },
      "primaryStrength": "<key strength identified>",
      "primaryWeakness": "<area for improvement>",
      "recommendation": "<specific actionable recommendation>",
      "comparisonToAverage": "<percentile estimate, e.g., 'Top 20% of users'>",
      "healthCorrelation": "<insight if health data provided, null otherwise>"
    }

    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    const VALID_GRADES = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'];
    const validateBreakdown = (b) => ({
      score: Math.min(100, Math.max(0, Number(b?.score) || 0)),
      analysis: String(b?.analysis || '').substring(0, 500),
    });
    return {
      overallScore: Math.min(100, Math.max(0, Number(parsed.overallScore) || 0)),
      grade: VALID_GRADES.includes(parsed.grade) ? parsed.grade : 'C',
      breakdown: {
        consistency: validateBreakdown(parsed.breakdown?.consistency),
        momentum: validateBreakdown(parsed.breakdown?.momentum),
        resilience: validateBreakdown(parsed.breakdown?.resilience),
        engagement: validateBreakdown(parsed.breakdown?.engagement),
      },
      primaryStrength: String(parsed.primaryStrength || '').substring(0, 300),
      primaryWeakness: String(parsed.primaryWeakness || '').substring(0, 300),
      recommendation: String(parsed.recommendation || '').substring(0, 500),
      comparisonToAverage: String(parsed.comparisonToAverage || '').substring(0, 200),
      healthCorrelation: parsed.healthCorrelation ? String(parsed.healthCorrelation).substring(0, 500) : null,
    };
  } catch (error) {
    console.error("Error generating habit score:", error.message || error);
    throw new HttpsError("internal", `Failed to generate habit score: ${error.message || 'Unknown error'}`);
  }
}

module.exports = generateHabitScore;
