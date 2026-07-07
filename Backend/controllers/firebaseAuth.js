const admin = require("firebase-admin");
const serviceAccount = require("../controllers/resqbox-2740d-firebase-adminsdk-fbsvc-266712abea.json");

const authApp =
  admin.apps.find(app => app.name === "resqbox-auth") ||
  admin.initializeApp(
    {
      credential: admin.credential.cert(serviceAccount),
    },
    "resqbox-auth"
  );

module.exports = {
  admin,
  authApp,
};
