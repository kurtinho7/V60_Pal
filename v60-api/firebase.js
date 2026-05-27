const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

function loadCredential() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
  }

  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const serviceAccountPath = path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
    if (!fs.existsSync(serviceAccountPath)) {
      throw new Error(
        `Firebase Admin credentials file not found at ${serviceAccountPath}. ` +
          'Download a Firebase service account key or update GOOGLE_APPLICATION_CREDENTIALS.'
      );
    }
    return admin.credential.cert(require(serviceAccountPath));
  }

  const localServiceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  if (fs.existsSync(localServiceAccountPath)) {
    return admin.credential.cert(require(localServiceAccountPath));
  }

  throw new Error(
    'Firebase Admin credentials are missing. Add v60-api/serviceAccountKey.json, ' +
      'or set FIREBASE_SERVICE_ACCOUNT / GOOGLE_APPLICATION_CREDENTIALS in v60-api/.env.'
  );
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: loadCredential(),
  });
}

module.exports = admin;
