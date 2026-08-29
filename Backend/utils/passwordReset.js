const jwt = require("jsonwebtoken");

function issueResetToken({ email, audience }) {
  return jwt.sign(
    {
      email,
      audience,
      purpose: "password_reset",
    },
    process.env.JWT_SECRET_KEY,
    { expiresIn: "10m" }
  );
}

function verifyResetToken(resetToken, expectedAudience) {
  if (!resetToken) {
    const error = new Error("Reset token is required");
    error.statusCode = 400;
    throw error;
  }

  let decoded;
  try {
    decoded = jwt.verify(resetToken, process.env.JWT_SECRET_KEY);
  } catch (err) {
    const error = new Error("Invalid or expired reset token");
    error.statusCode = 400;
    throw error;
  }

  if (decoded.purpose !== "password_reset") {
    const error = new Error("Invalid reset token");
    error.statusCode = 400;
    throw error;
  }

  if (expectedAudience && decoded.audience !== expectedAudience) {
    const error = new Error("Invalid reset token");
    error.statusCode = 400;
    throw error;
  }

  return decoded;
}

module.exports = {
  issueResetToken,
  verifyResetToken,
};
