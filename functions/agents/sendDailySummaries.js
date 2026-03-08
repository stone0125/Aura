// =============================================================================
// sendDailySummaries.js — Scheduled Daily Summary Notifications
// 定时每日摘要通知
//
// Scheduled function that runs every hour to send daily summary push
// notifications via FCM. Checks each user's timezone and notification
// preferences to send at their configured local time.
//
// 每小时运行一次的定时函数，通过 FCM 发送每日摘要推送通知。
// 检查每个用户的时区和通知偏好，在其配置的本地时间发送。
// =============================================================================

const admin = require("firebase-admin");

/// Send daily summary notifications to users at their scheduled time
/// 在用户的预定时间发送每日摘要通知
async function sendDailySummaries(event) {
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
        const userLocalTime = new Date(now.toLocaleString('en-US', { timeZone: userTimezone }));
        userHour = userLocalTime.getHours();
      } catch (tzError) {
        console.log(`Timezone parse failed for "${userTimezone}", using UTC+8 fallback`);
        const utc8Offset = 8 * 60 * 60 * 1000;
        const userLocalTime = new Date(now.getTime() + utc8Offset);
        userHour = userLocalTime.getUTCHours();
      }

      // Check if it's the user's scheduled notification hour
      if (userHour === prefs.dailySummaryHour) {
        console.log(`Time match for user: hour ${userHour}`);
        matchingUsers.push({ userDoc, userTimezone, fcmTokens, userHour });
      }
    }

    // Parallelize habit queries for all matching users
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
}

module.exports = sendDailySummaries;
