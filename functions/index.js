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
