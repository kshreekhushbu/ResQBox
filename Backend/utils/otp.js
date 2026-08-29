const crypto = require("crypto");

const OTP_TTL_MS = 10 * 60 * 1000;

function isLocalDev() {
  return process.env.NODE_ENV === "development";
}

function generateOtp() {
  if (isLocalDev()) {
    return "123456";
  }
  return String(crypto.randomInt(100000, 1000000));
}

function isOtpFresh(updatedAt) {
  if (!updatedAt) return false;
  return Date.now() - new Date(updatedAt).getTime() <= OTP_TTL_MS;
}

module.exports = {
  generateOtp,
  isOtpFresh,
  isLocalDev,
  OTP_TTL_MS,
};
