const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();

// Set global options for Gen 2 functions with rate limiting
setGlobalOptions({ 
  region: "us-central1",
  maxInstances: 10,        // Limit concurrent executions to prevent abuse
  timeoutSeconds: 60,      // Reasonable timeout for AI calls
});

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

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
  // Remove potential injection patterns
  return str
    .replace(/[<>{}[\]]/g, '')  // Remove brackets
    .replace(/\n{3,}/g, '\n\n') // Limit consecutive newlines
    .substring(0, 200);         // Limit length
}

// --- Cloud Functions ---

exports.generateHabitSuggestions = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Input validation
  const { categories, currentHabits } = request.data || {};
  
  const validatedCategories = validateArray(categories || [], 'categories', 10)
    .map(c => validateCategory(c));
  
  const validatedHabits = validateArray(currentHabits || [], 'currentHabits', 50)
    .map(h => sanitizeForPrompt(h));

  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const prompt = `
    I am a habit coach. The user is interested in these categories: ${validatedCategories.join(", ")}.
    They already have these habits: ${validatedHabits.join(", ")}.
    Suggest 3 new, specific habits they could start.
    Format the output as a JSON array of objects with keys: "habitName", "category", "explanation", "reason".
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Clean up potential markdown code blocks
    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(jsonStr);
  } catch (error) {
    console.error("Error generating suggestions:", error);
    throw new HttpsError("internal", "Failed to generate suggestions.");
  }
});

exports.generateWeeklyInsights = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Input validation
  const { weekData } = request.data || {};
  
  if (!weekData || typeof weekData !== 'object') {
    throw new HttpsError('invalid-argument', 'weekData must be an object');
  }
  
  // Sanitize weekData - only allow expected numeric/boolean values
  const sanitizedWeekData = {};
  for (const [key, value] of Object.entries(weekData)) {
    if (typeof value === 'number' || typeof value === 'boolean') {
      sanitizedWeekData[sanitizeForPrompt(key)] = value;
    }
  }

  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const prompt = `
    Analyze this weekly habit data: ${JSON.stringify(sanitizedWeekData)}.
    Provide a motivational summary, identify 1 positive pattern, and 1 area for improvement.
    Format as JSON with keys: "summary", "pattern", "improvement".
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(jsonStr);
  } catch (error) {
    console.error("Error generating insights:", error);
    throw new HttpsError("internal", "Failed to generate insights.");
  }
});

exports.generateHabitTips = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // No user input needed for this function - just generates general tips

  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const prompt = `
    Generate 6 unique, actionable habit coaching tips, distributed across these categories:
    - Getting Started
    - Staying Consistent
    - Overcoming Challenges
    - Advanced Strategies
    - Mindset & Motivation

    Format the output as a JSON array of objects with keys: 
    - "title": concise title
    - "content": 1-2 sentence explanation
    - "category": one of ["gettingStarted", "stayingConsistent", "overcomingChallenges", "advancedStrategies", "mindsetAndMotivation"]
    - "keyPoints": array of 3 short bullet points
    - "actionable": one specific action to take
    
    Ensure tips are distinct, psychological, and practical.
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(jsonStr);
  } catch (error) {
    console.error("Error generating tips:", error);
    throw new HttpsError("internal", "Failed to generate tips.");
  }
});

exports.generateHabitInsight = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Input validation
  const data = request.data || {};
  
  const habitName = sanitizeForPrompt(validateString(data.habitName || '', 'habitName', 100));
  const category = validateCategory(data.category || 'health');
  const currentStreak = validateNumber(data.currentStreak, 'currentStreak', 0, 10000);
  const totalCompletions = validateNumber(data.totalCompletions, 'totalCompletions', 0, 100000);
  const recentDays = validateNumber(data.recentDays, 'recentDays', 0, 7);

  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const prompt = `
    You are an encouraging habit coach. Analyze this habit and provide a brief, personalized insight.
    
    Habit: "${habitName}"
    Category: ${category}
    Current Streak: ${currentStreak} days
    Total Completions: ${totalCompletions}
    Recent Activity (last 7 days): ${recentDays} completions
    
    Provide a short, motivational insight (1-2 sentences max) that:
    - Acknowledges their progress or provides gentle encouragement
    - Is specific to their data (not generic)
    - Suggests one small improvement or celebrates consistency
    
    Format as JSON with keys:
    - "text": the insight message
    - "icon": one of ["trending_up", "emoji_events", "psychology", "timer", "favorite"]
    - "confidence": "high" if data is good, "medium" otherwise
    
    Do not include markdown formatting.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    const jsonStr = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(jsonStr);
  } catch (error) {
    console.error("Error generating habit insight:", error);
    throw new HttpsError("internal", "Failed to generate habit insight.");
  }
});
