const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }

  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return JSON.parse(
      fs.readFileSync(process.env.GOOGLE_APPLICATION_CREDENTIALS, "utf8")
    );
  }

  const legacyPath = path.join(
    __dirname,
    "resqbox-2740d-firebase-adminsdk-fbsvc-266712abea.json"
  );
  if (fs.existsSync(legacyPath)) {
    return JSON.parse(fs.readFileSync(legacyPath, "utf8"));
  }

  throw new Error("Firebase credentials are not configured");
}

let authApp;

function getAuthApp() {
  if (authApp) return authApp;

  const serviceAccount = loadServiceAccount();
  authApp =
    admin.apps.find((app) => app.name === "resqbox-auth") ||
    admin.initializeApp(
      {
        credential: admin.credential.cert(serviceAccount),
      },
      "resqbox-auth"
    );
  return authApp;
}

module.exports = {
  admin,
  get authApp() {
    return getAuthApp();
  },
};
