// backfillUsers.js
// Iterates Firebase Authentication users and creates a users/{uid} document in Firestore
// when missing. Requires a service account JSON file in the same folder named
// serviceAccountKey.json.

const admin = require('firebase-admin');
const fs = require('fs');

if (!fs.existsSync('./serviceAccountKey.json')) {
  console.error('serviceAccountKey.json not found in this folder. Place your service account JSON here.');
  process.exit(1);
}

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();

async function backfill() {
  let nextPageToken = undefined;
  console.log('Starting backfill of Auth users to Firestore...');
  do {
    const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of listUsersResult.users) {
      const uid = user.uid;
      const docRef = firestore.collection('users').doc(uid);
      const doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          email: user.email || null,
          displayName: user.displayName || null,
          phoneNumber: user.phoneNumber || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Created user doc for ${uid}`);
      } else {
        console.log(`Already exists: ${uid}`);
      }
    }
    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  console.log('Backfill complete.');
}

backfill().catch(err => {
  console.error('Error running backfill:', err);
  process.exit(1);
});
// backfillUsers.js
// Usage: node backfillUsers.js
// Places a document in Firestore at `users/{uid}` for each Authentication user
// if the document does not already exist.

const admin = require('firebase-admin');
const fs = require('fs');

const SERVICE_ACCOUNT_PATH = './serviceAccountKey.json';

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(`Service account JSON not found at ${SERVICE_ACCOUNT_PATH}`);
  console.error('Download a Service Account key from Firebase Console -> Project settings -> Service accounts and save it as serviceAccountKey.json in this folder.');
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();

async function backfill() {
  console.log('Starting backfill of Authentication users into Firestore users collection...');
  let nextPageToken = undefined;
  try {
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      for (const userRecord of listUsersResult.users) {
        const uid = userRecord.uid;
        const docRef = firestore.collection('users').doc(uid);
        const doc = await docRef.get();
        if (!doc.exists) {
          console.log(`Creating user doc for uid=${uid} email=${userRecord.email}`);
          await docRef.set({
            email: userRecord.email || null,
            displayName: userRecord.displayName || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          console.log(`Already exists: ${uid}`);
        }
      }
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    console.log('Backfill completed.');
    process.exit(0);
  } catch (err) {
    console.error('Error during backfill:', err);
    process.exit(1);
  }
}

backfill();
