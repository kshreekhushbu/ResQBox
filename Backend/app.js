const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const parser = require("body-parser");
const rateLimit = require("express-rate-limit");
const globalErrorHandler = require("./controllers/errorController");
// const formatAmountsMiddleware = require("./middleware/formatAmounts");
const adminRoutes = require("./routes/adminRoute");
const vendorRoutes = require('./routes/vendotRoute')
const userRoutes = require('./routes/userRoute')
const stripeRoutes = require('./routes/stripeRoute')
const helmet = require("helmet");
module.exports = () => {  // removed io parameter
  const app = express();

  app.set("trust proxy", 1);

  const limiter = rateLimit({
    max: 200,
    windowMs: 1 * 60 * 1000,
    message: async (req, res) => {
      return res.status(400).json({
        status: 0,
        message: "You're clicking too quickly. Please wait a few seconds and try again.",
      });
    },
  });

  app.use(cors());
  app.use(morgan("dev"));
  app.use(helmet());

  // ⚠️ CRITICAL: Stripe webhook needs raw body for signature verification
  // This MUST come BEFORE any body parsing middleware
  // Apply raw body parser ONLY to the webhook endpoint
  app.use(
    "/api/user/stripeWebhook",
    express.raw({
      type: "application/json",
      verify: (req, res, buf) => {
        // Store raw body for Stripe signature verification
        req.rawBody = buf.toString('utf8');
      }
    })
  );

  // Body parsers for all other routes (skip webhook route)
  app.use((req, res, next) => {
    if (req.originalUrl === '/api/user/stripeWebhook') {
      next();
    } else {
      parser.urlencoded({ extended: false })(req, res, next);
    }
  });

  app.use((req, res, next) => {
    if (req.originalUrl === '/api/user/stripeWebhook') {
      next();
    } else {
      express.json({ limit: "5mb" })(req, res, next);
    }
  });

  app.use("/api", limiter);

  // ⭐ Format all amounts to 2 decimal places in API responses
  // app.use(formatAmountsMiddleware);
  //  // ✅ Add io to all requests BEFORE routes
  //   app.use((req, res, next) => {
  //     req.io = io;
  //     next();
  //   });
  // Routes
  app.use("/api/admin", adminRoutes);
  app.use("/api/vendor", vendorRoutes)
  app.use("/api/user", userRoutes)
  app.use("/api/stripe", stripeRoutes)

  // 🏥 Health Check API
  app.get("/health", (req, res) => {
    res.status(200).json({
      status: 1,
      message: "ResQBox API is healthy",
      timestamp: new Date().toISOString(),
      env: process.env.NODE_ENV
    });
  });

  // ✅ Test API
  app.get("/api/test", (req, res) => {
    res.status(200).json({
      status: 1,
      message: "Server is running and API is reachable!"
    });
  });

  // Catch-all route for missing endpoints
  app.all(new RegExp(".*"), (req, res) => {
    res.status(404).json({
      Status: 0,
      Message: `This endpoint does not exist ${req.method} ${req.originalUrl} on this Server!`,
    });
  });

  // JSON parsing error handler
  app.use((error, req, res, next) => {
    if (error instanceof SyntaxError && error.status === 400 && 'body' in error) {
      console.error('JSON parsing error:', error.message);
      return res.status(400).json({
        status: 0,
        message: 'Invalid JSON format in request body',
        error: error.message
      });
    }
    next(error);
  });

  // Global error handling
  app.use(globalErrorHandler);

  return app;
};
