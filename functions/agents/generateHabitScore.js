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

const {
  HttpsError,
  getGenAI,
  SchemaType,
  validateString,
  validateNumber,
  validateCategory,
  validateArray,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  validateGeminiResponse,
  parseGeminiJSON,
} = require("../helpers");

const RESPONSE_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    breakdown: {
      type: SchemaType.OBJECT,
      description: "Scores for each of the 4 dimensions",
      properties: {
        consistency: {
          type: SchemaType.OBJECT,
          properties: {
            score: { type: SchemaType.INTEGER, description: "Score 0-100" },
            analysis: { type: SchemaType.STRING, description: "1-2 sentence explanation" },
          },
          required: ["score", "analysis"],
        },
        momentum: {
          type: SchemaType.OBJECT,
          properties: {
            score: { type: SchemaType.INTEGER, description: "Score 0-100" },
            analysis: { type: SchemaType.STRING, description: "1-2 sentence explanation" },
          },
          required: ["score", "analysis"],
        },
        resilience: {
          type: SchemaType.OBJECT,
          properties: {
            score: { type: SchemaType.INTEGER, description: "Score 0-100" },
            analysis: { type: SchemaType.STRING, description: "1-2 sentence explanation" },
          },
          required: ["score", "analysis"],
        },
        engagement: {
          type: SchemaType.OBJECT,
          properties: {
            score: { type: SchemaType.INTEGER, description: "Score 0-100" },
            analysis: { type: SchemaType.STRING, description: "1-2 sentence explanation" },
          },
          required: ["score", "analysis"],
        },
      },
      required: ["consistency", "momentum", "resilience", "engagement"],
    },
    primaryStrength: { type: SchemaType.STRING, description: "Key strength identified" },
    primaryWeakness: { type: SchemaType.STRING, description: "Area for improvement" },
    recommendation: { type: SchemaType.STRING, description: "Specific actionable recommendation" },
    comparisonToAverage: { type: SchemaType.STRING, description: "Percentile estimate" },
    healthCorrelation: { type: SchemaType.STRING, nullable: true, description: "Health insight if data provided, null otherwise" },
  },
  required: ["breakdown", "primaryStrength", "primaryWeakness", "recommendation", "comparisonToAverage"],
};

/// Generate a comprehensive performance score for a single habit
/// 为单个习惯生成综合表现评分
async function generateHabitScore(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'score'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  const data = request.data || {};

  // Input validation
  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  if (!habitName) {
    throw new HttpsError('invalid-argument', 'habitName must not be empty');
  }
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak ?? 0, 'currentStreak', 0, 10000);
  const longestStreak = validateNumber(data.longestStreak ?? 0, 'longestStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions ?? 0, 'totalCompletions', 0, 100000);
  const completionHistory = validateArray(data.completionHistory || [], 'completionHistory', 30);
  const healthData = data.healthData || null;
  const VALID_GOAL_TYPES = ['none', 'daily', 'weekly', 'monthly'];
  const rawGoalType = data.goalType || null;
  const goalType = VALID_GOAL_TYPES.includes(rawGoalType) ? rawGoalType : null;
  const goalValue = data.goalValue && Number.isFinite(Number(data.goalValue))
    ? Math.min(10000, Math.max(1, Number(data.goalValue)))
    : null;
  const goalUnit = data.goalUnit ? sanitizeForPrompt(String(data.goalUnit)).substring(0, 50) : null;

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

  // Calculate derived metrics
  const daysWithHistory = completionHistory.length;
  const completedDays = completionHistory.filter(d => d === true || d === 1).length;
  const historyCompletionRate = daysWithHistory > 0 ? ((completedDays / daysWithHistory) * 100).toFixed(1) : 0;
  const streakRetentionRate = longestStreak > 0 ? ((currentStreak / longestStreak) * 100).toFixed(1) : 0;

  let healthContext = '';
  if (healthData) {
    const avgSteps = healthData.avgSteps != null ? Number(healthData.avgSteps) : null;
    const avgSleep = healthData.avgSleep != null ? Number(healthData.avgSleep) : null;
    const avgHeartRate = healthData.avgHeartRate != null ? Number(healthData.avgHeartRate) : null;
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

    Return JSON with structure (overallScore and grade are computed server-side, do NOT include them):
    {
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

  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    validateGeminiResponse(text, "generateHabitScore");

    const parsed = parseGeminiJSON(text);

    const validateBreakdown = (b) => ({
      score: Math.min(100, Math.max(0, Number(b?.score) || 0)),
      analysis: String(b?.analysis || '').substring(0, 500),
    });
    // Ensure all 4 breakdown fields exist (Dart client expects all of them)
    const breakdown = parsed.breakdown || {};

    // Compute overallScore from weighted breakdown (server-side, not AI)
    const validatedBreakdown = {
      consistency: validateBreakdown(breakdown.consistency),
      momentum: validateBreakdown(breakdown.momentum),
      resilience: validateBreakdown(breakdown.resilience),
      engagement: validateBreakdown(breakdown.engagement),
    };
    const computedScore = Math.round(
      0.40 * validatedBreakdown.consistency.score +
      0.25 * validatedBreakdown.momentum.score +
      0.20 * validatedBreakdown.resilience.score +
      0.15 * validatedBreakdown.engagement.score
    );
    const clampedScore = Math.min(100, Math.max(0, computedScore));

    // Derive grade from computed score
    const GRADE_THRESHOLDS = [
      [95, 'A+'], [90, 'A'], [87, 'A-'],
      [83, 'B+'], [80, 'B'], [77, 'B-'],
      [73, 'C+'], [70, 'C'], [67, 'C-'],
      [60, 'D'],
    ];
    let computedGrade = 'F';
    for (const [threshold, grade] of GRADE_THRESHOLDS) {
      if (clampedScore >= threshold) {
        computedGrade = grade;
        break;
      }
    }

    returnValue = {
      overallScore: clampedScore,
      grade: computedGrade,
      breakdown: validatedBreakdown,
      primaryStrength: String(parsed.primaryStrength || '').substring(0, 300),
      primaryWeakness: String(parsed.primaryWeakness || '').substring(0, 300),
      recommendation: String(parsed.recommendation || '').substring(0, 500),
      comparisonToAverage: String(parsed.comparisonToAverage || '').substring(0, 200),
      healthCorrelation: parsed.healthCorrelation ? String(parsed.healthCorrelation).substring(0, 500) : null,
    };
  } catch (error) {
    console.error(`[generateHabitScore] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate habit score. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateHabitScore] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateHabitScore;
