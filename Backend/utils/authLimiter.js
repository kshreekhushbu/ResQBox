const rateLimit = require("express-rate-limit");

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return res.status(429).json({
      status: 0,
      message: "Too many attempts. Please wait a few minutes and try again.",
    });
  },
});

const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return res.status(429).json({
      status: 0,
      message: "Too many uploads. Please wait and try again.",
    });
  },
});

module.exports = {
  authLimiter,
  uploadLimiter,
};
