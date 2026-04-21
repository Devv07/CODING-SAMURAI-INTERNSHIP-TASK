const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

let serviceAccount;

//load service account key
const keyPath = path.resolve(
  process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './serviceAccountKey.json'
);

if (fs.existsSync(keyPath)) {
  serviceAccount = require(keyPath);
} else {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  } else {
    throw new Error(
      'Firebase service account not found.\n' +
      'Download it from Firebase Console → Project Settings → Service accounts\n' +
      'and save it as backend/serviceAccountKey.json'
    );
  }
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db   = admin.firestore();
const auth = admin.auth();

module.exports = { admin, db, auth };
