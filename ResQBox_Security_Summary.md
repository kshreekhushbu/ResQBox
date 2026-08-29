# ResQBox Security Findings — Short Report

**Date:** 29 August 2026  
**Scope:** Backend, Admin Portal, User App, Vendor App  
**Method:** Static code review (not a live penetration test)

---

## Summary

The main risk is **weak authentication and access control**. Several admin, payment, upload, and realtime paths skip auth or trust the client.

---

## Critical / High

| # | Finding | Where |
|---|---------|--------|
| 1 | Anyone can create an admin account | `POST /api/admin/adminSignUp` |
| 2 | Password can be reset with only an email (OTP is not required at reset) | Admin and vendor `resetPassword` |
| 3 | Android signing passwords and a vendor keystore are in the repo | `User_App/android/key.properties`, `Vendor_App/android/key.properties`, `*.jks` |
| 4 | Stripe kitchen linking and OAuth start are unauthenticated | Admin Stripe route (before auth), `GET /api/stripe/oauth/start/:kitchenId` |
| 5 | File uploads to S3 do not require login | User, vendor, and admin `/upload` |
| 6 | Socket.IO rooms join from query params (`userId` / `kitchenId` / `adminId`) with no JWT | Backend socket + all clients |
| 7 | Admin permissions are UI-only; any logged-in admin can call sensitive APIs | Admin portal `localStorage` + backend routes |
| 8 | Team members receive a full kitchen-owner JWT | Vendor login |
| 9 | Order payment can be captured before kitchen ownership is checked | `acceptOrder` |
| 10 | JWTs and (vendor) login passwords are logged; tokens stored in plaintext | Backend logs, `localStorage`, SharedPreferences |

---

## Also notable

- CORS allows all origins (`*`)
- User App allows cleartext HTTP
- OTPs have no real expiry; a test email uses a fixed OTP
- Vendor release builds point at the **dev API**; User App uses a **Stripe test key** against production

---

## What looks solid

- Database access uses Prisma (low SQL-injection risk)
- No command-execution / `eval` patterns in app code
- `.env` is gitignored; Helmet and a global rate limit exist

---

## Fix first

1. Close public admin signup and unauthenticated Stripe/upload routes  
2. Require a verified OTP token for password reset  
3. Authenticate Socket.IO; check order ownership before payment capture  
4. Enforce admin and team-member roles **on the server**  
5. Remove secrets from git, rotate signing keys, stop logging tokens  

---

This is a **code security assessment**, not a pentest of production. Rotate any credentials that have been in this repository.
