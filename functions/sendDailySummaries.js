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
    // Paginate users query to avoid loading all users into memory at once
    // 分页查询用户，避免一次性加载所有用户到内存中
    const PAGE_SIZE = 50;
    const CONCURRENCY_LIMIT = 10;
    let notificationsSent = 0;
    let lastDoc = null;
    let hasMore = true;

    while (hasMore) {
      let query = db.collection('users')
        .where('notificationPrefs.dailySummaryEnabled', '==', true)
        .limit(PAGE_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const usersSnapshot = await query.get();

      if (usersSnapshot.empty) {
        if (!lastDoc) console.log('No users with enabled daily summaries');
        break;
      }

      hasMore = usersSnapshot.docs.length === PAGE_SIZE;
      lastDoc = usersSnapshot.docs[usersSnapshot.docs.length - 1];

      const matchingUsers = [];

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const prefs = userData.notificationPrefs;
        const fcmTokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];

        if (!prefs || fcmTokens.length === 0) continue;

        // Calculate user's local time based on their timezone
        const userTimezone = prefs.timezone || 'UTC';
        let userHour;

        try {
          const userLocalTime = new Date(now.toLocaleString('en-US', { timeZone: userTimezone }));
          userHour = userLocalTime.getHours();
        } catch (tzError) {
          console.warn(`Skipping user ${userDoc.id}: timezone parse failed for "${userTimezone}"`);
          continue;
        }

        // Check if it's the user's scheduled notification hour
        const scheduledHour = typeof prefs.dailySummaryHour === 'number' ? prefs.dailySummaryHour : 20;
        if (userHour === scheduledHour) {
          console.log(`Time match for user: hour ${userHour}`);
          matchingUsers.push({ userDoc, userTimezone, fcmTokens, userHour });
        }
      }

      // Process matching users in batches with concurrency limit
      // 以并发限制批量处理匹配的用户
      for (let i = 0; i < matchingUsers.length; i += CONCURRENCY_LIMIT) {
        const batch = matchingUsers.slice(i, i + CONCURRENCY_LIMIT);
        await Promise.all(batch.map(async ({ userDoc, userTimezone, fcmTokens, userHour }) => {
          try {
            // Timezone was already validated in the matching loop above — safe to use directly
            const todayLocal = new Date(now.toLocaleString('en-US', { timeZone: userTimezone }));

            // Duplicate notification guard (atomic check-and-set to prevent TOCTOU race)
            // 重复通知保护（原子检查和设置，防止 TOCTOU 竞态条件）
            const todayStr = todayLocal.toISOString().split('T')[0];
            const userRef = db.collection('users').doc(userDoc.id);
            const shouldSend = await db.runTransaction(async (tx) => {
              const snap = await tx.get(userRef);
              if (snap.data()?.lastDailySummaryDate === todayStr) return false;
              tx.update(userRef, { lastDailySummaryDate: todayStr });
              return true;
            });
            if (!shouldSend) return;

            const habitsSnapshot = await db.collection('users').doc(userDoc.id)
              .collection('habits')
              .limit(200)
              .get();

            let habitCount = 0;
            const todayDayOfWeek = todayLocal.getDay(); // 0=Sunday
            for (const habitDoc of habitsSnapshot.docs) {
              const data = habitDoc.data();

              // Skip weekly habits not due today
              if (data.frequencyType === 'weekly') {
                if (!Array.isArray(data.weeklyDays) || !data.weeklyDays.includes(todayDayOfWeek)) continue;
              }

              const lastCompleted = data.lastCompletedDate?.toDate();
              if (!lastCompleted) {
                habitCount++;
              } else {
                // Timezone already validated in outer loop — safe to use directly
                const completedLocal = new Date(lastCompleted.toLocaleString('en-US', { timeZone: userTimezone }));
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
      } // end concurrency batch loop
    } // end while pagination loop

    console.log(`Daily summary check complete. Sent ${notificationsSent} notifications.`);
  } catch (error) {
    console.error('Error in sendDailySummaries:', error);
  }
}

module.exports = sendDailySummaries;
