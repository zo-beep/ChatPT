Firebase Cloud Function to aggregate exerciseHistory events into per-user summaries

Contents
- `index.js` — function listening to `users/{uid}/exerciseHistory/{eventId}` and incrementing per-period summary docs under `users/{uid}/summaries/`.
- `package.json` — Node dependencies.

Deploy
1. Install Firebase CLI and login: `npm i -g firebase-tools` then `firebase login`.
2. From this repo root, change into the functions folder:

```powershell
cd functions
npm install
firebase deploy --only functions:onExerciseHistory
```

Notes
- The function uses server timestamps and FieldValue.increment for atomic counters.
- For security, lock down `users/{uid}/summaries/*` so only server-side functions may write them. Allow clients to read summaries.
- This function is idempotent per event document creation. If you later run a backfill, be careful not to double-count; consider writing a separate backfill script that writes directly to summaries with deduplication.
