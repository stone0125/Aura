// =============================================================================
// generateWeeklyInsights.js — Weekly Performance Insights Agent
// 每周表现洞察代理
//
// Analyzes a user's weekly habit-tracking data through Gemini AI and returns
// a structured report containing a summary, identified behavioral patterns,
// improvement suggestions, and prioritized next steps.
//
// 通过 Gemini AI 分析用户的每周习惯追踪数据，返回包含摘要、
// 已识别行为模式、改进建议和优先级排序的下一步行动的结构化报告。
// =============================================================================

const {
  HttpsError,
  getGenAI,
  SchemaType,
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
    summary: { type: SchemaType.STRING, description: "Professional analysis of overall weekly performance" },
    pattern: { type: SchemaType.STRING, description: "One positive behavioral pattern identified" },
    improvement: { type: SchemaType.STRING, description: "One specific area for optimization" },
    nextSteps: {
      type: SchemaType.ARRAY,
      description: "2-4 specific, actionable next steps",
      minItems: 2,
      maxItems: 4,
      items: {
        type: SchemaType.OBJECT,
        properties: {
          action: { type: SchemaType.STRING, description: "A specific, measurable action" },
          timeframe: {
            type: SchemaType.STRING,
            format: "enum",
            enum: ["today", "this week", "next week"],
          },
          priority: {
            type: SchemaType.STRING,
            format: "enum",
            enum: ["high", "medium", "low"],
          },
        },
        required: ["action", "timeframe", "priority"],
      },
    },
  },
  required: ["summary", "pattern", "improvement", "nextSteps"],
};

async function generateWeeklyInsights(request) {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Parallelize independent checks to reduce latency
  const [, tier] = await Promise.all([
    checkBurstLimit(request.auth.uid, 'insights'),
    getUserTier(request.auth.uid),
  ]);
  await checkUsageLimit(request.auth.uid, tier, 'report');

  // Input validation
  const { weekData } = request.data || {};

  if (!weekData || typeof weekData !== 'object') {
    throw new HttpsError('invalid-argument', 'weekData must be an object');
  }

  if (Object.keys(weekData).length > 50) {
    throw new HttpsError('invalid-argument', 'weekData has too many fields');
  }

  // Sanitize weekData - only allow expected numeric/boolean values
  const sanitizedWeekData = {};
  for (const [key, value] of Object.entries(weekData)) {
    if (typeof value === 'number' || typeof value === 'boolean') {
      sanitizedWeekData[sanitizeForPrompt(key)] = value;
    }
  }

  const model = getGenAI().getGenerativeModel({
    model: "gemini-3-flash-preview",
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: RESPONSE_SCHEMA,
    },
  });

  const prompt = `
    You are a behavioral data analyst specializing in habit formation. Analyze the following weekly performance data and provide actionable insights.

    WEEKLY DATA (keys are metric names, values are numeric measurements):
    ${JSON.stringify(sanitizedWeekData)}

    ANALYSIS FRAMEWORK:
    1. Identify statistical patterns in completion timing and frequency
    2. Apply behavioral science principles to explain observed patterns
    3. Provide specific, actionable recommendations based on the data

    Provide:
    - "summary": A professional analysis of overall weekly performance (2-3 sentences, include specific percentages or metrics)
    - "pattern": One positive behavioral pattern identified with supporting evidence from the data
    - "improvement": One specific area for optimization with a concrete implementation strategy
    - "nextSteps": An array of 2-4 specific, actionable next steps. Each step should have:
      - "action": A specific, measurable action the user should take
      - "timeframe": "today", "this week", or "next week"
      - "priority": "high", "medium", or "low"

    Use evidence-based language (e.g., "Data shows...", "Your pattern indicates...", "Research suggests...").
    Format as JSON with keys: "summary", "pattern", "improvement", "nextSteps".
  `;

  let returnValue;
  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    validateGeminiResponse(text, "generateWeeklyInsights");
    const parsed = parseGeminiJSON(text);

    const VALID_NEXT_STEP_TIMEFRAMES = ['today', 'this week', 'next week'];
    const VALID_NEXT_STEP_PRIORITIES = ['high', 'medium', 'low'];
    const nextSteps = Array.isArray(parsed.nextSteps)
      ? parsed.nextSteps.filter(step => step && typeof step === 'object').slice(0, 4).map(step => ({
          action: String(step.action || '').substring(0, 300),
          timeframe: VALID_NEXT_STEP_TIMEFRAMES.includes(step.timeframe) ? step.timeframe : 'this week',
          priority: VALID_NEXT_STEP_PRIORITIES.includes(step.priority) ? step.priority : 'medium',
        }))
      : [];

    returnValue = {
      summary: String(parsed.summary || '').substring(0, 1000),
      pattern: String(parsed.pattern || '').substring(0, 500),
      improvement: String(parsed.improvement || '').substring(0, 500),
      nextSteps,
    };
  } catch (error) {
    console.error(`[generateWeeklyInsights] Error for user ${request.auth.uid}:`, error.message || error);
    throw new HttpsError("internal", "Failed to generate insights. Please try again.");
  }

  try {
    await recordUsage(request.auth.uid, 'report');
  } catch (usageError) {
    console.error(`[generateWeeklyInsights] Failed to record usage for ${request.auth.uid}:`, usageError.message);
  }
  return returnValue;
}

module.exports = generateWeeklyInsights;
