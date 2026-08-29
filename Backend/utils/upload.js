const multer = require("multer");

const MAX_FILE_SIZE = 5 * 1024 * 1024;
const MAX_FILES = 10;

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_FILE_SIZE,
    files: MAX_FILES,
  },
});

function sanitizeFolder(folder) {
  const raw = String(folder || "uploads").trim();
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(raw)) {
    return "uploads";
  }
  return raw;
}

module.exports = {
  upload,
  sanitizeFolder,
  MAX_FILE_SIZE,
};
