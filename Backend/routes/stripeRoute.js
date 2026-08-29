const express = require("express");

const router = express.Router();

const stripeController = require("../controllers/stripe");
const auth = require("../utils/authentication");

router.get("/oauth/start/:kitchenId", auth.authenticateOptionalKitchen, stripeController.startStripeOAuth);
router.get("/oauth/callback", stripeController.handleStripeOAuthCallback);

router.post("/create-stripe-account", auth.authenticateOptionalKitchen, auth.requireKitchenOwner, stripeController.createStripeAccount);
router.post("/create-account-session", auth.authenticateOptionalKitchen, auth.requireKitchenOwner, stripeController.createAccountSession);

router.get("/onboarding-embed", stripeController.onboardingEmbed);

module.exports = router;
