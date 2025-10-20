// setRoleClaim.js
// Usage: node setRoleClaim.js <UID> <role>
// Requires serviceAccountKey.json in this folder.

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

async function setRole(uid, role) {
  try {
    await admin.auth().setCustomUserClaims(uid, { role });
    console.log(`Set role=${role} for ${uid}`);
  } catch (err) {
    console.error('Error setting role:', err);
  }
}

const [,, uid, role] = process.argv;
if (!uid || !role) {
  console.error('Usage: node setRoleClaim.js <UID> <role>');
  process.exit(1);
}

setRole(uid, role).then(() => process.exit(0));
// setRoleClaim.js
// Usage: node setRoleClaim.js <USER_UID> <role>
// Example: node setRoleClaim.js yX12abcDoctor doctor

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

async function setRole(uid, role) {
  try {
    await admin.auth().setCustomUserClaims(uid, { role });
    console.log(`Custom claim set: ${uid} -> role=${role}`);
    process.exit(0);
  } catch (err) {
    console.error('Failed to set custom claim:', err);
    process.exit(1);
  }
}

const [,, uid, role] = process.argv;
if (!uid || !role) {
  console.error('Usage: node setRoleClaim.js <USER_UID> <role>');
  process.exit(1);
}

setRole(uid, role);
