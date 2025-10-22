const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Helper to format period ids
function toDailyId(ts) {
  const d = ts.toDate ? ts.toDate() : ts;
  const yr = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${yr}-${m}-${day}`;
}

function toMonthlyId(ts) {
  const d = ts.toDate ? ts.toDate() : ts;
  const yr = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  return `${yr}-${m}`;
}

function toYearlyId(ts) {
  const d = ts.toDate ? ts.toDate() : ts;
  return `${d.getUTCFullYear()}`;
}

// ISO week calculation
function toWeekId(ts) {
  const d = ts.toDate ? ts.toDate() : ts;
  // Copy date so don't modify original
  const date = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  // Set to nearest Thursday: current date + 4 - current day number
  const dayNum = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - dayNum);
  // Year of the Thursday
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(),0,1));
  const weekNo = Math.ceil((((date - yearStart) / 86400000) + 1)/7);
  return `${date.getUTCFullYear()}-W${String(weekNo).padStart(2,'0')}`;
}

exports.onExerciseHistory = functions.firestore
  .document('users/{uid}/exerciseHistory/{eventId}')
  .onCreate(async (snap, context) => {
    const { uid } = context.params;
    const data = snap.data() || {};
    const completedAt = data.completedAt || data.createdAt || admin.firestore.Timestamp.now();

    const dailyId = toDailyId(completedAt);
    const weeklyId = toWeekId(completedAt);
    const monthlyId = toMonthlyId(completedAt);
    const yearlyId = toYearlyId(completedAt);

    const batch = db.batch();

    const inc = admin.firestore.FieldValue.increment(1);

    const base = db.collection('users').doc(uid).collection('summaries');
    batch.set(base.doc(`daily-${dailyId}`), { totalCompleted: inc, lastUpdated: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    batch.set(base.doc(`weekly-${weeklyId}`), { totalCompleted: inc, lastUpdated: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    batch.set(base.doc(`monthly-${monthlyId}`), { totalCompleted: inc, lastUpdated: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    batch.set(base.doc(`yearly-${yearlyId}`), { totalCompleted: inc, lastUpdated: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

    // Optionally increment per-exercise counters
    if (data.exerciseId) {
      const exKey = `byExercise.${data.exerciseId}`;
      batch.set(base.doc(`daily-${dailyId}`), { [exKey]: inc }, { merge: true });
      batch.set(base.doc(`weekly-${weeklyId}`), { [exKey]: inc }, { merge: true });
      batch.set(base.doc(`monthly-${monthlyId}`), { [exKey]: inc }, { merge: true });
      batch.set(base.doc(`yearly-${yearlyId}`), { [exKey]: inc }, { merge: true });
    }

    await batch.commit();
    return null;
  });

// Send push notification to user
exports.sendNotification = functions.https.onCall(async (data, context) => {
  try {
    const { recipientId, title, message, type, additionalData } = data;
    
    // Validate required fields
    if (!recipientId || !title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Get user's FCM token
    const userDoc = await db.collection('users').doc(recipientId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'User has no FCM token');
    }

    // Create notification document in Firestore
    const notificationData = {
      title,
      message,
      type: type || 'general',
      recipient_id: recipientId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread',
      additionalData: additionalData || {},
    };

    const notificationRef = await db.collection('notifications').add(notificationData);

    // Send FCM message
    const payload = {
      notification: {
        title,
        body: message,
      },
      data: {
        type: type || 'general',
        notificationId: notificationRef.id,
        ...additionalData,
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(payload);
    console.log('Successfully sent message:', response);

    return { success: true, notificationId: notificationRef.id };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

// Send notification to multiple users
exports.sendNotificationToMultiple = functions.https.onCall(async (data, context) => {
  try {
    const { recipientIds, title, message, type, additionalData } = data;
    
    // Validate required fields
    if (!recipientIds || !Array.isArray(recipientIds) || recipientIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'recipientIds must be a non-empty array');
    }
    
    if (!title || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    const results = [];
    
    for (const recipientId of recipientIds) {
      try {
        // Get user's FCM token
        const userDoc = await db.collection('users').doc(recipientId).get();
        if (!userDoc.exists) {
          results.push({ recipientId, success: false, error: 'User not found' });
          continue;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
          results.push({ recipientId, success: false, error: 'No FCM token' });
          continue;
        }

        // Create notification document in Firestore
        const notificationData = {
          title,
          message,
          type: type || 'general',
          recipient_id: recipientId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          status: 'unread',
          additionalData: additionalData || {},
        };

        const notificationRef = await db.collection('notifications').add(notificationData);

        // Send FCM message
        const payload = {
          notification: {
            title,
            body: message,
          },
          data: {
            type: type || 'general',
            notificationId: notificationRef.id,
            ...additionalData,
          },
          token: fcmToken,
        };

        await admin.messaging().send(payload);
        results.push({ recipientId, success: true, notificationId: notificationRef.id });
      } catch (error) {
        console.error(`Error sending notification to ${recipientId}:`, error);
        results.push({ recipientId, success: false, error: error.message });
      }
    }

    return { results };
  } catch (error) {
    console.error('Error sending notifications:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send notifications');
  }
});

// Send reminder notifications (can be triggered by scheduled functions)
exports.sendReminderNotifications = functions.https.onCall(async (data, context) => {
  try {
    const { userId, exerciseName, reminderType } = data;
    
    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }

    // Get user's FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'User has no FCM token');
    }

    let title, message;
    
    switch (reminderType) {
      case 'exercise':
        title = 'Exercise Reminder';
        message = `Don't forget to complete your exercise: ${exerciseName || 'Today\'s exercises'}`;
        break;
      case 'daily':
        title = 'Daily Reminder';
        message = 'Time for your daily physical therapy session!';
        break;
      case 'weekly':
        title = 'Weekly Progress';
        message = 'Check your weekly progress and continue your therapy journey!';
        break;
      default:
        title = 'Reminder';
        message = 'Don\'t forget about your physical therapy routine!';
    }

    // Create notification document in Firestore
    const notificationData = {
      title,
      message,
      type: 'reminder',
      recipient_id: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'unread',
      additionalData: {
        reminderType,
        exerciseName: exerciseName || '',
      },
    };

    const notificationRef = await db.collection('notifications').add(notificationData);

    // Send FCM message
    const payload = {
      notification: {
        title,
        body: message,
      },
      data: {
        type: 'reminder',
        notificationId: notificationRef.id,
        reminderType,
        exerciseName: exerciseName || '',
      },
      token: fcmToken,
    };

    const response = await admin.messaging().send(payload);
    console.log('Successfully sent reminder:', response);

    return { success: true, notificationId: notificationRef.id };
  } catch (error) {
    console.error('Error sending reminder notification:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send reminder notification');
  }
});