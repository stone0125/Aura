// =============================================================================
// generateHealthCorrelations.js — Health Correlation AI Agent
// 健康关联 AI 代理
//
// Analyzes correlations between biometric health data (steps, sleep, heart
// rate, active minutes) and habit completion patterns using Gemini AI.
// Returns Pearson-like correlation coefficients, optimal conditions, and
// actionable health-habit insights.
//
// 使用 Gemini AI 分析生物健康数据（步数、睡眠、心率、
// 活跃分钟数）与习惯完成模式之间的关联。
// 返回类 Pearson 相关系数、最佳条件和可操作的健康-习惯洞察。
// =============================================================================

const {
  HttpsError,
  getGenAI,
  validateArray,
  sanitizeForPrompt,
  checkBurstLimit,
  getUserTier,
  checkUsageLimit,
  recordUsage,
  VALID_CATEGORIES,
  parseGeminiJSON,
} = require("../helpers");

/// Analyze health-habit correlations using AI
/// 使用 AI 分析健康与习惯的关联
async function generateHealthCorrelations(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'correlations');
  const tier = await getUserTier(request.auth.uid);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  const data = request.data || {};

  // Input validation
  const VALID_TIME_RANGES = ['7d', '30d', '90d'];
  const timeRange = VALID_TIME_RANGES.includes(data.timeRange) ? data.timeRange : '30d';
  const habitData = validateArray(data.habitData || [], 'habitData', 100);
  const healthData = validateArray(data.healthData || [], 'healthData', 100);

  if (healthData.length < 7) {
    throw new HttpsError('invalid-argument', 'Minimum 7 days of health data required for correlation analysis');
  }

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Prepare data summary (sanitized)
  const habitSummary = habitData.map(h => ({
    name: sanitizeForPrompt(h.name || ''),
    category: VALID_CATEGORIES.includes(h.category) ? h.category : 'general',
    completionDates: Number(h.completionDates?.length) || 0,
    avgCompletionRate: Number(h.avgCompletionRate) || 0
  }));

  const healthSummary = {
    days: healthData.length,
    avgSteps: healthData.reduce((a, b) => a + (Number(b.steps) || 0), 0) / healthData.length,
    avgSleep: healthData.reduce((a, b) => a + (Number(b.sleepHours) || 0), 0) / healthData.length,
    avgHeartRate: healthData.reduce((a, b) => a + (Number(b.heartRate) || 0), 0) / healthData.length,
    avgActiveMinutes: healthData.reduce((a, b) => a + (Number(b.activeMinutes) || 0), 0) / healthData.length
  };

  const prompt = `
    You are a health data scientist analyzing correlations between biometric data and behavioral patterns.

    TIME RANGE: ${timeRange}

    HEALTH DATA SUMMARY (${healthSummary.days} days):
    - Average daily steps: ${healthSummary.avgSteps.toFixed(0)}
    - Average sleep: ${healthSummary.avgSleep.toFixed(1)} hours
    - Average resting heart rate: ${healthSummary.avgHeartRate.toFixed(0)} bpm
    - Average active minutes: ${healthSummary.avgActiveMinutes.toFixed(0)} min

    HABIT DATA:
    ${JSON.stringify(habitSummary, null, 2)}

    RAW DATA FOR CORRELATION ANALYSIS:
    Health: ${JSON.stringify(healthData.slice(0, 30).map(d => ({ steps: Number(d.steps) || 0, sleepHours: Number(d.sleepHours) || 0, heartRate: Number(d.heartRate) || 0, activeMinutes: Number(d.activeMinutes) || 0 })))}
    Habits: ${JSON.stringify(habitSummary.map(h => ({ name: h.name, completionDates: h.completionDates })))}

    ANALYSIS REQUIREMENTS:
    1. Calculate Pearson-like correlations between each health metric and habit completion
    2. Identify statistically significant patterns (consider sample size)
    3. Determine optimal conditions for habit completion
    4. Generate actionable insights

    CORRELATION STRENGTH SCALE:
    - strong_positive: r > 0.5
    - moderate_positive: 0.3 < r <= 0.5
    - weak_positive: 0.1 < r <= 0.3
    - none: -0.1 <= r <= 0.1
    - weak_negative: -0.3 <= r < -0.1
    - moderate_negative: -0.5 <= r < -0.3
    - strong_negative: r < -0.5

    Return JSON:
    {
      "correlations": [
        {
          "metric": "sleep|steps|heartRate|activeMinutes",
          "impact": "<correlation strength from scale above>",
          "correlation": <number -1 to 1>,
          "insight": "<1-2 sentence explanation of the correlation>",
          "recommendation": "<specific recommendation based on this correlation>"
        }
      ],
      "optimalConditions": {
        "steps": { "min": <number>, "max": <number>, "description": "<optimal range explanation>" },
        "sleep": { "min": <number>, "max": <number>, "description": "<optimal range explanation>" },
        "heartRate": { "min": <number>, "max": <number>, "description": "<optimal range explanation>" },
        "activeMinutes": { "min": <number>, "max": <number>, "description": "<optimal range explanation>" }
      },
      "keyFindings": [
        "<finding 1 - most significant insight>",
        "<finding 2>",
        "<finding 3>"
      ],
      "actionPlan": "<comprehensive recommendation paragraph combining all insights>"
    }

    Use scientific language. Be honest about confidence levels given sample size.
    Do not include markdown formatting.
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const parsed = parseGeminiJSON(text);

    const VALID_IMPACTS = ['strong_positive', 'moderate_positive', 'weak_positive', 'none', 'weak_negative', 'moderate_negative', 'strong_negative'];
    const VALID_METRICS = ['sleep', 'steps', 'heartRate', 'activeMinutes'];

    const sanitizeOptimalConditions = (o) => {
      if (!o || typeof o !== 'object') return {};
      const result = {};
      for (const key of VALID_METRICS) {
        if (o[key] && typeof o[key] === 'object') {
          result[key] = {
            min: Number(o[key].min) || 0,
            max: Number(o[key].max) || 0,
            description: String(o[key].description || '').substring(0, 300),
          };
        }
      }
      return result;
    };

    returnValue = {
      correlations: Array.isArray(parsed.correlations) ? parsed.correlations.slice(0, 10).map(c => ({
        metric: VALID_METRICS.includes(c.metric) ? c.metric : 'steps',
        impact: VALID_IMPACTS.includes(c.impact) ? c.impact : 'none',
        correlation: Math.min(1, Math.max(-1, Number(c.correlation) || 0)),
        insight: String(c.insight || '').substring(0, 500),
        recommendation: String(c.recommendation || '').substring(0, 500),
      })) : [],
      optimalConditions: sanitizeOptimalConditions(parsed.optimalConditions),
      keyFindings: Array.isArray(parsed.keyFindings) ? parsed.keyFindings.slice(0, 5).map(f => String(f).substring(0, 500)) : [],
      actionPlan: String(parsed.actionPlan || '').substring(0, 1000),
    };
  } catch (error) {
    console.error(`[generateHealthCorrelations] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate health correlations. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateHealthCorrelations] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateHealthCorrelations;
