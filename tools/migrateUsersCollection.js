// migrateUsersCollection.js
// Usage: node migrateUsersCollection.js <sourceCollection> <targetCollection>
// Copies documents from sourceCollection to targetCollection.
// Preserves 'role' field in target if present and won't overwrite it.
// Requires serviceAccountKey.json in this folder.

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function loadServiceAccount(keyPath) {
  if (!keyPath) {
    keyPath = path.join(__dirname, 'serviceAccountKey.json');
  }
  if (!fs.existsSync(keyPath)) {
    console.error(`Service account JSON not found at ${keyPath}. Use --key <path> to point to it.`);
    process.exit(1);
  }
  return require(keyPath);
}

let adminApp;
let db;

async function migrate(source, target, { dryRun = false, keyPath = null } = {}) {
  // Initialize Admin SDK (required even for dry-run because we need to read documents)
  const serviceAccount = loadServiceAccount(keyPath);
  adminApp = admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  db = adminApp.firestore();

  if (dryRun) {
    console.log('Running in DRY-RUN mode: no writes will be performed.');
  }

  console.log(`Migrating documents from '${source}' -> '${target}'`);
  const snapshot = await db.collection(source).get();
  console.log(`Found ${snapshot.size} documents in '${source}'.`);
  let count = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (dryRun) {
      console.log(`[DRY-RUN] Would copy document '${doc.id}' to '${target}' with fields:`, data);
      count++;
      continue;
    }
    const targetRef = db.collection(target).doc(doc.id);
    const targetDoc = await targetRef.get();
    if (!targetDoc.exists) {
      // create new doc in target with all fields from source
      await targetRef.set(data);
      console.log(`Created ${target}/${doc.id}`);
      count++;
    } else {
      // merge fields from source into target but do not overwrite role if exists in target
      const targetData = targetDoc.data() || {};
      const merged = { ...targetData };
      for (const [k, v] of Object.entries(data)) {
        if (k === 'role' && (typeof targetData.role !== 'undefined')) {
          // skip overwriting role
          continue;
        }
        merged[k] = v;
      }
      await targetRef.set(merged);
      console.log(`Merged into ${target}/${doc.id}`);
      count++;
    }
  }
  console.log(`Migration complete. Processed ${count} documents.`);
}

// Parse args: source target [--dry-run] [--key <path>]
const args = process.argv.slice(2);
if (args.length < 2) {
  console.error('Usage: node migrateUsersCollection.js <sourceCollection> <targetCollection> [--dry-run] [--key <path>]');
  process.exit(1);
}
const sourceCollection = args[0];
const targetCollection = args[1];
const dryRun = args.includes('--dry-run');
let keyPath = null;
const keyIndex = args.indexOf('--key');
if (keyIndex !== -1 && args.length > keyIndex + 1) {
  keyPath = args[keyIndex + 1];
}

migrate(sourceCollection, targetCollection, { dryRun, keyPath }).then(() => process.exit(0)).catch(err => {
  console.error('Migration error:', err);
  process.exit(1);
});

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      // allow updates but prevent clients changing the 'role' field
      allow update: if request.auth != null && request.auth.uid == userId
                    && !(request.resource.data.keys().hasAny(['role']));
    }
  }
})
