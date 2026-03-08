// =============================================================================
// helpers.js — Shared Utilities for Cloud Functions
// 共享工具函数
//
// Contains input validation, prompt sanitization, subscription tier management,
// rate limiting, and burst protection used by all AI agent functions.
//
// 包含所有 AI 代理函数使用的输入验证、提示词清洗、订阅层级管理、
// 速率限制和突发保护功能。
// =============================================================================

const { HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

/// Secret definitions for external services
/// 外部服务的密钥定义
const smtpPassword = defineSecret("SMTP_PASSWORD");
const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");
const geminiApiKey = defineSecret("_API_KEY");

/// SMTP user email for support messages
/// 用于支持消息的 SMTP 用户邮箱
const SMTP_USER = "xiaostone0125@gmail.com";

/// Valid habit categories
/// 有效的习惯类别
const VALID_CATEGORIES = ['health', 'learning', 'productivity', 'mindfulness', 'fitness'];

/// Valid support message types
/// 有效的支持消息类型
const VALID_SUPPORT_TYPES = ['contact_support', 'bug_report', 'feature_request'];

/// Subscription tier rate limits
/// 订阅层级速率限制
const TIER_LIMITS = {
  starter: { maxAISuggestionsPerDay: 3, maxAIReportsPerMonth: 20 },
  growth:  { maxAISuggestionsPerDay: 5, maxAIReportsPerMonth: 30 },
  mastery: { maxAISuggestionsPerDay: -1, maxAIReportsPerMonth: -1 }, // unlimited
};

// --- Input Validation Helpers ---
// --- 输入验证辅助函数 ---

/// Initialize Gemini AI client (must be called inside function handlers where secret is available)
/// 初始化 Gemini AI 客户端（必须在密钥可用的函数处理器内调用）
function getGenAI() {
  return new GoogleGenerativeAI(geminiApiKey.value());
}

/// Validate a string field with max length
/// 验证字符串字段的最大长度
function validateString(value, fieldName, maxLength = 500) {
  if (typeof value !== 'string') {
    throw new HttpsError('invalid-argument', `${fieldName} must be a string`);
  }
  if (value.length > maxLength) {
    throw new HttpsError('invalid-argument', `${fieldName} exceeds maximum length of ${maxLength}`);
  }
  return value.trim();
}

/// Validate an array field with max item count
/// 验证数组字段的最大项目数
function validateArray(value, fieldName, maxItems = 50) {
  if (!Array.isArray(value)) {
    throw new HttpsError('invalid-argument', `${fieldName} must be an array`);
  }
  if (value.length > maxItems) {
    throw new HttpsError('invalid-argument', `${fieldName} exceeds maximum of ${maxItems} items`);
  }
  return value;
}

/// Validate a number field within min/max range
/// 验证数字字段是否在最小/最大范围内
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

/// Validate that a category is one of the allowed values
/// 验证类别是否为允许的值之一
function validateCategory(value) {
  if (!VALID_CATEGORIES.includes(value)) {
    throw new HttpsError('invalid-argument', `Invalid category. Must be one of: ${VALID_CATEGORIES.join(', ')}`);
  }
  return value;
}

/// Sanitize a string to prevent prompt injection attacks
/// 清洗字符串以防止提示词注入攻击
function sanitizeForPrompt(str) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/[<>{}[\]]/g, '')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/ignore\s+(all\s+)?(previous|prior|above)\s+(instructions?|prompts?|rules?)/gi, '')
    .replace(/you\s+are\s+now/gi, '')
    .replace(/system\s*:\s*/gi, '')
    .substring(0, 200);
}

/// Sanitize email fields to prevent CRLF header injection
/// 清洗邮件字段以防止 CRLF 头部注入
function sanitizeEmailInput(str) {
  if (typeof str !== 'string') return '';
  return str.replace(/[\r\n]/g, ' ').trim();
}

// --- Subscription Tier Helpers ---
// --- 订阅层级辅助函数 ---

/// Get the user's subscription tier (checks Firestore cache, then RevenueCat)
/// 获取用户的订阅层级（先检查 Firestore 缓存，然后查询 RevenueCat）
async function getUserTier(userId) {
  const db = admin.firestore();
  const cacheRef = db.collection('users').doc(userId);

  const cached = await cacheRef.get();
  const cachedData = cached.data();

  const VALID_TIERS = ['starter', 'growth', 'mastery'];
  if (cachedData?.tierOverride && VALID_TIERS.includes(cachedData.tierOverride)) {
    console.log(`getUserTier(${userId}): using Firestore override → ${cachedData.tierOverride}`);
    return cachedData.tierOverride;
  }

  if (cachedData?.tierCache?.tier &&
      cachedData?.tierCache?.expiresAt?.toDate() > new Date()) {
    console.log(`getUserTier(${userId}): using cache → ${cachedData.tierCache.tier}`);
    return cachedData.tierCache.tier;
  }

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
    }
  }

  if (!VALID_TIERS.includes(tier)) tier = 'starter';

  console.log(`getUserTier(${userId}): resolved from RevenueCat → ${tier}`);

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

/// Check usage limits and record usage atomically (prevents race condition bypass)
/// 检查使用限制并原子性地记录使用量（防止竞态条件绕过）
async function checkAndRecordUsage(userId, tier, usageType) {
  const limits = TIER_LIMITS[tier];
  const limit = usageType === 'suggestion'
    ? limits.maxAISuggestionsPerDay
    : limits.maxAIReportsPerMonth;

  if (limit === -1) return;

  const db = admin.firestore();
  const now = new Date();
  const periodKey = usageType === 'suggestion'
    ? now.toISOString().split('T')[0]
    : `${now.getFullYear()}-${now.getMonth()}`;

  const ref = db.collection('users').doc(userId)
    .collection('usageCounters').doc(`${usageType}_${periodKey}`);

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

/// Enforce a cooldown between consecutive AI requests (burst protection)
/// 在连续 AI 请求之间强制冷却时间（突发保护）
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

module.exports = {
  smtpPassword,
  revenueCatApiKey,
  geminiApiKey,
  SMTP_USER,
  VALID_CATEGORIES,
  VALID_SUPPORT_TYPES,
  TIER_LIMITS,
  getGenAI,
  validateString,
  validateArray,
  validateNumber,
  validateCategory,
  sanitizeForPrompt,
  sanitizeEmailInput,
  getUserTier,
  checkAndRecordUsage,
  checkBurstLimit,
};
