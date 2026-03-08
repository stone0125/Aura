// =============================================================================
// index.js — Firebase Cloud Functions Entry Point
// Firebase Cloud Functions 入口文件
//
// Registers all Cloud Functions by importing individual agent modules from
// the agents/ directory. Each agent handles one AI feature or service.
// Shared utilities (validation, auth, rate limiting) live in helpers.js.
//
// 通过从 agents/ 目录导入各个代理模块来注册所有 Cloud Functions。
// 每个代理处理一个 AI 功能或服务。
// 共享工具函数（验证、认证、速率限制）在 helpers.js 中。
//
// Agent files:
// - generateHabitSuggestions: AI habit recommendations (AI 习惯建议)
// - generateWeeklyInsights: Weekly summary and analysis (每周洞察与分析)
// - generatePatternDiscovery: Detect patterns in completion data (模式发现)
// - generateHabitTips: Category-based tips (分类技巧)
// - generateActionItems: Personalized action items (个性化行动项)
// - generateHabitScore: Score a habit across 4 dimensions (习惯评分)
// - generateDailyReview: Daily performance review (每日回顾)
// - generateHabitInsight: Single habit AI insight (单个习惯洞察)
// - generateHealthCorrelations: Health-habit correlation analysis (健康关联分析)
// - submitSupportMessage: Send support emails (提交支持消息)
// - sendDailySummaries: Scheduled push notifications (定时推送通知)
// =============================================================================

const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const { revenueCatApiKey, geminiApiKey, smtpPassword } = require("./helpers");

// --- Import agent handlers ---
// --- 导入代理处理函数 ---
const generateHabitSuggestions = require("./agents/generateHabitSuggestions");
const generateWeeklyInsights = require("./agents/generateWeeklyInsights");
const generateHabitTips = require("./agents/generateHabitTips");
const generateHabitInsight = require("./agents/generateHabitInsight");
const generateActionItems = require("./agents/generateActionItems");
const generatePatternDiscovery = require("./agents/generatePatternDiscovery");
const generateHabitScore = require("./agents/generateHabitScore");
const generateDailyReview = require("./agents/generateDailyReview");
const generateHealthCorrelations = require("./agents/generateHealthCorrelations");
const submitSupportMessage = require("./agents/submitSupportMessage");
const sendDailySummariesHandler = require("./agents/sendDailySummaries");

/// Initialize Firebase Admin SDK
/// 初始化 Firebase Admin SDK
admin.initializeApp();

/// Set global options for Gen 2 functions with rate limiting
/// 设置 Gen 2 函数的全局选项和速率限制
setGlobalOptions({
  region: "us-central1",
  maxInstances: 10,
  timeoutSeconds: 60,
});

// =============================================================================
// AI Agent Cloud Functions — each wraps an agent handler with onCall
// AI 代理 Cloud Functions — 每个用 onCall 包装一个代理处理函数
// =============================================================================

/// AI habit suggestions based on user profile and performance
/// 基于用户资料和表现的 AI 习惯建议
exports.generateHabitSuggestions = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateHabitSuggestions
);

/// Weekly performance analysis and insights
/// 每周表现分析和洞察
exports.generateWeeklyInsights = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateWeeklyInsights
);

/// Evidence-based coaching tips organized by skill level
/// 按技能级别组织的循证教练技巧
exports.generateHabitTips = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateHabitTips
);

/// Single habit AI insight with metrics analysis
/// 带指标分析的单个习惯 AI 洞察
exports.generateHabitInsight = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateHabitInsight
);

/// Personalized daily/weekly/challenge action items
/// 个性化的每日/每周/挑战行动项
exports.generateActionItems = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateActionItems
);

/// Behavioral pattern discovery from completion data
/// 从完成数据中发现行为模式
exports.generatePatternDiscovery = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generatePatternDiscovery
);

/// Comprehensive habit scoring across 4 dimensions
/// 4 个维度的综合习惯评分
exports.generateHabitScore = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateHabitScore
);

/// Daily performance review with coach commentary
/// 带教练评语的每日表现回顾
exports.generateDailyReview = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateDailyReview
);

/// Health-habit correlation analysis
/// 健康与习惯关联分析
exports.generateHealthCorrelations = onCall(
  { secrets: [revenueCatApiKey, geminiApiKey], timeoutSeconds: 300 },
  generateHealthCorrelations
);

/// Support message submission with email notification
/// 支持消息提交和邮件通知
exports.submitSupportMessage = onCall(
  { secrets: [smtpPassword] },
  submitSupportMessage
);

// =============================================================================
// Scheduled Functions
// 定时函数
// =============================================================================

/// Hourly check to send daily summary push notifications
/// 每小时检查并发送每日摘要推送通知
exports.sendDailySummaries = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "UTC",
    retryCount: 0,
  },
  sendDailySummariesHandler
);
