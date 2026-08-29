const SENSITIVE_KEY_PATTERN = /secret|password|token|webhook|private|api[_-]?key|smtp/i;

function filterPublicConfig(configRows = []) {
  return configRows.filter((row) => !SENSITIVE_KEY_PATTERN.test(String(row.configKey || "")));
}

function corsOriginDelegate() {
  const fromEnv = (process.env.CORS_ORIGINS || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  const allowed = fromEnv.length
    ? fromEnv
    : [
        "https://resqboxfood.com",
        "https://www.resqboxfood.com",
        "https://admin.resqboxfood.com",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8080",
      ];

  return (origin, callback) => {
    if (!origin) {
      return callback(null, true);
    }
    if (allowed.includes(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  };
}

module.exports = {
  filterPublicConfig,
  corsOriginDelegate,
};
