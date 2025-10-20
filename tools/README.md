# Admin tools

This folder contains simple admin scripts that you can run locally to manage user documents and roles.

1) backfillUsers.js
- Purpose: Create `users/{uid}` documents in Firestore for Authentication users that don't have a Firestore doc yet.
- Requirements: Node.js installed, `npm install firebase-admin`, and a service account JSON file named `serviceAccountKey.json` placed in this folder.
- Run:

```powershell
cd tools
npm init -y
npm install firebase-admin
# place serviceAccountKey.json here (download from Firebase Console -> Project settings -> Service accounts)
node .\backfillUsers.js
```

2) setRoleClaim.js
- Purpose: Set a custom claim `role` for a user. This is useful if you want to use custom claims to authorize actions in Firestore security rules.
- Run:

```powershell
cd tools
npm init -y
npm install firebase-admin
# place serviceAccountKey.json here
node .\setRoleClaim.js <USER_UID> doctor
```

Notes:
- Do NOT commit your `serviceAccountKey.json` to source control.
- Running `setRoleClaim.js` sets custom claims for the user; the user will need to refresh their ID token (sign out and sign in) to get the updated claims client-side.
Admin tools

This folder contains two Node.js scripts to help manage user documents and roles for the chatpt-9513d Firebase project.

Files:
- backfillUsers.js — iterate Authentication users and create a Firestore document at users/{uid} if missing.
- setRoleClaim.js — set a custom claim role for a specific user (requires Admin SDK / service account).

Important: Do NOT commit your service account JSON to source control. Download a service account key from Firebase Console -> Project settings -> Service accounts, and save it as serviceAccountKey.json in this tools folder before running the scripts.

Prerequisites:
- Node.js installed
- npm available
- A Firebase service account JSON (download from Project settings -> Service accounts)

Setup (PowerShell):

1. Open PowerShell and change directory to the tools folder:
   cd tools
2. Initialize and install dependencies:
   npm init -y
   npm install firebase-admin
3. Place your serviceAccountKey.json in this folder.

Backfill all Authentication users into Firestore:

From the tools folder run:
node .\backfillUsers.js

Set custom role claim for a single user:

Usage:
node .\setRoleClaim.js <USER_UID> <role>
Example:
node .\setRoleClaim.js someUid123 doctor

After setting custom claims, users must refresh their ID token in the client to see the updated claims. In Flutter call:
await FirebaseAuth.instance.currentUser!.getIdTokenResult(true);

Security note:
- Only use the Admin SDK from trusted environments. Keep the service account JSON secret.
- Prefer custom claims for authorization checks in Firestore security rules.

Migration: copying documents between collections
---------------------------------------------

You can migrate documents from one collection to another using `migrateUsersCollection.js`.
This is useful if your app created a `users` collection but you also have `Users` or other variants.

Preview (dry-run) without writing anything:

```powershell
cd tools
node .\migrateUsersCollection.js Users users --dry-run --key 'C:\path\to\your\serviceAccountKey.json'
```

When ready to perform the migration (writes will occur):

```powershell
node .\migrateUsersCollection.js Users users --key 'C:\path\to\your\serviceAccountKey.json'
```

Notes:
- Use the `--key` flag to point to your service account JSON anywhere on your machine so you don't have to place it in the repo.
- Dry-run prints what would be copied without changing data. When ready, run without `--dry-run`.
- The migration merges fields and will NOT overwrite an existing `role` field in the target.

