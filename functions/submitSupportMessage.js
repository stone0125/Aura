// =============================================================================
// submitSupportMessage.js — Support Message Submission
// 提交支持消息
//
// Handles user support requests (contact support, bug reports, feature
// requests). Saves to Firestore and sends email notification via SMTP.
//
// 处理用户支持请求（联系支持、错误报告、功能请求）。
// 保存到 Firestore 并通过 SMTP 发送邮件通知。
// =============================================================================

const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const {
  validateString,
  sanitizeEmailInput,
  VALID_SUPPORT_TYPES,
  SMTP_USER,
  smtpPassword,
} = require("./helpers");

/// Submit a support message and send email notification
/// 提交支持消息并发送邮件通知
async function submitSupportMessage(request) {
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
}

module.exports = submitSupportMessage;
