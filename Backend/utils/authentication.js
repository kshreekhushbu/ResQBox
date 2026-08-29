const jwt = require("jsonwebtoken");
const catchAsync = require("./catchAsync");
const prisma = require("./prisma");

function extractBearerToken(req) {
  const header = req.headers.authorization;
  if (!header) return null;
  const parts = header.split(" ");
  if (parts.length === 2 && /^Bearer$/i.test(parts[0]) && parts[1]) {
    return parts[1];
  }
  if (parts.length === 1 && parts[0]) {
    return parts[0];
  }
  return null;
}

function isSuperAdmin(admin) {
  if (!admin) return false;
  if (Number(admin.roleId) === 1) return true;
  const roleName = String(admin.roleName || "").toLowerCase();
  return roleName.includes("super");
}

exports.extractBearerToken = extractBearerToken;
exports.isSuperAdmin = isSuperAdmin;

exports.authenticateUser = catchAsync(async (req, res, next) => {
  const token = extractBearerToken(req);
  if (!token) {
    return res.status(401).json({ status: 0, message: "Token empty" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
    if (!decoded) {
      return res.status(401).json({ status: 0, message: "Invalid user.", isTokenExpired: 1 });
    }

    const user = await prisma.user.findUnique({
      where: { userId: Number(decoded.userId), status: "ACTIVE" },
    });

    if (!user) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized User",
        isTokenExpired: 1,
      });
    }

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
    const token = extractBearerToken(req);
    if (!token) {
      return res.status(401).json({ status: 0, message: "Token empty" });
    }

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

    if (!decoded.adminId) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized Admin User",
        isTokenExpired: 1,
      });
    }

    const admin = await prisma.adminUsers.findUnique({
      where: { adminId: Number(decoded.adminId) }
    });

    if (!admin || admin.status !== 1) {
      return res.status(401).json({
        status: 0,
        message: "Unauthorized Admin User",
        isTokenExpired: 1,
      });
    }

    if (admin.token !== token) {
      return res.status(401).json({
        status: 0,
        message: "Session expired",
        isTokenExpired: 1,
      });
    }

    let roleName = "ADMIN";
    let permissions = [];
    if (admin.roleId) {
      try {
        const role = await prisma.adminRoles.findUnique({
          where: { id: admin.roleId },
          select: { role: true, permissions: true }
        });
        if (role?.role) {
          roleName = role.role;
        }
        if (role?.permissions) {
          permissions = Array.isArray(role.permissions)
            ? role.permissions
            : Array.isArray(role.permissions.permissions)
              ? role.permissions.permissions
              : [];
        }
      } catch (error) {
        console.log("Could not fetch role name:", error.message);
      }
    }

    req.admin = {
      ...admin,
      roleName,
      permissions
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

exports.requirePermission = (pageName, action = "read") =>
  catchAsync(async (req, res, next) => {
    if (isSuperAdmin(req.admin)) {
      return next();
    }

    const permissions = Array.isArray(req.admin?.permissions)
      ? req.admin.permissions
      : [];
    const item = permissions.find(
      (entry) =>
        String(entry.PageName || entry.pageName || "").toLowerCase() ===
        String(pageName).toLowerCase()
    );

    if (!item || Number(item[action]) !== 1) {
      return res.status(403).json({
        status: 0,
        message: "Insufficient permissions",
      });
    }

    next();
  });

exports.requireKitchenOwner = catchAsync(async (req, res, next) => {
  if (req.isTeamMember) {
    return res.status(403).json({
      status: 0,
      message: "This action is limited to the kitchen owner",
    });
  }
  next();
});

exports.authenticateKitchen = catchAsync(async (req, res, next) => {
  const token = extractBearerToken(req);

  if (!token) {
    return res.status(401).json({
      status: 0,
      message: "Token empty",
      isTokenExpired: 1
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    if (!decoded.id || decoded.role !== "KITCHEN") {
      return res.status(401).json({
        status: 0,
        message: "Invalid token payload",
        isTokenExpired: 1
      });
    }

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

    req.kitchen = kitchen;
    req.isTeamMember = Boolean(decoded.teamMemberId);
    req.teamMemberId = decoded.teamMemberId || null;
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
  const token = extractBearerToken(req);

  if (!token) {
    return res.status(401).json({
      status: 0,
      message: "Token empty",
      isTokenExpired: 1
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    if (!decoded.id || decoded.role !== "KITCHEN") {
      return res.status(401).json({
        status: 0,
        message: "Invalid token payload",
        isTokenExpired: 1
      });
    }

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

    req.kitchen = kitchen;
    req.isTeamMember = Boolean(decoded.teamMemberId);
    req.teamMemberId = decoded.teamMemberId || null;
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

exports.optionalAuthenticateUser = catchAsync(async (req, res, next) => {
  const token = extractBearerToken(req);
  if (!token) {
    return next();
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);

    if (!decoded || !decoded.userId) {
      return next();
    }

    const user = await prisma.user.findUnique({
      where: { userId: Number(decoded.userId), status: "ACTIVE" },
    });

    if (user) {
      req.user = user;
    }

    next();
  } catch (error) {
    next();
  }
});
