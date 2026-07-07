
const express = require("express");

const router = express.Router();

const stripeController = require("../controllers/stripe");
const auth = require("../utils/authentication");


router.get("/oauth/start/:kitchenId", stripeController.startStripeOAuth);
router.get("/oauth/callback", stripeController.handleStripeOAuthCallback);



// 🆕 Embedded Onboarding Flow
router.post("/create-stripe-account", auth.authenticateOptionalKitchen, stripeController.createStripeAccount);
router.post("/create-account-session", auth.authenticateOptionalKitchen, stripeController.createAccountSession);

// 🌐 Public route to serve the HTML wrapper for Flutter WebView
router.get("/onboarding-embed", stripeController.onboardingEmbed);


module.exports = router;
