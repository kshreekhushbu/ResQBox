
require('dotenv').config();
const http = require("http");
const logger = require("./utils/logger");

const createApp = require("./app");
const { initSocket } = require("./utils/socket"); // ⭐ updated path

console.log("Environment Running:", process.env.NODE_ENV);

const PORT = 9000;

// Create express app
const app = createApp();

// Create HTTP server
const server = http.createServer(app);

// ⭐ Initialize Socket.IO
initSocket(server);

// Start server
server.listen(PORT, () => {
  console.log(`server is running on port: ${PORT}`);
  logger.debug(`server is running on port: ${PORT}`);

  // ⭐ Initialize cron jobs for scheduled tasks
  try {
    const { initializeCronJobs } = require("./cron/cronJobs");
    initializeCronJobs();
  } catch (error) {
    console.error("⚠️  Failed to initialize cron jobs:", error.message);
    console.error("   Make sure 'node-cron' package is installed: npm install node-cron");
  }
});

// Error handling
server.on('error', (error) => {
  logger.error('HTTP server error:', error);
});

process.on("uncaughtException", (error) => {
  console.log(error);
  process.exit(1);
});

process.on("unhandledRejection", (err) => {
  logger.debug("UnhandledRejection shutting down!!😈..");
  logger.debug(err.name, err.message, err);
});
