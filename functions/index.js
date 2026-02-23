const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const nodemailer = require("nodemailer");

const smtpPassword = defineSecret("SMTP_PASSWORD");
const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const SMTP_USER = "xiaostone0125@gmail.com";

admin.initializeApp();

// Set global options for Gen 2 functions with rate limiting
setGlobalOptions({ 
  region: "us-central1",
  maxInstances: 10,        // Limit concurrent executions to prevent abuse
  timeoutSeconds: 60,      // Reasonable timeout for AI calls
});

// Initialize Gemini (must be called inside function handlers where geminiApiKey secret is available)
function getGenAI() {
  return new GoogleGenerativeAI(geminiApiKey.value());
}

// --- Input Validation Helpers ---

const VALID_CATEGORIES = ['health', 'learning', 'productivity', 'mindfulness', 'fitness'];

function validateString(value, fieldName, maxLength = 500) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${fieldName} must be a string`);
  }
  if (value.length > maxLength) {
    throw new HttpsError('invalid-argument', `${fieldName} exceeds maximum length of ${maxLength}`);
  }
  return value.trim();
}

function validateArray(value, fieldName, maxItems = 50) {
  if (!Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `${fieldName} must be an array`);
  }
  if (value.length > maxItems) {
    throw new HttpsError('invalid-argument', `${fieldName} exceeds maximum of ${maxItems} items`);
  }
  return value;
}

function validateNumber(value, fieldName, min = 0, max = 10000) {
  const num = Number(value);
  if (isNaN(num)) {
    throw new HttpsError('invalid-argument', `${fieldName} must be a number`);
  }
  if (num < min || num > max) {
    throw new HttpsError('invalid-argument', `${fieldName} must be between ${min} and ${max}`);
  }
  return num;
}

function validateCategory(value) {
  if (!VALID_CATEGORIES.includes(value)) {
    throw new HttpsError('invalid-argument', `Invalid category. Must be one of: ${VALID_CATEGORIES.join(', ')}`);
  }
  return value;
}

// Sanitize string to prevent prompt injection
function sanitizeForPrompt(str) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/[<>{}[\]]/g, '')  // Remove brackets
    .replace(/\n{3,}/g, '\n\n') // Limit consecutive newlines
    .replace(/ignore\s+(all\s+)?(previous|prior|above)\s+(instructions?|prompts?|rules?)/gi, '')
    .replace(/you\s+are\s+now/gi, '')
    .replace(/system\s*:\s*/gi, '')
    .substring(0, 200);         // Limit length
}

// Sanitize email fields to prevent CRLF header injection
function sanitizeEmailInput(str) {
  if (typeof str !== 'string') return '';
  return str.replace(/[\r\n]/g, ' ').trim();
}

// --- Subscription Tier Helpers ---

const TIER_LIMITS = {
  starter: { maxAISuggestionsPerDay: 1, maxAIReportsPerMonth: 10 },
  growth:  { maxAISuggestionsPerDay: 5, maxAIReportsPerMonth: 30 },
  mastery: { maxAISuggestionsPerDay: -1, maxAIReportsPerMonth: -1 }, // unlimited
};

async function getUserTier(userId) {
  const db = admin.firestore();
  const cacheRef = db.collection('users').doc(userId);

  // Check for cached tier (5-minute TTL)
  const cached = await cacheRef.get();
  const cachedData = cached.data();
  if (cachedData?.tierCache?.tier &&
      cachedData?.tierCache?.expiresAt?.toDate() > new Date()) {
    return cachedData.tierCache.tier;
  }

  // Fetch from RevenueCat
  const resp = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${userId}`,
    { headers: { Authorization: `Bearer ${revenueCatApiKey.value()}` } }
  );

  let tier = 'starter';
  if (resp.ok) {
    try {
      const data = await resp.json();
      const entitlements = data.subscriber?.entitlements || {};
      if (entitlements.mastery?.expires_date &&
          new Date(entitlements.mastery.expires_date) > new Date()) {
        tier = 'mastery';
      } else if (entitlements.growth?.expires_date &&
          new Date(entitlements.growth.expires_date) > new Date()) {
        tier = 'growth';
      }
    } catch (parseErr) {
      console.error('RevenueCat response parse error:', parseErr.message);
      // tier stays 'starter'
    }
  }

  const VALID_TIERS = ['starter', 'growth', 'mastery'];
  if (!VALID_TIERS.includes(tier)) tier = 'starter';

  // Cache the result with 5-minute TTL
  await cacheRef.set({
    tierCache: {
      tier,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 5 * 60 * 1000)
      ),
    },
  }, { merge: true });

  return tier;
}

async function checkAndRecordUsage(userId, tier, usageType) {
  // usageType: 'suggestion' or 'report'
  const limits = TIER_LIMITS[tier];
  const limit = usageType === 'suggestion'
    ? limits.maxAISuggestionsPerDay
    : limits.maxAIReportsPerMonth;

  if (limit === -1) return; // unlimited

  const db = admin.firestore();
  const now = new Date();
  const periodKey = usageType === 'suggestion'
    ? now.toISOString().split('T')[0]           // daily: "2026-02-20"
    : `${now.getFullYear()}-${now.getMonth()}`;  // monthly: "2026-1"

  const ref = db.collection('users').doc(userId)
    .collection('usageCounters').doc(`${usageType}_${periodKey}`);

  // Atomic transaction to prevent race condition limit bypass
  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(ref);
    const currentCount = doc.exists ? doc.data().count : 0;

    if (currentCount >= limit) {
      throw new HttpsError('resource-exhausted',
        `${usageType === 'suggestion' ? 'Daily AI suggestion' : 'Monthly AI report'} limit reached for your plan. Upgrade for more.`);
    }

    transaction.set(ref, {
      count: currentCount + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

async function checkBurstLimit(userId, functionName, cooldownMs = 5000) {
  const db = admin.firestore();
  const ref = db.collection('users').doc(userId)
    .collection('usageCounters').doc(`lastAIRequest_${functionName}`);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(ref);
    if (doc.exists) {
      const lastRequest = doc.data().timestamp?.toDate();
      if (lastRequest && (Date.now() - lastRequest.getTime()) < cooldownMs) {
        throw new HttpsError('resource-exhausted',
          'Please wait a few seconds between AI requests.');
      }
    }
    transaction.set(ref, { timestamp: admin.firestore.FieldValue.serverTimestamp() });
  });
}

// --- Cloud Functions ---

exports.generateHabitSuggestions = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'suggestions');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'suggestion');

  // Input validation
  const { categories, currentHabits, userStats } = request.data || {};
  
  const validatedCategories = validateArray(categories || [], 'categories', 10)
    .map(c => validateCategory(c));
  
  const validatedHabits = validateArray(currentHabits || [], 'currentHabits', 50)
    .map(h => sanitizeForPrompt(h));

  // Extract user stats for personalization (with defaults)
  const completionRate = validateNumber(userStats?.completionRate ?? 0, 'completionRate', 0, 100);
  const bestStreak = validateNumber(userStats?.bestStreak ?? 0, 'bestStreak', 0, 10000);
  const totalHabits = validateNumber(userStats?.totalHabits ?? 0, 'totalHabits', 0, 100);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  // Build personalized prompt based on user data
  let userContext = '';
  if (totalHabits > 0) {
    userContext = `
    Current User Performance Metrics:
    - Active habit portfolio: ${totalHabits} habits
    - Overall completion rate: ${completionRate.toFixed(1)}%
    - Best streak achieved: ${bestStreak} days
    - Performance tier: ${completionRate >= 80 ? 'High Performer' : completionRate >= 50 ? 'Building Consistency' : 'Foundation Phase'}
    `;
  }

  const prompt = `
    You are a behavioral psychologist and habit formation specialist. Analyze the user's profile and provide evidence-based habit recommendations.

    USER PROFILE:
    - Interest categories: ${validatedCategories.join(", ")}
    - Current habits: ${validatedHabits.length > 0 ? validatedHabits.join(", ") : "No habits yet (new user)"}
    ${userContext}

    ANALYSIS REQUIREMENTS:
    1. Apply habit stacking principles (Fogg Behavior Model) to suggest habits that complement existing routines
    2. Consider the user's current capacity based on completion rate
    3. Ensure variety across categories while maintaining focus
    ${completionRate < 50 ? '4. IMPORTANT: User shows inconsistency patterns. Recommend micro-habits (2-5 min) with low friction.' : ''}
    ${completionRate > 80 ? '4. IMPORTANT: User demonstrates strong consistency. Recommend challenging habits that build on existing momentum.' : ''}
    ${totalHabits === 0 ? '4. IMPORTANT: First-time user. Recommend beginner-friendly habits with immediate rewards and clear implementation intentions.' : ''}

    Suggest exactly 3 new, specific habits that:
    - Have clear implementation triggers
    - Build on existing habits when possible
    - Match the user's demonstrated capacity level

    Format as JSON array with keys: "habitName", "category", "explanation", "reason".
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    if (!Array.isArray(parsed)) throw new Error('Expected array');
    return parsed.slice(0, 5).map(item => ({
      habitName: String(item.habitName || '').substring(0, 100),
      category: VALID_CATEGORIES.includes(item.category) ? item.category : 'health',
      explanation: String(item.explanation || '').substring(0, 500),
      reason: String(item.reason || '').substring(0, 500),
    }));
  } catch (error) {
    console.error("Error generating suggestions:", error);
    throw new HttpsError("internal", "Failed to generate suggestions.");
  }
});

exports.generateWeeklyInsights = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'insights');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

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

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  const prompt = `
    You are a behavioral data analyst specializing in habit formation. Analyze the following weekly performance data and provide actionable insights.

    WEEKLY DATA:
    ${JSON.stringify(sanitizedWeekData)}

    ANALYSIS FRAMEWORK:
    1. Identify statistical patterns in completion timing and frequency
    2. Apply behavioral science principles to explain observed patterns
    3. Provide specific, actionable recommendations based on the data

    Provide:
    - "summary": A professional analysis of overall weekly performance (2-3 sentences, include specific percentages or metrics)
    - "pattern": One positive behavioral pattern identified with supporting evidence from the data
    - "improvement": One specific area for optimization with a concrete implementation strategy

    Use evidence-based language (e.g., "Data shows...", "Your pattern indicates...", "Research suggests...").
    Format as JSON with keys: "summary", "pattern", "improvement".
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    return {
      summary: String(parsed.summary || '').substring(0, 1000),
      pattern: String(parsed.pattern || '').substring(0, 500),
      improvement: String(parsed.improvement || '').substring(0, 500),
    };
  } catch (error) {
    console.error("Error generating insights:", error);
    throw new HttpsError("internal", "Failed to generate insights.");
  }
});

exports.generateHabitTips = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'tips');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  // Extract user data for personalization (optional)
  const { userHabits, completionRate, bestStreak, totalCompletions } = request.data || {};
  
  const habits = validateArray(userHabits || [], 'userHabits', 50)
    .map(h => sanitizeForPrompt(h));
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

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    const VALID_TIP_CATEGORIES = ['gettingStarted', 'stayingConsistent', 'overcomingChallenges', 'advancedStrategies', 'mindsetAndMotivation'];
    if (!Array.isArray(parsed)) throw new Error('Expected array');
    return parsed.slice(0, 20).map(item => ({
      title: String(item.title || '').substring(0, 100),
      content: String(item.content || '').substring(0, 500),
      category: VALID_TIP_CATEGORIES.includes(item.category) ? item.category : 'gettingStarted',
      keyPoints: Array.isArray(item.keyPoints) ? item.keyPoints.slice(0, 5).map(p => String(p).substring(0, 200)) : [],
      actionable: String(item.actionable || '').substring(0, 300),
    }));
  } catch (error) {
    console.error("Error generating tips:", error);
    throw new HttpsError("internal", "Failed to generate tips.");
  }
});

exports.generateHabitInsight = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
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
    console.error("Error generating habit insight:", error);
    throw new HttpsError("internal", "Failed to generate habit insight.");
  }
});

// ==================== Action Items ====================

exports.generateActionItems = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'actions');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

  const { habits, completionRate, bestStreak } = request.data || {};

  const validatedHabits = validateArray(habits || [], 'habits', 50);
  const rate = validateNumber(completionRate ?? 0, 'completionRate', 0, 100);
  const streak = validateNumber(bestStreak ?? 0, 'bestStreak', 0, 10000);

  const model = getGenAI().getGenerativeModel({ model: "gemini-3-flash-preview" });

  const habitsDetail = validatedHabits.filter(h => h && typeof h === 'object').map(h =>
    `- ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): streak ${Number(h.streak) || 0}, ${h.completed ? 'completed' : 'incomplete'}`
  ).join('\n');

  const performanceTier = rate >= 80 ? 'High Performer' : rate >= 50 ? 'Developing' : 'Foundation Building';

  const prompt = `
    You are a behavioral coach creating personalized daily and weekly action items based on the user's actual habit data.

    USER PROFILE:
    - Performance tier: ${performanceTier}
    - Completion rate: ${rate.toFixed(1)}%
    - Best streak: ${streak} days
    - Active habits:
    ${habitsDetail || 'No habits yet'}

    Generate exactly 5-7 personalized action items:
    - 3 daily actions (things to do today)
    - 2 weekly actions (goals for this week)
    - 1-2 challenge actions (stretch goals)

    Each action must be:
    - Specific and measurable (not vague)
    - Based on the user's actual habits and performance
    - Achievable given their current level

    ${rate < 50 ? 'Focus on building consistency with micro-habits and reducing friction.' : ''}
    ${rate >= 80 ? 'Include advanced optimization and stretch goals.' : ''}
    ${streak < 3 ? 'Emphasize streak building and habit anchoring.' : ''}

    Format as JSON array:
    [
      {
        "title": "<specific actionable title>",
        "description": "<why this matters, 1-2 sentences>",
        "type": "daily" | "weekly" | "challenge",
        "priority": "high" | "medium" | "low",
        "relatedHabit": "<name of related habit or null>",
        "metric": "<specific measurable target>"
      }
    ]

    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

    const VALID_ACTION_TYPES = ['daily', 'weekly', 'challenge'];
    const VALID_PRIORITIES = ['high', 'medium', 'low'];
    if (!Array.isArray(parsed)) throw new Error('Expected array');
    return parsed.slice(0, 10).map(item => ({
      title: String(item.title || '').substring(0, 200),
      description: String(item.description || '').substring(0, 500),
      type: VALID_ACTION_TYPES.includes(item.type) ? item.type : 'daily',
      priority: VALID_PRIORITIES.includes(item.priority) ? item.priority : 'medium',
      relatedHabit: item.relatedHabit ? String(item.relatedHabit).substring(0, 100) : null,
      metric: String(item.metric || '').substring(0, 200),
    }));
  } catch (error) {
    console.error("Error generating action items:", error);
    throw new HttpsError("internal", "Failed to generate action items.");
  }
});

// ==================== Pattern Discovery ====================

const VALID_PATTERN_TYPES = ['timeOfDay', 'dayOfWeek', 'sequence', 'trigger'];
const VALID_ICON_NAMES = ['schedule', 'wb_sunny', 'nightlight', 'calendar_today', 'weekend', 'link', 'repeat', 'bolt', 'insights'];

exports.generatePatternDiscovery = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
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

  // Minimum threshold gate — avoid calling Gemini with insufficient data
  if (validatedHabits.length < 2) {
    return { patterns: [], reason: 'insufficient_data' };
  }

  let totalCompletions = 0;
  const habitsDetail = validatedHabits.map(h => {
    const dates = Array.isArray(h.completionDates)
      ? h.completionDates.filter(d => typeof d === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(d))
      : [];
    totalCompletions += dates.length;
    return `- ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): streak ${Number(h.streak) || 0}, reminder ${sanitizeForPrompt(h.reminderTime || 'none')}, completions: [${dates.slice(0, 60).join(', ')}]`;
  }).join('\n');

  if (totalCompletions < 5) {
    return { patterns: [], reason: 'insufficient_data' };
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

    // Validate and sanitize each pattern
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
    console.error("Error generating pattern discovery:", error);
    throw new HttpsError("internal", "Failed to generate pattern discovery.");
  }
});

// ==================== AI Scoring Functions ====================

/**
 * Generate a comprehensive score (1-100) for an individual habit
 * Analyzes consistency, momentum, resilience, and engagement
 */
exports.generateHabitScore = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
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

  const prompt = `
    You are a behavioral analytics expert. Generate a comprehensive performance score for this habit.

    HABIT DATA:
    - Name: "${habitName}"
    - Category: ${category}
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
    console.error("Error generating habit score:", error);
    throw new HttpsError("internal", "Failed to generate habit score.");
  }
});

/**
 * Generate a comprehensive daily review with AI coach commentary
 */
exports.generateDailyReview = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
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

  const habitsDetail = habits.map(h =>
    `- ${sanitizeForPrompt(h.name || '')} (${VALID_CATEGORIES.includes(h.category) ? h.category : 'general'}): ${h.completed ? 'Completed' : 'Incomplete'}, Streak: ${Number(h.streak) || 0}`
  ).join('\n');

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
    console.error("Error generating daily review:", error);
    throw new HttpsError("internal", "Failed to generate daily review.");
  }
});

/**
 * Analyze correlations between health metrics and habit completion
 */
exports.generateHealthCorrelations = onCall({ secrets: [revenueCatApiKey, geminiApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  await checkBurstLimit(request.auth.uid, 'correlations');
  const tier = await getUserTier(request.auth.uid);
  await checkAndRecordUsage(request.auth.uid, tier, 'report');

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
    avgSteps: healthData.reduce((a, b) => a + (b.steps || 0), 0) / healthData.length,
    avgSleep: healthData.reduce((a, b) => a + (b.sleepHours || 0), 0) / healthData.length,
    avgHeartRate: healthData.reduce((a, b) => a + (b.heartRate || 0), 0) / healthData.length,
    avgActiveMinutes: healthData.reduce((a, b) => a + (b.activeMinutes || 0), 0) / healthData.length
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

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(jsonStr);

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

    return {
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
    console.error("Error generating health correlations:", error);
    throw new HttpsError("internal", "Failed to generate health correlations.");
  }
});

// ==================== Support Message Submission ====================

const VALID_SUPPORT_TYPES = ['contact_support', 'bug_report', 'feature_request'];

exports.submitSupportMessage = onCall({ secrets: [smtpPassword] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const data = request.data || {};

  // Validate type
  const type = data.type;
  if (!VALID_SUPPORT_TYPES.includes(type)) {
    throw new HttpsError('invalid-argument', `type must be one of: ${VALID_SUPPORT_TYPES.join(', ')}`);
  }

  // Validate required fields
  const subject = validateString(data.subject || '', 'subject', 200);
  const message = validateString(data.message || '', 'message', 5000);
  if (!subject) {
    throw new HttpsError('invalid-argument', 'subject is required');
  }
  if (!message) {
    throw new HttpsError('invalid-argument', 'message is required');
  }

  // Optional fields
  const category = validateString(data.category || '', 'category', 100);
  const deviceInfo = validateString(data.deviceInfo || '', 'deviceInfo', 500);

  const userId = request.auth.uid;
  const userEmail = request.auth.token.email || 'unknown';

  // Save to Firestore
  const docData = {
    userId,
    userEmail,
    type,
    subject,
    message,
    category,
    deviceInfo,
    status: 'new',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const docRef = await admin.firestore().collection('supportMessages').add(docData);

  // Send email notification (non-fatal)
  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: SMTP_USER,
        pass: smtpPassword.value(),
      },
    });

    const typeLabels = {
      contact_support: 'Contact Support',
      bug_report: 'Bug Report',
      feature_request: 'Feature Request',
    };

    const emailBody = [
      `Type: ${typeLabels[type]}`,
      `From: ${sanitizeEmailInput(userEmail)} (${userId})`,
      category ? `Category: ${sanitizeEmailInput(category)}` : null,
      `Subject: ${sanitizeEmailInput(subject)}`,
      '',
      sanitizeEmailInput(message),
      deviceInfo ? `\n--- Device Info ---\n${sanitizeEmailInput(deviceInfo)}` : null,
      `\nFirestore doc: supportMessages/${docRef.id}`,
    ].filter(Boolean).join('\n');

    await transporter.sendMail({
      from: `"Aura Support" <${SMTP_USER}>`,
      to: SMTP_USER,
      subject: `[Aura ${typeLabels[type]}] ${sanitizeEmailInput(subject)}`,
      text: emailBody,
    });
  } catch (emailError) {
    console.error('Email notification failed (non-fatal):', emailError.message);
  }

  return { success: true, messageId: docRef.id };
});

// ==================== Daily Summary Notifications ====================

const { onSchedule } = require("firebase-functions/v2/scheduler");

/**
 * Scheduled function that runs every hour to send daily summary notifications
 * Checks each user's notification preferences and sends FCM if it's their scheduled time
 */
exports.sendDailySummaries = onSchedule({
  schedule: "every 1 hours",
  timeZone: "UTC",
  retryCount: 0,
}, async (event) => {
  const db = admin.firestore();
  const messaging = admin.messaging();
  
  // Get current time in UTC
  const now = new Date();
  const currentUtcHour = now.getUTCHours();
  
  console.log(`Running daily summary check at UTC hour ${currentUtcHour}`);
  
  try {
    // Get all users with notification preferences
    const usersSnapshot = await db.collection('users')
      .where('notificationPrefs.dailySummaryEnabled', '==', true)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('No users with enabled daily summaries');
      return;
    }
    
    let notificationsSent = 0;
    const matchingUsers = [];

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const prefs = userData.notificationPrefs;
      const fcmTokens = userData.fcmTokens || [];
      
      if (!prefs || fcmTokens.length === 0) continue;
      
      // Calculate user's local time based on their timezone
      const userTimezone = prefs.timezone || 'UTC';
      let userHour;
      
      try {
        // Try IANA timezone format first (e.g., "Asia/Singapore")
        const userLocalTime = new Date(now.toLocaleString('en-US', { timeZone: userTimezone }));
        userHour = userLocalTime.getHours();
      } catch (tzError) {
        // Fallback: Use UTC+8 for Malaysia/Singapore if timezone parse fails
        console.log(`Timezone parse failed for "${userTimezone}", using UTC+8 fallback`);
        const utc8Offset = 8 * 60 * 60 * 1000; // 8 hours in ms
        const userLocalTime = new Date(now.getTime() + utc8Offset);
        userHour = userLocalTime.getUTCHours();
      }
      
      // Check if it's the user's scheduled notification hour
      if (userHour === prefs.dailySummaryHour) {
        console.log(`Time match for user: hour ${userHour}`);
        // Count habits NOT completed today in user's timezone
        // (runs in parallel below via matchingUsers)
        matchingUsers.push({ userDoc, userTimezone, fcmTokens, userHour });
      }
    }

    // Parallelize habit queries for all matching users (fixes N+1 sequential query)
    await Promise.all(matchingUsers.map(async ({ userDoc, userTimezone, fcmTokens, userHour }) => {
      try {
        const habitsSnapshot = await db.collection('users').doc(userDoc.id)
          .collection('habits')
          .get();

        let habitCount = 0;
        let todayLocal;
        try {
          todayLocal = new Date(now.toLocaleString('en-US', { timeZone: userTimezone }));
        } catch (tzError) {
          // Fallback: Use UTC+8 if timezone is invalid
          console.log(`todayLocal timezone parse failed for "${userTimezone}", using UTC+8 fallback`);
          const utc8Offset = 8 * 60 * 60 * 1000;
          todayLocal = new Date(now.getTime() + utc8Offset);
        }
        for (const habitDoc of habitsSnapshot.docs) {
          const data = habitDoc.data();
          const lastCompleted = data.lastCompletedDate?.toDate();
          if (!lastCompleted) {
            habitCount++;
          } else {
            let completedLocal;
            try {
              completedLocal = new Date(lastCompleted.toLocaleString('en-US', { timeZone: userTimezone }));
            } catch (tzError) {
              const utc8Offset = 8 * 60 * 60 * 1000;
              completedLocal = new Date(lastCompleted.getTime() + utc8Offset);
            }
            if (completedLocal.getFullYear() !== todayLocal.getFullYear() ||
                completedLocal.getMonth() !== todayLocal.getMonth() ||
                completedLocal.getDate() !== todayLocal.getDate()) {
              habitCount++;
            }
          }
        }

        // Build notification
        let title, body;
        if (userHour < 12) {
          title = 'Good morning! ☀️';
        } else if (userHour < 17) {
          title = 'Good afternoon! 👋';
        } else {
          title = 'Good evening! 🌙';
        }
        
        if (habitCount === 0) {
          body = "You're all caught up! No habits to complete today.";
        } else if (habitCount === 1) {
          body = "You have 1 habit to complete today. Let's do it! 💪";
        } else {
          body = `You have ${habitCount} habits to complete today. Let's go! 💪`;
        }
        
        // Send to all user's devices
        const message = {
          notification: { title, body },
          data: { type: 'daily_summary', habitCount: String(habitCount) },
          tokens: fcmTokens,
        };
        
        try {
          const response = await messaging.sendEachForMulticast(message);
          console.log(`Notification sent: ${response.successCount} success, ${response.failureCount} failed`);
          notificationsSent++;
          
          // Remove invalid tokens
          if (response.failureCount > 0) {
            const invalidTokens = [];
            response.responses.forEach((resp, idx) => {
              if (!resp.success && resp.error?.code === 'messaging/registration-token-not-registered') {
                invalidTokens.push(fcmTokens[idx]);
              }
            });
            if (invalidTokens.length > 0) {
              await db.collection('users').doc(userDoc.id).update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
              });
              console.log(`Removed ${invalidTokens.length} invalid tokens`);
            }
          }
        } catch (sendError) {
          console.error(`Error sending notification:`, sendError);
        }
      } catch (userError) {
        console.error(`Error processing user ${userDoc.id}:`, userError);
      }
    }));

    console.log(`Daily summary check complete. Sent ${notificationsSent} notifications.`);
  } catch (error) {
    console.error('Error in sendDailySummaries:', error);
  }
});
