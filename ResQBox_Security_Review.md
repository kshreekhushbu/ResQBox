# ResQBox Security Review

**Date:** 29 August 2026  
**Scope:** Backend, Admin Portal, User App, Vendor App  
**Method:** Defensive static code review of the repository (no live attacks, exploits, or unauthorized access)  
**Repository:** https://github.com/kshreekhushbu/ResQBox

---

## Executive summary

ResQBox has a **serious authentication and access-control gap**. Several admin, payment, upload, and realtime paths trust the client too much or skip authentication entirely.

Fix first:

1. Lock down public admin signup, password reset, uploads, and Stripe routes.
2. Authenticate Socket.IO connections with a JWT.
3. Enforce admin and vendor roles on the **server**, not only in the UI.
4. Remove secrets from git and logs; rotate leaked signing keys.
5. Stop logging JWTs and passwords; store tokens in secure storage.

---

## Severity counts (code review)

| Area | Critical | High | Medium | Low / Info |
|------|----------|------|--------|------------|
| Backend | 2 | 12 | 22 | 18 |
| Admin Portal | 0 | 6 | 10 | 4 |
| Flutter apps | 1 | 10 | 14 | 6 |

These counts overlap where the same weakness appears in more than one layer (for example, unauthenticated sockets in backend *and* both mobile apps).

---

## Highest-risk findings

### 1. Public admin self-registration — Critical

- **Where:** `Backend/routes/adminRoute.js`, `Backend/controllers/adminController.js` (`adminSignUp`)
- **Issue:** `POST /api/admin/adminSignUp` is unauthenticated. A caller can create an admin account and supply a `roleId` (including super-admin).
- **Fix:** Remove public signup. Restrict creation to a bootstrap script or a super-admin-only authenticated endpoint. Lock `roleId` server-side.

### 2. Password reset without OTP proof — Critical

- **Where:** `Backend/controllers/adminController.js`, `Backend/controllers/vendorController.js` (`resetPassword`)
- **Issue:** OTP verification and password reset are separate steps. `resetPassword` only needs email + new password. It does not check that OTP succeeded. Knowing an email is enough to set a new password for admin and vendor accounts.
- **Fix:** After OTP success, issue a short-lived, single-use reset token and require it on `resetPassword`. Expire and invalidate OTPs after use.

### 3. Android signing credentials committed — Critical

- **Where:** `User_App/android/key.properties`, `Vendor_App/android/key.properties`, `Vendor_App/android/app/resqboxvendor.jks`
- **Issue:** Release keystore passwords and aliases are in the repo in plaintext. The vendor keystore file is also committed.
- **Fix:** Remove these files from git history, rotate keystore passwords, store signing credentials in CI secrets or local-only files, and add `key.properties` and `*.jks` to `.gitignore`.

### 4. Unauthenticated Stripe kitchen linking — High

- **Where:** `Backend/routes/adminRoute.js` (`addStripeAccountToKitchen` is registered **before** admin auth middleware)
- **Issue:** Unauthenticated callers can link Stripe account IDs to kitchens.
- **Fix:** Move the route below `authenticateAdmin`. Do not register it twice.

### 5. Unauthenticated Stripe OAuth start — High

- **Where:** `Backend/routes/stripeRoute.js`, `Backend/controllers/stripe.js` (`startStripeOAuth`)
- **Issue:** `GET /api/stripe/oauth/start/:kitchenId` requires no kitchen or admin session.
- **Fix:** Require an authenticated kitchen (or admin) that owns `kitchenId` before starting OAuth.

### 6. Payment capture before ownership check — High

- **Where:** `Backend/controllers/vendorController.js` (`acceptOrder`)
- **Issue:** Stripe `paymentIntents.capture()` can run before verifying the order belongs to the authenticated kitchen.
- **Fix:** Confirm `order.kitchenId` matches the authenticated kitchen **before** any Stripe capture or update.

### 7. Unauthenticated file uploads — High

- **Where:** `Backend/routes/userRoute.js`, `Backend/routes/adminRoute.js`, `Backend/routes/vendotRoute.js` (`POST /upload`, `POST /uploads` registered before auth)
- **Issue:** Anyone can upload files to S3. Multer has no file-size limit and trusts client MIME types.
- **Fix:** Require auth on all upload routes. Set size/count limits. Allowlist folder names. Verify file type server-side.

### 8. Socket.IO rooms joined without JWT — High

- **Where:** `Backend/utils/socket.js`; `Admin_Portal/src/services/socket.ts`; `User_App/lib/Controllers/socket_controller.dart`; `Vendor_App/lib/Services/kitchen_socket.dart`
- **Issue:** Clients join `user_{userId}`, `kitchen_{kitchenId}`, and `admins` rooms from query params (`role`, `userId`, `adminId`, `kitchenId`). Handshake does not verify a JWT. Admin client falls back to `adminId` `1` on parse failure.
- **Fix:** Authenticate the WebSocket handshake with the same JWT used for REST. Authorize room membership on the server. Never trust client-supplied IDs.

### 9. Admin RBAC is UI-only — High

- **Where:** Backend `authenticateAdmin` (loads role but does not enforce permissions); Admin Portal `localStorage` `AccessItems`; `RouteGuard.tsx` exists but is not wired into the router
- **Issue:** Any authenticated admin can call payout, user-management, and config APIs. The portal hides menus client-side; detail/form routes and several write actions are not permission-gated.
- **Fix:** Add permission checks on every admin API. Treat UI checks as UX only. Wire `RouteGuard` into private routes.

### 10. Vendor team members get a full kitchen-owner JWT — High

- **Where:** `Backend/controllers/vendorController.js` (`loginKitchen`); `Vendor_App/lib/Utils/access_helper.dart`
- **Issue:** Team login issues `{ id: kitchenId, role: "KITCHEN" }`. Middleware does not distinguish team members. The vendor app only hides UI using local `isTeamMember`; `hasAccess()` is largely unused.
- **Fix:** Put `teamMemberId` and permission scope in the JWT. Enforce authorization in sensitive backend handlers.

### 11. CORS allows all origins — High

- **Where:** `Backend/app.js`, `Backend/utils/socket.js`
- **Issue:** Express CORS and Socket.IO use `origin: *`.
- **Fix:** Restrict to known frontend origins per environment.

### 12. Tokens and passwords stored or logged insecurely — High

- **Where:**
  - Backend `utils/authentication.js` logs full bearer tokens
  - Admin Portal stores JWT and permissions in `localStorage`; login form logs credentials
  - Flutter apps store JWT in unencrypted SharedPreferences
  - Vendor app logs login payload including password; splash logs token
  - User App sets `android:usesCleartextTraffic="true"`
- **Fix:** Remove token/password logging. Store mobile tokens in secure storage (Keychain/Keystore). Prefer httpOnly cookies for the admin session, or short-lived JWTs. Disable cleartext HTTP in the User App.

---

## Backend (Node.js / Express / Prisma)

**Stack:** Express 5, Prisma/PostgreSQL, JWT, Firebase Admin, Stripe Connect, S3, Socket.IO.

### Authentication and authorization (additional)

| Severity | Finding | Location | Remediation |
|----------|---------|----------|-------------|
| Medium | JWT lifetime is 10 days with no refresh/revocation. Admin tokens are stored in DB on login but not checked on later requests. | User/vendor/admin controllers | Shorter access tokens + refresh; optional denylist |
| Medium | Hardcoded OTP bypass for a test email even in production | `userController.js` (`sendOtp`) | Remove hardcoded bypass |
| Medium | OTP defaults to a fixed value when `NODE_ENV !== 'production'` | User, admin, vendor controllers | Random OTPs in all deployed environments |
| Medium | OTPs stored in plaintext with no TTL or attempt lockout | Prisma `VerifyEmail` / Kitchen / AdminUsers | Expiry, hash at rest, per-email limits |
| Low | User `DEACTIVATED` / `ON_HOLD` checks are commented out | `utils/authentication.js` | Re-enable status checks |

### Secrets and logging

| Severity | Finding | Location | Remediation |
|----------|---------|----------|-------------|
| High | Firebase Admin SDK path is hardcoded next to controllers; `.gitignore` does not exclude service-account JSON | `controllers/firebaseAuth.js` | Load from secret manager; gitignore `*firebase*adminsdk*.json`; rotate if ever committed |
| Medium | First 10 characters of Stripe webhook secret logged | `userController.js` (`stripeWebhook`) | Never log secret material |
| Medium | Social-login ID tokens logged | Google/Apple/Facebook login handlers | Stop logging auth tokens |
| Low | SMTP username hardcoded | `utils/emailService.js` | Move to env |

`.env` is gitignored (good). There is no `.env.example` documenting required variables.

### Uploads, webhooks, and config

| Severity | Finding | Location | Remediation |
|----------|---------|----------|-------------|
| Medium | `req.body.folder` is concatenated into S3 keys without an allowlist | `imageUpload.js` | Allowlist folder names |
| Medium | Stripe webhook v2 events skip signature verification | `userController.js` | Verify every webhook payload |
| Medium | Onboarding embed puts Stripe key/secret in the query string | `stripe.js` (`onboardingEmbed`) | Use POST or a one-time server session |
| Medium | Unauthenticated `getConfig` returns full platform config | User and vendor controllers | Return only client-needed keys |
| Medium | Global rate limit is 200 req/min on `/api`; auth endpoints are not specially protected | `app.js` | Stricter limits on login/OTP/reset |
| Medium | `morgan("dev")` in all environments | `app.js` | Redact sensitive fields in production |
| Low | `/health` returns `NODE_ENV` | `app.js` | Minimal public health payload |

### Sensitive data

- Any authenticated admin can fetch bulk user PII (`getAllUserDetails`) because RBAC is not enforced.
- Full Stripe event bodies are stored and listed via `getStripeLogs`.
- Kitchen order details include customer name and phone (may be needed operationally; minimize and audit access).

### Dependencies (high level)

- `xlsx` is used for admin bulk upload; keep it updated.
- Both `bcrypt` and `bcryptjs` are present; unused `razorpay` is imported.
- Prisma parameterized queries are used in handlers (low SQL-injection risk). No `eval` / shell execution found in application code.

---

## Admin Portal (React / Vite)

| Severity | Finding | Location | Remediation |
|----------|---------|----------|-------------|
| High | Permissions in `localStorage` control UI; `RouteGuard` is unused | `permissions.ts`, `routes.tsx` | Enforce on API; wire `RouteGuard` |
| High | Detail/form routes have no read-permission guard | orders, payouts, kitchens, roles, teams, config | Guard all nested routes |
| High | Several mutations skip write/edit/delete checks | users status, notifications, roles, teams, config | Gate every mutating action |
| High | JWT in `localStorage` (XSS can steal it) | login, `authSlice`, axios config | httpOnly cookies or short-lived tokens |
| High | Profile password change reuses forgot-password API (no current password) | `profile.tsx` | Dedicated endpoint requiring current password |
| High | Socket identity from query params; fallback admin ID `1` | `socket.ts` | JWT on handshake |
| Medium | Login credentials logged to the browser console | `login.tsx` | Remove credential logging |
| Medium | Logout is client-only; `logoutUser()` is never called | Header / auth slice | Revoke token server-side |
| Medium | Config display assigns API HTML via `innerHTML` | `Configs.tsx` | Render as text or sanitize |
| Medium | User-controlled URLs in `href` / `src` (banners, alerts, chat) | banners, AlertsDrawer, SupportChatWindow | Allowlist `https:` / `http:` only |
| Medium | Role and notification changes save without confirmation | permissions, ComposeNotification | Confirm + server audit log |
| Low | No CSP in `index.html` / Vite config | hosting layer | Set CSP and frame-ancestors at CDN |

No hardcoded admin passwords or API keys were found in portal source. Env files are gitignored.

---

## User App and Vendor App (Flutter)

### Secrets and environment

| Severity | Finding | Apps | Remediation |
|----------|---------|------|-------------|
| Critical | Keystore passwords committed | Both | Remove, rotate, gitignore |
| High | Google Maps / Places API keys hardcoded in manifests, iOS delegates, and Dart | Both | Restrict keys by app ID; proxy Places via backend |
| Medium | Facebook App ID and client token in Android strings | User | Restrict app; rotate if repo is public |
| Medium | Stripe **test** publishable key while API is production | User `main.dart` | Align keys with environment |
| Medium | Stripe test **and** live publishable keys hardcoded | Vendor `api.dart` | Inject per build flavor |
| Medium | Release builds point at **dev API** (`xapi.resqboxfood.com`) | Vendor `main.dart` | Flavor-based environment; fail CI if wrong |

Firebase configs in `google-services.json` / `firebase_options.dart` are expected for mobile, but should be restricted in Google Cloud Console.

### Storage, network, and auth

| Severity | Finding | Apps | Remediation |
|----------|---------|------|-------------|
| High | JWT in SharedPreferences (unencrypted) | Both | `flutter_secure_storage` |
| High | Cleartext HTTP allowed app-wide | User AndroidManifest | `usesCleartextTraffic="false"` |
| Medium | No certificate pinning | Both | Consider pinning API hosts |
| Medium | Stripe WebView allows mixed content and strips CSP | Vendor | HTTPS-only; keep CSP |
| Medium | Custom scheme `resqboxvendor://`; success if URL `contains('success')` | Vendor | Strict callback validation server-side |
| High | Team-member restrictions are UI-only | Vendor | Server RBAC |
| Medium | Guest mode (`loginType=skip`) is client-gated | User | Mutating APIs must require JWT |
| Medium | Single-image upload helper omits Authorization header | Vendor | Always send bearer token |

---

## What looks solid

- Most database access uses Prisma (parameterized), so SQL injection risk is low.
- No `eval` or command-execution patterns in application code.
- Helmet is enabled on the API; a global rate limiter exists (too coarse for auth).
- `.env` is not committed.
- Admin portal list pages generally redirect to `/403` when read permission is missing.
- Several destructive admin flows (team delete, kitchen approve/reject, logout) use confirmation dialogs.
- React default escaping is used for most user-visible text.

---

## Recommended fix order

1. Remove or lock down public `adminSignUp` and unauthenticated `addStripeAccountToKitchen`.
2. Require a verified OTP token for password reset (admin and vendor).
3. Require auth on all upload endpoints; check kitchen ownership before payment capture.
4. Authenticate Socket.IO; restrict CORS to known origins.
5. Remove secrets, tokens, and passwords from logs; load Firebase credentials from a secret store.
6. Enforce admin permissions and vendor team-member scopes on the server.
7. Harden OTP (expiry, rate limits, no hardcoded bypass).
8. Remove keystores from git, rotate signing credentials, disable User App cleartext traffic.
9. Align Vendor App and User App Stripe/API environments with production vs development.
10. Add upload size limits and S3 folder allowlisting.

---

## Notes

This review is a **code-level security assessment**, not a live penetration test of production. It does not include exploit payloads, attack procedures, or copied secrets.

Rotate any credentials that have been in this repository (signing keys, Maps keys, Firebase keys, Stripe publishable keys as a precaution) and treat this report as internal.
