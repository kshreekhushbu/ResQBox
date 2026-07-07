const jwt = require("jsonwebtoken");
const catchAsync = require("./catchAsync");
const prisma = require("./prisma");

exports.authenticateUser = catchAsync(async (req, res, next) => {
  if (!req.headers.authorization) {
    return res.status(401).json({ status: 0, message: "Token empty" });
  }

  const token = req.headers.authorization.split(" ")[1];
  console.log("User token:", token)
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
    if (!decoded) {
      return res.status(401).json({ status: 0, message: "Invalid user.", isTokenExpired: 1 });
    }

    const user = await prisma.user.findUnique({
      where: { userId: Number(decoded.userId), status: "ACTIVE" }, // ✅ Use decoded.userId
    });

    if (!user) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized User",
        isTokenExpired: 1,
      });
    }

    // // ✅ Check user status
    // if (user.status === "DEACTIVATED") {
    //   return res.status(403).json({
    //     status: 0,
    //     message: "Your account has been deactivated. Please contact support.",
    //     accountStatus: "DEACTIVATED",
    //     reason: user.statusReason
    //   });
    // }

    // if (user.status === "ON_HOLD") {
    //   return res.status(403).json({
    //     status: 0,
    //     message: "Your account is on hold. Please contact support.",
    //     accountStatus: "ON_HOLD",
    //     reason: user.statusReason
    //   });
    // }

    // User is ACTIVE - proceed
    req.user = user;
    next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({ status: 0, message: "Token expired", isTokenExpired: 1 });
    }
    return res.status(401).json({ status: 0, message: "Invalid token", isTokenExpired: 0 });
  }
});


exports.authenticateAdmin = catchAsync(async (req, res, next) => {
  try {
    if (!req.headers.authorization) {
      return res.status(401).json({ status: 0, message: "Token empty" });
    }

    const token = req.headers.authorization.split(" ")[1];
    console.log("Admin token:", token);

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
    } catch (err) {
      if (err.name === "TokenExpiredError") {
        return res.status(401).json({
          status: 0,
          message: "Token expired",
          isTokenExpired: 1
        });
      }

      return res.status(401).json({
        status: 0,
        message: "Invalid token",
        isTokenExpired: 0
      });
    }

    // Check admin exists
    const admin = await prisma.adminUsers.findUnique({
      where: { adminId: Number(decoded.adminId) }
    });

    if (!admin) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized Admin User",
        isTokenExpired: 1,
      });
    }

    // Fetch role name from adminRoles table
    let roleName = 'ADMIN'; // Default fallback
    if (admin.roleId) {
      try {
        const role = await prisma.adminRoles.findUnique({
          where: { id: admin.roleId },
          select: { role: true }
        });
        if (role && role.role) {
          roleName = role.role;
        }
      } catch (error) {
        console.log('⚠️ Could not fetch role name:', error.message);
      }
    }

    // Attach admin with role name
    req.admin = {
      ...admin,
      roleName // Add role name for easy access
    };
    next();

  } catch (error) {
    console.log("AUTH ADMIN ERROR:", error);
    return res.status(500).json({
      status: 0,
      message: "Authentication failed"
    });
  }
});


exports.authenticateKitchen = catchAsync(async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  console.log("Kitchen token:", token);

  if (!token) {
    return res.status(401).json({
      status: 0,
      message: "Token empty",
      isTokenExpired: 1
    });
  }

  try {
    // 🔐 Verify JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    // Validate payload
    if (!decoded.id || decoded.role !== "KITCHEN") {
      return res.status(401).json({
        status: 0,
        message: "Invalid token payload",
        isTokenExpired: 1
      });
    }

    // Fetch kitchen from DB
    const kitchen = await prisma.kitchen.findUnique({
      where: { kitchenId: decoded.id }
    });

    if (!kitchen || kitchen.status !== "APPROVED") {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized",
        isTokenExpired: 1
      });
    }

    // Attach to request
    req.kitchen = kitchen;
    next();

  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        status: 0,
        message: "Token expired",
        isTokenExpired: 1
      });
    }

    return res.status(401).json({
      status: 0,
      message: "Invalid token",
      isTokenExpired: 0
    });
  }
});

exports.authenticateOptionalKitchen = catchAsync(async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];
  console.log("Kitchen token:", token);

  if (!token) {
    return res.status(401).json({
      status: 0,
      message: "Token empty",
      isTokenExpired: 1
    });
  }

  try {
    // 🔐 Verify JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    // Validate payload
    if (!decoded.id || decoded.role !== "KITCHEN") {
      return res.status(401).json({
        status: 0,
        message: "Invalid token payload",
        isTokenExpired: 1
      });
    }

    // Fetch kitchen from DB
    const kitchen = await prisma.kitchen.findUnique({
      where: { kitchenId: decoded.id }
    });

    if (!kitchen) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized",
        isTokenExpired: 1
      });
    }

    // Attach to request
    req.kitchen = kitchen;
    next();

  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        status: 0,
        message: "Token expired",
        isTokenExpired: 1
      });
    }

    return res.status(401).json({
      status: 0,
      message: "Invalid token",
      isTokenExpired: 0
    });
  }
});

/**
 * Optional User Authentication Middleware
 * - If token is provided and valid: sets req.user
 * - If token is missing or invalid: continues without req.user
 * - Never blocks the request
 */
exports.optionalAuthenticateUser = catchAsync(async (req, res, next) => {
  // Check if authorization header exists
  if (!req.headers.authorization) {
    console.log("No token provided - continuing without authentication");
    return next(); // ✅ Continue without authentication
  }

  const token = req.headers.authorization.split(" ")[1];

  if (!token) {
    console.log("Empty token - continuing without authentication");
    return next(); // ✅ Continue without authentication
  }

  console.log("Optional user token:", token);

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    if (!decoded || !decoded.userId) {
      console.log("Invalid token payload - continuing without authentication");
      return next(); // ✅ Continue without authentication
    }

    const user = await prisma.user.findUnique({
      where: { userId: Number(decoded.userId), status: "ACTIVE" },
    });

    if (user) {
      req.user = user; // ✅ Set user if found
      console.log("User authenticated:", user.userId);
    } else {
      console.log("User not found - continuing without authentication");
    }

    next(); // ✅ Always continue
  } catch (error) {
    // Token expired or invalid - just continue without authentication
    if (error.name === "TokenExpiredError") {
      console.log("Token expired - continuing without authentication");
    } else {
      console.log("Token validation error - continuing without authentication:", error.message);
    }
    next(); // ✅ Always continue
  }
});

