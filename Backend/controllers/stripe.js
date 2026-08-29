const crypto = require("crypto");
const Stripe = require("stripe");
const prisma = require("../utils/prisma");
const auditLogger = require("../utils/auditLogger");

// Use VENDORS account to match the STRIPE_CLIENT_ID (ca_TaHZ...)
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY_VENDORS);


exports.startStripeOAuth = async (req, res) => {
  try {
    const kitchenId = req.kitchen?.kitchenId || Number(req.params.kitchenId);

    if (!req.kitchen || Number(req.kitchen.kitchenId) !== Number(kitchenId)) {
      return res.status(403).json({
        status: 0,
        message: "You can only connect Stripe for your own kitchen"
      });
    }

    if (req.isTeamMember) {
      return res.status(403).json({
        status: 0,
        message: "This action is limited to the kitchen owner"
      });
    }

    const kitchen = req.kitchen;

    if (!kitchen) {
      return res.status(404).json({
        status: 0,
        message: "Kitchen not found"
      });
    }

    // ❌ Prevent reconnect
    if (kitchen.stripeAccountId) {
      return res.status(400).json({
        status: 0,
        message: "Stripe already connected for this kitchen"
      });
    }

    // 🔐 CSRF state
    const stateToken = crypto.randomBytes(24).toString("hex");

    // Save state temporarily (reuse scope column OR use Redis)
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        stripeOauthScope: stateToken
      }
    });

    // 🔗 Stripe OAuth URL
    const params = new URLSearchParams({
      response_type: "code",
      scope: "read_write",
      client_id: process.env.STRIPE_CLIENT_ID,
      redirect_uri: process.env.STRIPE_OAUTH_REDIRECT_URL,
      state: `${kitchenId}:${stateToken}`
    });

    params.append("stripe_user[country]", "AU");
    params.append("stripe_user[account_type]", "express");

    // Weekly payouts
    params.append("stripe_user[payout_schedule][interval]", "weekly");
    params.append("stripe_user[payout_schedule][weekly_anchor]", "monday");

    const authUrl = `https://connect.stripe.com/oauth/authorize?${params.toString()}`;

    console.log(`[Stripe OAuth] Redirecting to: ${authUrl}`);
    return res.redirect(authUrl);
  } catch (error) {
    console.error("[Stripe OAuth] START ERROR:", error);

    return res.status(500).json({
      status: 0,
      message: error.message || "Failed to start Stripe OAuth"
    });
  }

};


exports.handleStripeOAuthCallback = async (req, res) => {
  try {
    const { code, state, error, error_description } = req.query;

    console.log("[Stripe OAuth] Callback received with query:", req.query);
    if (error) {
      console.error(`[Stripe OAuth] Error from Stripe: ${error_description}`);
      return res.redirect("/integrations/stripe?error=true");
    }

    if (!code || !state) {
      return res.redirect("/integrations/stripe?error=missing_params");
    }

    // 🔐 Validate state
    const [kitchenId, stateToken] = state.split(":");

    const kitchen = await prisma.kitchen.findUnique({
      where: { kitchenId: Number(kitchenId) }
    });

    if (!kitchen || kitchen.stripeOauthScope !== stateToken) {
      return res.status(400).json({
        status: 0,
        message: "Invalid OAuth state"
      });
    }

    // 🔁 Exchange code → tokens
    const tokenResponse = await stripe.oauth.token({
      grant_type: "authorization_code",
      code
    });

    // 💾 Save Stripe details
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        stripeAccountId: tokenResponse.stripe_user_id,
        stripeOauthAccessToken: tokenResponse.access_token,
        stripeOauthRefreshToken: tokenResponse.refresh_token || null,
        stripeOauthPublishableKey: tokenResponse.stripe_publishable_key,
        stripeConnectedAt: new Date(),
        stripeAccountConnected: true,       // ✅ CONNECTED
        stripeOnboardingCompleted: false,   // ❌ NOT READY YET
        stripeIntegrationType: "oauth",
        stripeOauthScope: null // clear state
      }
    });

    // 🔧 Set weekly payout schedule immediately after account creation
    try {
      console.log(`[Stripe OAuth] Setting weekly payout schedule for account ${tokenResponse.stripe_user_id}`);

      await stripe.accounts.update(tokenResponse.stripe_user_id, {
        settings: {
          payouts: {
            schedule: {
              interval: "weekly",
              weekly_anchor: "monday"
            }
          }
        }
      });

      console.log(`[Stripe OAuth] ✅ Weekly payout schedule set successfully`);
    } catch (payoutError) {
      console.error(`[Stripe OAuth] ⚠️ Failed to set payout schedule:`, payoutError.message);
      // Don't fail the entire OAuth flow if payout schedule fails
      // It can be set later via the stripePayoutScheduler utility
    }

    // 🔍 CREATE AUDIT LOG for Stripe account linking
    try {
      await auditLogger.createAuditLog({
        kitchenId: Number(kitchenId),
        actorType: 'RESTAURANT',
        actorId: Number(kitchenId),
        actorName: kitchen.kitchenName || kitchen.ownerName,
        actorRole: 'KITCHEN_OWNER',
        actionType: 'STRIPE_ACCOUNT_LINKED_AUTO',
        actionDescription: `Stripe account automatically linked via OAuth: ${tokenResponse.stripe_user_id}`,
        oldData: null,
        newData: tokenResponse.stripe_user_id,
        metadata: {
          linkedBy: 'OAUTH',
          publishableKey: tokenResponse.stripe_publishable_key,
          hasRefreshToken: !!tokenResponse.refresh_token
        }
      });
      console.log(`[Stripe OAuth] ✅ Audit log created for kitchen ${kitchenId}`);
    } catch (auditError) {
      console.error(`[Stripe OAuth] ⚠️ Failed to create audit log:`, auditError.message);
      // Don't fail the OAuth flow if audit logging fails
    }

    console.log(`[Stripe OAuth] Successfully connected kitchen ${kitchenId} to Stripe account ${tokenResponse.stripe_user_id}`);
    // return res.redirect("resqbox://stripe-success");
    // return res.redirect("resqboxvendor://stripe-callback?success=true");
    const appDeepLink = "resqboxvendor://stripe-callback?success=true";

    const html = `
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Redirecting...</title>
</head>
<body style="background-color:#fff; c
olor:#333; font-family:sans-serif; text-align:center; padding-top:40px;">
    <h3>Authentication Successful!</h3>
    <p>Redirecting you back to Resqbox...</p>
    <script>
        // Try to redirect immediately
        window.location.href = "${appDeepLink}";
        
        // Fallback if needed
        setTimeout(function() {
            window.location.href = "${appDeepLink}";
        }, 500);
    </script>
    <br/>
    <a style="display:inline-block; padding:10px 20px; background-color:#EB7712; color:white; text-decoration:none; border-radius:5px;" href="${appDeepLink}">
        Click here if not redirected
    </a>
</body>
</html>
`;

    return res.send(html);
  } catch (error) {
    // logger.error("[Stripe OAuth] Callback error:", error);
    console.error("[Stripe OAuth] Callback error:", error);
    return res.redirect("/integrations/stripe?error=true");
  }
};

// exports.createStripeAccount = async (req, res) => {
//   try {
//     // 🔐 Get kitchenId from token (middleware attaches it)
//     const kitchen = req.kitchen;
//     const kitchenId = kitchen.kitchenId;

//     console.log(`[Stripe] Creating account session for kitchen: ${kitchenId}`);
//     // ✅ If already has an account, return it
//     if (kitchen.stripeAccountId) {
//       console.log(`[Stripe] Kitchen ${kitchenId} already has Stripe account: ${kitchen.stripeAccountId}`);
//       return res.status(200).json({
//         status: 1,
//         message: "Stripe account already exists",
//         stripeAccountId: kitchen.stripeAccountId,
//         onboardingCompleted: kitchen.stripeOnboardingCompleted
//       });
//     }

//     console.log(`[Stripe] Creating new Express account for kitchen: ${kitchenId}`);

//     // 🚀 Create a new Express account
//     const account = await stripe.accounts.create({
//       type: 'express',
//       country: 'AU', // Default to Australia as per existing logic
//       capabilities: {
//         card_payments: { requested: true },
//         transfers: { requested: true },
//       },
//       settings: {
//         payouts: {
//           schedule: {
//             interval: 'weekly',
//             weekly_anchor: 'monday',
//           },
//         },
//       },
//     });

//     console.log(`[Stripe] ✅ Created account: ${account.id}`);

//     // 💾 Save Stripe details
//     await prisma.kitchen.update({
//       where: { kitchenId: Number(kitchenId) },
//       data: {
//         stripeAccountId: account.id,
//         stripeIntegrationType: "embedded",
//         stripeAccountConnected: true,
//         stripeOnboardingCompleted: false,
//         stripeConnectedAt: new Date()
//       }
//     });

//     // 🔍 CREATE AUDIT LOG
//     try {
//       const auditLogger = require('../utils/auditLogger');
//       await auditLogger.createAuditLog({
//         kitchenId: Number(kitchenId),
//         actorType: 'RESTAURANT',
//         actorId: Number(kitchenId),
//         actorName: kitchen.kitchenName || kitchen.ownerName,
//         actorRole: 'KITCHEN_OWNER',
//         actionType: 'STRIPE_ACCOUNT_LINKED_AUTO',
//         actionDescription: `Stripe account created for embedded onboarding: ${account.id}`,
//         oldData: null,
//         newData: account.id,
//         metadata: {
//           integrationType: 'embedded',
//           accountType: 'express'
//         }
//       });
//     } catch (auditError) {
//       console.error(`[Stripe] ⚠️ Audit log failed:`, auditError.message);
//     }

//     return res.status(200).json({
//       status: 1,
//       message: "Stripe account created successfully",
//       stripeAccountId: account.id
//     });
//   } catch (error) {
//     console.error("[Stripe] CREATE ACCOUNT ERROR:", error);
//     return res.status(500).json({
//       status: 0,
//       message: error.message || "Failed to create Stripe account"
//     });
//   }
// };
// ✅ Add these helpers at the top of the file (outside the function)
const COUNTRY_MAP = {
  'australia': 'AU',
  'united states': 'US',
  'united kingdom': 'GB',
  'india': 'IN',
  'new zealand': 'NZ',
};

const normalizeCountry = (country) => {
  if (!country) return 'AU';
  if (country.length === 2) return country.toUpperCase();
  return COUNTRY_MAP[country.toLowerCase()] || 'AU';
};

const AU_STATE_MAP = {
  'new south wales': 'NSW',
  'victoria': 'VIC',
  'queensland': 'QLD',
  'western australia': 'WA',
  'south australia': 'SA',
  'tasmania': 'TAS',
  'australian capital territory': 'ACT',
  'northern territory': 'NT',
};

const normalizeAUState = (state) => {
  if (!state) return undefined;
  if (state.length <= 3) return state.toUpperCase();
  return AU_STATE_MAP[state.toLowerCase()] || state;
};

exports.createStripeAccount = async (req, res) => {
  try {
    const kitchen = req.kitchen;
    const kitchenId = kitchen.kitchenId;

    console.log(`[Stripe] Creating account session for kitchen: ${kitchenId}`);

    if (kitchen.stripeAccountId) {
      console.log(`[Stripe] Kitchen ${kitchenId} already has Stripe account: ${kitchen.stripeAccountId}`);
      return res.status(200).json({
        status: 1,
        message: "Stripe account already exists",
        stripeAccountId: kitchen.stripeAccountId,
        onboardingCompleted: kitchen.stripeOnboardingCompleted
      });
    }

    console.log(`[Stripe] Creating new Express account for kitchen: ${kitchenId}`);

    // Fetch kitchen with address and KYC
    const kitchenData = await prisma.kitchen.findUnique({
      where: { kitchenId: Number(kitchenId) },
      include: { address: true, kyc: true }
    });

    const addr = kitchenData?.address;
    const kyc = kitchenData?.kyc;

    // ✅ Build normalized address
    const line1 = [addr?.houseNo, addr?.street].filter(Boolean).join(', ') || undefined;
    const city = addr?.city || undefined;
    const state = normalizeAUState(addr?.state);
    const postal_code = addr?.pincode || undefined;
    const country = normalizeCountry(addr?.country);

    // ✅ STEP 1: Create Stripe Account
    const account = await stripe.accounts.create({
      country: 'AU',
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      controller: {
        stripe_dashboard: { type: 'none' },
        fees: { payer: 'application' },
        losses: { payments: 'application' },
        requirement_collection: 'application',
      },
      settings: {
        payouts: {
          schedule: {
            interval: 'weekly',
            weekly_anchor: 'monday',
          },
        },
      },
      email: kitchen.email || undefined,
      business_profile: {
        support_email: kitchen.email || undefined,
        support_phone: kitchen.contactNumber || undefined,
        ...(addr?.city && {
          support_address: {
            line1,
            city,
            state,
            postal_code,
            country,
          }
        })
      },
      ...(kyc?.abnNumber && {
        business_type: 'company',
        company: {
          tax_id: kyc.abnNumber,
          registration_number: kyc.acn || undefined,
          name: kitchen.kitchenName || undefined,
          phone: kitchen.contactNumber || undefined,
          ...(addr && {
            address: {
              line1,
              city,
              state,
              postal_code,
              country,
            }
          })
        }
      })
    }); // ✅ stripe.accounts.create ends here

    console.log(`[Stripe] ✅ Created account: ${account.id}`);

    // ✅ STEP 2: Pre-fill owner personal details
    if (kitchen.ownerName) {
      try {
        const nameParts = (kitchen.ownerName || '').trim().split(' ');
        const firstName = nameParts[0] || undefined;
        const lastName = nameParts.slice(1).join(' ') || undefined;

        await stripe.accounts.createPerson(account.id, {
          first_name: firstName,
          last_name: lastName,
          email: kitchen.email || undefined,
          phone: kitchen.contactNumber || undefined,
          relationship: {
            representative: true,
            owner: true,
          },
          ...(addr && {
            address: {
              line1,
              city,
              state,
              postal_code,
              country,
            }
          })
        });

        console.log(`[Stripe] ✅ Pre-filled person details for account: ${account.id}`);
      } catch (personError) {
        console.error(`[Stripe] ⚠️ Failed to pre-fill person:`, personError.message);
      }
    }

    // ✅ STEP 3: Save Stripe details to DB
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        stripeAccountId: account.id,
        stripeIntegrationType: "embedded",
        stripeAccountConnected: true,
        stripeOnboardingCompleted: false,
        stripeConnectedAt: new Date()
      }
    });

    // ✅ STEP 4: Audit log
    try {
      await auditLogger.createAuditLog({
        kitchenId: Number(kitchenId),
        actorType: 'RESTAURANT',
        actorId: Number(kitchenId),
        actorName: kitchen.kitchenName || kitchen.ownerName,
        actorRole: 'KITCHEN_OWNER',
        actionType: 'STRIPE_ACCOUNT_LINKED_AUTO',
        actionDescription: `Stripe account created for embedded onboarding: ${account.id}`,
        oldData: null,
        newData: account.id,
        metadata: {
          integrationType: 'embedded',
          accountType: 'controller'
        }
      });
    } catch (auditError) {
      console.error(`[Stripe] ⚠️ Audit log failed:`, auditError.message);
    }

    return res.status(200).json({
      status: 1,
      message: "Stripe account created successfully",
      stripeAccountId: account.id
    });

  } catch (error) {
    console.error("[Stripe] CREATE ACCOUNT ERROR:", error);
    return res.status(500).json({
      status: 0,
      message: error.message || "Failed to create Stripe account"
    });
  }
};

// // ✅ Updated createStripeAccount
// exports.createStripeAccount = async (req, res) => {
//   try {
//     const kitchen = req.kitchen;
//     const kitchenId = kitchen.kitchenId;

//     console.log(`[Stripe] Creating account session for kitchen: ${kitchenId}`);

//     if (kitchen.stripeAccountId) {
//       console.log(`[Stripe] Kitchen ${kitchenId} already has Stripe account: ${kitchen.stripeAccountId}`);
//       return res.status(200).json({
//         status: 1,
//         message: "Stripe account already exists",
//         stripeAccountId: kitchen.stripeAccountId,
//         onboardingCompleted: kitchen.stripeOnboardingCompleted
//       });
//     }

//     console.log(`[Stripe] Creating new Express account for kitchen: ${kitchenId}`);

//     // Fetch kitchen with address and KYC
//     const kitchenData = await prisma.kitchen.findUnique({
//       where: { kitchenId: Number(kitchenId) },
//       include: { address: true, kyc: true }
//     });

//     const addr = kitchenData?.address;
//     const kyc = kitchenData?.kyc;

//     // ✅ Build normalized address
//     const line1 = [addr?.houseNo, addr?.street].filter(Boolean).join(', ') || undefined;
//     const city = addr?.city || undefined;
//     const state = normalizeAUState(addr?.state);
//     const postal_code = addr?.pincode || undefined;
//     const country = normalizeCountry(addr?.country);

//     const account = await stripe.accounts.create({
//       country: 'AU',
//       capabilities: {
//         card_payments: { requested: true },
//         transfers: { requested: true },
//       },
//       controller: {
//         stripe_dashboard: { type: 'none' },
//         fees: { payer: 'application' },
//         losses: { payments: 'application' },
//         requirement_collection: 'application',
//       },
//       settings: {
//         payouts: {
//           schedule: {
//             interval: 'weekly',
//             weekly_anchor: 'monday',
//           },
//         },
//       },

//       // ✅ PRE-FILL BUSINESS INFO
//       email: kitchen.email || undefined,
//       business_profile: {
//         // name: kitchen.kitchenName || undefined,
//         support_email: kitchen.email || undefined,
//         support_phone: kitchen.contactNumber || undefined,
//         ...(addr?.city && {
//           support_address: {
//             line1,
//             city,
//             state,
//             postal_code,
//             country,
//           }
//         })
//       },

//       // ✅ PRE-FILL COMPANY TAX INFO
//       ...(kyc?.abnNumber && {
//         business_type: 'company',  // ✅ Required when sending company params
//         company: {
//           tax_id: kyc.abnNumber,
//           registration_number: kyc.acn || undefined,      // ✅ ACN
//           name: kitchen.kitchenName || undefined,
//           phone: kitchen.contactNumber || undefined,
//           ...(addr && {
//             address: {
//               line1,
//               city,
//               state,
//               postal_code,
//               country,
//             }
//           })
//         }
//       })
//     });

//     console.log(`[Stripe] ✅ Created account: ${account.id}`);

//     await prisma.kitchen.update({
//       where: { kitchenId: Number(kitchenId) },
//       data: {
//         stripeAccountId: account.id,
//         stripeIntegrationType: "embedded",
//         stripeAccountConnected: true,
//         stripeOnboardingCompleted: false,
//         stripeConnectedAt: new Date()
//       }
//     });

//     try {
//       await auditLogger.createAuditLog({
//         kitchenId: Number(kitchenId),
//         actorType: 'RESTAURANT',
//         actorId: Number(kitchenId),
//         actorName: kitchen.kitchenName || kitchen.ownerName,
//         actorRole: 'KITCHEN_OWNER',
//         actionType: 'STRIPE_ACCOUNT_LINKED_AUTO',
//         actionDescription: `Stripe account created for embedded onboarding: ${account.id}`,
//         oldData: null,
//         newData: account.id,
//         metadata: {
//           integrationType: 'embedded',
//           accountType: 'controller'
//         }
//       });
//     } catch (auditError) {
//       console.error(`[Stripe] ⚠️ Audit log failed:`, auditError.message);
//     }

//     return res.status(200).json({
//       status: 1,
//       message: "Stripe account created successfully",
//       stripeAccountId: account.id
//     });

//   } catch (error) {
//     console.error("[Stripe] CREATE ACCOUNT ERROR:", error);
//     return res.status(500).json({
//       status: 0,
//       message: error.message || "Failed to create Stripe account"
//     });
//   }
// };

exports.createAccountSession = async (req, res) => {
  try {
    // 🔐 Get kitchenId from token
    const kitchen = req.kitchen;
    const kitchenId = kitchen.kitchenId;

    console.log(`[Stripe] Creating account session for kitchen: ${kitchenId}`);

    if (!kitchen.stripeAccountId) {
      return res.status(400).json({
        status: 0,
        message: "Stripe account not created yet"
      });
    }

    console.log(`[Stripe] Creating account session for account: ${kitchen.stripeAccountId}`);

    // // 🔗 Create Account Session for Embedded Onboarding
    // const accountSession = await stripe.accountSessions.create({
    //   account: kitchen.stripeAccountId,
    //   components: {
    //     account_onboarding: {
    //       enabled: true,
    //       // features: {
    //       //   // ✅ FIX: Prevents embedded_auth popup/redirect that breaks Android WebView
    //       //   // Note: disable_stripe_user_authentication is NOT supported for Express accounts
    //       //   external_account_collection: false,
    //       // },
    //       features: {
    //         external_account_collection: false,
    //         disable_stripe_user_authentication: true, // ✅ Now valid with controller accounts
    //       },
    //     },
    //   },
    // });
    const accountSession = await stripe.accountSessions.create({
      account: kitchen.stripeAccountId,
      components: {
        account_onboarding: {
          enabled: true,
          features: {
            external_account_collection: true,  // ✅ Allow bank details collection
            disable_stripe_user_authentication: true,
          },
        },
      },
    });
    return res.status(200).json({
      status: 1,
      client_secret: accountSession.client_secret
    });
  } catch (error) {
    console.error("[Stripe] CREATE ACCOUNT SESSION ERROR:", error);
    return res.status(500).json({
      status: 0,
      message: error.message || "Failed to create account session"
    });
  }
};

exports.onboardingEmbed = async (req, res) => {
  const { key, secret } = req.query;

  if (!key || !secret) {
    return res.status(400).send("Missing key or secret parameters");
  }

  // ✅ FIX: Sanitize inputs to prevent XSS
  const safeKey = key.replace(/[^a-zA-Z0-9_\-]/g, '');
  const safeSecret = secret.replace(/[^a-zA-Z0-9_\-]/g, '');

  if (!safeKey || !safeSecret) {
    return res.status(400).send("Invalid key or secret parameters");
  }

  // ✅ FIX: Corrected CSP wildcards (was missing * before dots)
  res.setHeader(
    "Content-Security-Policy",
    "default-src 'self'; " +
    "script-src 'self' https://connect-js.stripe.com https://js.stripe.com 'unsafe-inline'; " +
    "frame-src https://*.stripe.com https://*.stripecdn.com https://*.stripe.network; " +
    "connect-src https://*.stripe.com https://*.stripecdn.com https://r.stripe.com https://m.stripe.com https://*.stripe.network; " +
    "img-src 'self' data: https://*.stripe.com https://*.stripecdn.com; " +
    "style-src 'self' 'unsafe-inline';"
  );
  res.setHeader("Content-Type", "text/html");

  const html = `
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Add Billing Details</title>
    <script src="https://connect-js.stripe.com/v1.0/connect.js"></script>
    <style>
      body {
        margin: 0;
        padding: 16px;
        background-color: #ffffffff;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      }
      #container {
        width: 100%;
        min-height: 100vh;
      }

    </style>
  </head>
  <body>
    <div id="container"></div>
    <script>
      const stripeConnect = window.StripeConnect.init({
        publishableKey: "${safeKey}",
        clientSecret: "${safeSecret}",
        appearance: {
          overlays: 'dialog',
          variables: {
            colorPrimary: '#EB7712',
          },
        },
      });

      const onboarding = stripeConnect.create("account-onboarding");

      onboarding.setFullTermsOfServiceUrl('https://resqboxfood.com/terms');
      onboarding.setRecipientTermsOfServiceUrl('https://resqboxfood.com/terms');
      onboarding.setPrivacyPolicyUrl('https://resqboxfood.com/privacy');

      onboarding.setOnExit(() => {
        window.location.href = 'resqboxvendor://onboarding_exit';
      });

      document.getElementById("container").appendChild(onboarding);
    </script>
  </body>
</html>
  `;

  return res.send(html);
};


// exports.createAccountSession = async (req, res) => {
//   try {
//     const accountId = req.kitchen.stripeAccountId;

//     const accountSession = await stripe.accountSessions.create({
//       account: accountId,
//       components: {
//         account_onboarding: {
//           enabled: true,
//           features: {
//             disable_stripe_user_authentication: true,
//           },
//         },
//       },
//     });

//     return res.json({
//       status: 1,
//       client_secret: accountSession.client_secret,
//     });
//   } catch (error) {
//     console.error("Create account session error:", error);
//     return res.status(500).json({ status: 0, message: error.message });
//   }
// };
// // exports.onboardingEmbed = async (req, res) => {
// //   const { key, secret } = req.query;

// //   if (!key || !secret) {
// //     return res.status(400).send("Missing key or secret parameters");
// //   }

// //   const html = `
// // <!DOCTYPE html>
// // <html>
// //   <head>
// //     <meta charset="utf-8">
// //     <meta name="viewport" content="width=device-width, initial-scale=1.0">
// //     <title>Stripe Onboarding</title>
// //     <script src="https://connect-js.stripe.com/v1.0/connect.js"></script>
// //     <style>
// //       body {
// //         margin: 0;
// //         padding: 0;
// //         background-color: #f3f4f8;
// //         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
// //       }
// //       #container {
// //         width: 100%;
// //         min-height: 100vh;
// //       }
// //     </style>
// //   </head>
// //   <body>
// //     <div id="container"></div>
// //     <script>
// //       // Initialize Stripe Connect
// //       const stripeConnect = window.StripeConnect.init({
// //         publishableKey: "${key}",
// //         clientSecret: "${secret}",
// //         appearance: {
// //           overlays: 'dialog',
// //           variables: {
// //             colorPrimary: '#EB7712',
// //           },
// //         },
// //       });

// //       const onboarding = stripeConnect.create("account-onboarding");

// //       // Handle exit event - deep link back to Flutter app
// //       onboarding.setOnExit(() => {
// //         window.location.href = 'resqboxvendor://onboarding_exit';
// //       });

// //       document.getElementById("container").appendChild(onboarding);
// //     </script>
// //   </body>
// // </html>
// //   `;

// //   res.setHeader('Content-Type', 'text/html');
// //   return res.send(html);
// // };


// exports.onboardingEmbed = async (req, res) => {
//   const { key, secret } = req.query;
//   if (!key || !secret) {
//     return res.status(400).send("Missing key or secret parameters");
//   }

//   res.setHeader(
//     "Content-Security-Policy",
//     "default-src 'self'; " +
//     "script-src 'self' https://connect-js.stripe.com https://js.stripe.com 'unsafe-inline'; " +
//     "frame-src https://*.stripe.com https://*.stripecdn.com; " +
//     "connect-src https://*.stripe.com https://*.stripecdn.com https://r.stripe.com https://m.stripe.com; " +
//     "img-src 'self' data: https://*.stripe.com https://*.stripecdn.com; " +
//     "style-src 'self' 'unsafe-inline';"
//   );
//   res.setHeader("Content-Type", "text/html");

//   const html = `
// <!DOCTYPE html>
// <html>
//   <head>
//     <meta charset="utf-8">
//     <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     <title>Stripe Onboarding</title>
//     <script src="https://connect-js.stripe.com/v1.0/connect.js"></script>
//     <style>
//       body {
//         margin: 0; padding: 0;
//         background-color: #f3f4f8;
//         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
//       }
//       #container { width: 100%; min-height: 100vh; }
//       #loading-overlay {
//         position: fixed;
//         top: 0; left: 0; right: 0; bottom: 0;
//         background: #f3f4f8;
//         display: flex;
//         flex-direction: column;
//         align-items: center;
//         justify-content: center;
//         z-index: 9999;
//       }
//       .spinner {
//         width: 44px; height: 44px;
//         border: 4px solid #e0e0e0;
//         border-top-color: #EB7712;
//         border-radius: 50%;
//         animation: spin 0.8s linear infinite;
//       }
//       @keyframes spin { to { transform: rotate(360deg); } }
//       .loading-text { margin-top: 16px; color: #555; font-size: 15px; }
//     </style>
//   </head>
//   <body>
//     <div id="loading-overlay">
//       <div class="spinner"></div>
//       <div class="loading-text">Setting up payments...</div>
//     </div>
//     <div id="container"></div>
//     <script>
//       const stripeConnect = window.StripeConnect.init({
//         publishableKey: "${key}",
//         clientSecret: "${secret}",
//         appearance: {
//           overlays: 'dialog',
//           variables: { colorPrimary: '#EB7712' },
//         },
//       });

//       const onboarding = stripeConnect.create("account-onboarding");

//       onboarding.setFullTermsOfServiceUrl('https://resqboxfood.com/terms');
//       onboarding.setRecipientTermsOfServiceUrl('https://resqboxfood.com/terms');
//       onboarding.setPrivacyPolicyUrl('https://resqboxfood.com/privacy');

//       onboarding.setOnLoaderStart(() => {
//         document.getElementById('loading-overlay').style.display = 'none';
//       });

//       onboarding.setOnExit(() => {
//         window.location.href = 'resqboxvendor://onboarding_exit';
//       });

//       document.getElementById("container").appendChild(onboarding);
//     </script>
//   </body>
// </html>
//   `;

//   return res.send(html);
// };