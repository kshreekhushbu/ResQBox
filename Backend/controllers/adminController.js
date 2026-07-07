const catchAsync = require("../utils/catchAsync");
const Api400Error = require("../utils/errorCode400");
const handleFactory = require("./handleFactory");
const logger = require("../utils/logger");
const bcrypt = require("bcrypt");
const prisma = require("../utils/prisma");
const jwt = require('jsonwebtoken');
const dayjs = require('dayjs')
const multer = require("multer");
const fs = require("fs");
const xlsx = require("xlsx");
const { generateUID } = require("./handleFactory");
const { messaging } = require("firebase-admin");
const { getIO } = require("../utils/socket");
const auditLogger = require('../utils/auditLogger');


exports.adminSignUp = catchAsync(async (req, res) => {
  try {
    const { name, emailId, password, roleId } = req.body;

    // Check if email exists
    const exists = await prisma.adminUsers.findFirst({
      where: { emailId, status: 1 }
    });

    if (exists) {
      return res.status(400).json({ status: 0, message: "Email already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create admin user
    await prisma.adminUsers.create({
      data: {
        name,
        emailId,
        password: hashedPassword,
        roleId,
        token: ""
      }
    });

    return res.status(200).json({
      status: 1,
      message: "Admin SignUp Completed."
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({
      status: 0,
      message: "Internal Server Error"
    });
  }
});


exports.adminLogin = catchAsync(async (req, res) => {
  try {
    const { emailId, password } = req.body;

    const admin = await prisma.adminUsers.findFirst({
      where: { emailId, status: 1 }
    });

    if (!admin)
      return res.status(400).json({ status: 0, Message: "Account not registered." });

    const isMatch = bcrypt.compareSync(password, admin.password);
    if (!isMatch)
      return res.status(400).json({ status: 0, Message: "Incorrect password" });

    const token = jwt.sign(
      { adminId: admin.adminId },
      process.env.JWT_SECRET_KEY,
      { expiresIn: "10d" }
    );

    await prisma.adminUsers.update({
      where: { adminId: admin.adminId },
      data: { token }
    });

    const role = await prisma.adminRoles.findUnique({
      where: { id: admin.roleId }
    });

    return res.json({
      status: 1,
      Message: "Login Successful",
      Token: token,
      adminDetails: {
        adminId: admin.adminId,
        name: admin.name,
        emailId: admin.emailId,
        roleId: admin.roleId,
        role: role.role,
      },
      permissions: role.permissions

    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ status: 0, Message: "Internal Server Error" });
  }
});

// ⭐ Dashboard API
exports.getDashboard = catchAsync(async (req, res) => {
  try {
    // 📊 Total Restaurants
    const totalRestaurants = await prisma.kitchen.count({
      where: { isActive: { not: 2 } } // Exclude deleted
    });

    // ⏳ Pending Approvals
    const pendingApprovals = await prisma.kitchen.count({
      where: {
        status: "PENDING",
        isActive: { not: 2 }
      }
    });

    // ✅ Approved Restaurants
    const approvedRestaurants = await prisma.kitchen.count({
      where: {
        status: "APPROVED",
        isActive: { not: 2 }
      }
    });

    // 📦 Total Orders
    const totalOrders = await prisma.order.count();

    // 👥 Total Users
    const totalUsers = await prisma.user.count({
      where: { isActive: 1 }
    });

    // ⏰ Expiring Soon (KYC certificates expiring in next 30 days)
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    const expiringSoon = await prisma.kitchenKyc.count({
      where: {
        expireDate: {
          lte: thirtyDaysFromNow,
          gte: new Date()
        }
      }
    });

    // 📈 Monthly Order Trends (Last 6 months)
    const monthlyTrends = [];
    const now = new Date();

    for (let i = 5; i >= 0; i--) {
      const startDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const endDate = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);

      const orderCount = await prisma.order.count({
        where: {
          orderedAt: {
            gte: startDate,
            lte: endDate
          }
        }
      });

      monthlyTrends.push({
        month: startDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
        orders: orderCount
      });
    }

    // 🍽️ Food Types (All active food types)
    const foodTypes = await prisma.foodtype.findMany({
      where: { isActive: 1, type: "KITCHEN" },
      select: {
        id: true,
        name: true,
        image: true
      },
      orderBy: { name: 'asc' }
    });

    const CATEGORY_S3 = process.env.categories_s3 || "";
    const formattedFoodTypes = foodTypes.map(ft => ({
      id: ft.id,
      name: ft.name,
      image: ft.image ? `${CATEGORY_S3}${ft.image}` : null
    }));

    // 🕒 Date helpers
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date(now);
    endOfToday.setHours(23, 59, 59, 999);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);


    // 📅 Today Orders
    const todayOrders = await prisma.order.count({
      where: {
        orderedAt: {
          gte: startOfToday,
          lte: endOfToday
        }
      }
    });

    // 💰 This Month Revenue
    const thisMonthRevenueAgg = await prisma.order.aggregate({
      _sum: { totalAmount: true },
      where: {
        orderedAt: {
          gte: startOfMonth,
          lte: now
        }
      }
    });
    const thisMonthRevenue = thisMonthRevenueAgg._sum.totalAmount || 0;
    return res.status(200).json({
      status: 1,
      message: "Dashboard data fetched successfully",
      data: {
        totalRestaurants,
        pendingApprovals,
        approvedRestaurants,
        totalOrders,
        totalUsers,
        expiringSoon,
        monthlyOrderTrends: monthlyTrends,
        foodTypes: formattedFoodTypes,
        todayorders: todayOrders,
        monthlyAmount: thisMonthRevenue
      }
    });

  } catch (error) {
    console.error("❌ Error in getDashboard:", error);
    return res.status(500).json({
      status: 0,
      message: "Internal server error"
    });
  }
});

exports.createAdminUser = catchAsync(async (req, res) => {
  try {
    let { name, emailId, password, roleId } = req.body;

    if (!name || !emailId || !password || !roleId) {
      return res.status(400).json({ status: 0, message: "All fields are required" });
    }

    // Check if email exists
    const exists = await prisma.adminUsers.findFirst({
      where: { emailId }
    });

    if (exists) {
      return res.status(400).json({ status: 0, message: "Email already exists" });
    }

    // Hash password (async is better)
    const hashPassword = await bcrypt.hash(password, 10);

    await prisma.adminUsers.create({
      data: {
        name,
        emailId,
        password: hashPassword,
        roleId: Number(roleId),
        token: "",
        status: 1,
      }
    });

    return res.status(200).json({
      status: 1,
      message: "Admin user created successfully"
    });

  } catch (error) {
    console.error("❌ Error in createAdminUser:", error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

exports.getSubAdmins = catchAsync(async (req, res) => {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  const search = req.query.search?.toLowerCase() || "";

  const where = {
    roleId: { not: 1 }, // NOT super admin
    status: 1,
    ...(search
      ? {
        OR: [
          { name: { contains: search, mode: "insensitive" } },
          { emailId: { contains: search, mode: "insensitive" } }
        ]
      }
      : {})
  };

  // 1️⃣ Count
  const total = await prisma.adminUsers.count({ where });

  // 2️⃣ Fetch users
  const subadmins = await prisma.adminUsers.findMany({
    where,
    skip,
    take: limit,
    orderBy: { created_at: "desc" }
  });

  // 3️⃣ Get unique roleIds
  const roleIds = [...new Set(subadmins.map(sa => sa.roleId))];

  // 4️⃣ Fetch roles
  const roles = await prisma.adminRoles.findMany({
    where: { id: { in: roleIds } },
    select: { id: true, role: true }
  });

  // 5️⃣ Map roleId → role name
  const roleMap = {};
  roles.forEach(r => {
    roleMap[r.id] = r.role;
  });

  // 6️⃣ Attach roleName to users
  const result = subadmins.map(sa => ({
    ...sa,
    roleName: roleMap[sa.roleId] || null
  }));

  return res.status(200).json({
    status: 1,
    message: "Sub Admins fetched successfully",
    subadmins: result,
    pagination: {
      total,
      currentPage: page,
      totalPages: Math.ceil(total / limit)
    }
  });
});

exports.getAdminUserById = catchAsync(async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        status: 0,
        message: "Admin user id is required"
      });
    }

    const adminUser = await prisma.adminUsers.findFirst({
      where: {
        adminId: Number(id),
        status: 1
      }
    });

    if (!adminUser) {
      return res.status(404).json({
        status: 0,
        message: "Admin user not found"
      });
    }

    return res.status(200).json({
      status: 1,
      adminUser
    });

  } catch (error) {
    console.error("❌ Error in getAdminUserById:", error);
    return res.status(500).json({
      status: 0,
      message: "Internal server error"
    });
  }
});

exports.updateSubAdmin = catchAsync(async (req, res) => {
  const { adminId } = req.params;
  const { name, emailId, password, roleId, status } = req.body;

  let updateData = {};

  if (name) updateData.name = name;

  if (emailId) {
    const exists = await prisma.adminUsers.findFirst({
      where: { emailId, adminId: { not: Number(adminId) } }
    });

    if (exists) {
      return res.status(400).json({ status: 0, message: "Email already exists" });
    }

    updateData.emailId = emailId;
  }

  if (password) {
    updateData.password = await bcrypt.hash(password, 10);
  }

  if (roleId !== undefined) updateData.roleId = roleId;
  if (status !== undefined) updateData.status = status;

  const updated = await prisma.adminUsers.update({
    where: { adminId: Number(adminId) },
    data: updateData
  });

  return res.status(200).json({
    status: 1,
    message: "Sub Admin updated successfully",
    updated
  });
});

exports.deleteSubAdmin = catchAsync(async (req, res) => {
  const { adminId } = req.params;
  const loggedInAdminId = req.user?.adminId; // Get logged-in admin's ID from JWT

  // ⭐ Prevent self-deletion
  if (Number(adminId) === Number(loggedInAdminId)) {
    return res.status(400).json({
      status: 0,
      message: "You cannot delete your own account"
    });
  }

  // ⭐ Fetch the admin to check if they're a super admin
  const adminToDelete = await prisma.adminUsers.findUnique({
    where: { adminId: Number(adminId) },
    select: { roleId: true, name: true }
  });

  if (!adminToDelete) {
    return res.status(404).json({
      status: 0,
      message: "Admin not found"
    });
  }

  // ⭐ Prevent deleting super admin (roleId: 1)
  if (adminToDelete.roleId === 1) {
    return res.status(403).json({
      status: 0,
      message: "You cannot delete a Super Admin account"
    });
  }

  await prisma.adminUsers.update({
    where: { adminId: Number(adminId) },
    data: { status: 2 }  // soft delete
  });

  return res.status(200).json({
    status: 1,
    message: "Sub Admin deleted successfully"
  });
});

exports.getAllRoles = catchAsync(async (req, res) => {
  try {
    const roles = await prisma.adminRoles.findMany({
      orderBy: { id: "asc" },
      select: {
        id: true,
        role: true
      },
      where: {
        role: { not: 'Super Admin' }
      }
    });

    return res.status(200).json({ status: 1, roles });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

exports.getRoleById = catchAsync(async (req, res) => {
  try {

    const { id } = req.params;
    const role = await prisma.adminRoles.findMany({
      orderBy: { id: "asc" },
      where: { id: Number(id) }
    });
    return res.status(200).json({ status: 1, role });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

exports.createRole = catchAsync(async (req, res) => {
  try {
    const { role, permissions } = req.body;

    const exists = await prisma.adminRoles.findUnique({ where: { role } });
    if (exists) {
      return res.status(400).json({ status: 0, message: "Role already exists" });
    }

    await prisma.adminRoles.create({
      data: {
        role,
        permissions: permissions || []
      }
    });

    return res.status(200).json({ status: 1, message: "Role created successfully" });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

exports.updateRolePermissions = catchAsync(async (req, res) => {
  try {
    const roleId = Number(req.params.id);
    const { permissions } = req.body;

    await prisma.adminRoles.update({
      where: { id: roleId },
      data: { permissions }
    });

    return res.status(200).json({
      status: 1,
      message: "Permissions updated successfully"
    });

  } catch (error) {
    console.error(error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

exports.addBanner = catchAsync(async (req, res) => {
  const { banner, linkUrl, linkType } = req.body;

  if (!banner) {
    return res.status(400).json({ status: 0, message: "Banner image is required" });
  }

  await prisma.banner.create({
    data: {
      banner,
      linkUrl,
      linkType
    }
  });

  res.status(201).json({
    status: 1,
    message: "Banner added successfully",
  });
});

// ✅ Update Banner
exports.updateBanner = catchAsync(async (req, res) => {
  const { bannerId } = req.params;
  const { banner, isActive } = req.body;

  const existing = await prisma.banner.findUnique({ where: { bannerId: Number(bannerId) } });
  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Banner not found" });
  }

  const updatedBanner = await prisma.banner.update({
    where: { bannerId: Number(bannerId) },
    data: {
      ...(banner && { banner }),
      ...(isActive && { isActive: Number(isActive) }),
    },
  });

  res.status(200).json({
    status: 1,
    message: "Banner updated successfully",
  });
});

exports.getBanners = catchAsync(async (req, res) => {
  const BASE_URL = process.env.banners_s3; // e.g. https://d1fdhgfmyegey1.cloudfront.net/banners/

  const banners = await prisma.banner.findMany({
    where: { isActive: { not: 2 } },
    orderBy: { createdAt: "desc" },
  });

  const formattedBanners = banners.map((b) => ({
    ...b,
    banner: b.banner ? `${BASE_URL}${b.banner}` : null,
  }));

  res.status(200).json({
    status: 1,
    banners: formattedBanners,
  });
});

exports.deleteBanner = catchAsync(async (req, res) => {
  const { bannerId } = req.params;

  const existing = await prisma.banner.findUnique({
    where: { bannerId: Number(bannerId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Banner not found" });
  }

  await prisma.banner.update({
    where: { bannerId: Number(bannerId) },
    data: { isActive: 2 }
  });

  res.status(200).json({
    status: 1,
    message: "Banner deleted successfully"
  });
});

exports.getBannerById = catchAsync(async (req, res) => {
  const { bannerId } = req.params;
  const BASE_URL = process.env.banners_s3;

  const banner = await prisma.banner.findUnique({
    where: { bannerId: Number(bannerId) },
  });

  if (!banner || banner.isActive === 2) {
    return res.status(404).json({
      status: 0,
      message: "Banner not found",
    });
  }

  const formattedBanner = {
    ...banner,
    banner: banner.banner ? `${BASE_URL}${banner.banner}` : null,
  };

  res.status(200).json({
    status: 1,
    banner: formattedBanner,
  });
});

exports.addCategory = catchAsync(async (req, res) => {
  const { name, image, isPopular } = req.body;

  if (!name) {
    return res.status(400).json({ status: 0, message: "Category name is required" });
  }

  const newCategory = await prisma.category.create({
    data: { name, image, isPopular: Number(isPopular) || 0 },
  });

  res.status(201).json({
    status: 1,
    message: "Category added successfully",
  });
});

exports.updateCategory = catchAsync(async (req, res) => {
  const { categoryId } = req.params;
  const { name, image, isActive, isPopular } = req.body;

  const existing = await prisma.category.findUnique({
    where: { id: Number(categoryId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Category not found" });
  }

  const updatedCategory = await prisma.category.update({
    where: { id: Number(categoryId) },
    data: {
      ...(name && { name }),
      ...(image && { image }),
      ...(isActive !== undefined && { isActive: Number(isActive) }),
      ...(isPopular !== undefined && { isPopular: Number(isPopular) }),
    }
  });

  res.status(200).json({
    status: 1,
    message: "Category updated successfully",
  });
});

exports.getCategories = catchAsync(async (req, res) => {
  const BASE_URL = process.env.categories_s3;
  const { search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const where = {
    isActive: { not: 2 },
    ...(search && {
      name: {
        contains: search,
        mode: 'insensitive'
      }
    })
  };

  // 🧮 Total count
  const totalCategories = await prisma.category.count({ where });

  // 📦 Fetch paginated data
  const categories = await prisma.category.findMany({
    where,
    skip,
    take: limit,
    orderBy: { name: "asc" }
  });

  const formatted = categories.map(c => ({
    ...c,
    image: c.image ? `${BASE_URL}${c.image}` : null
  }));

  return res.status(200).json({
    status: 1,
    categories: formatted,
    pagination: {
      totalRecords: totalCategories,
      currentPage: page,
      totalPages: Math.ceil(totalCategories / limit)
    }
  });
});

exports.getCategoryById = catchAsync(async (req, res) => {
  const { categoryId } = req.params;
  const BASE_URL = process.env.categories_s3;

  const category = await prisma.category.findUnique({
    where: { id: Number(categoryId) }
  });

  if (!category || category.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Category not found" });
  }

  const formatted = {
    ...category,
    image: category.image ? `${BASE_URL}${category.image}` : null
  };

  res.status(200).json({
    status: 1,
    category: formatted,
  });
});

exports.deleteCategory = catchAsync(async (req, res) => {
  const { categoryId } = req.params;

  const existing = await prisma.category.findUnique({
    where: { id: Number(categoryId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Category not found" });
  }

  await prisma.category.update({
    where: { id: Number(categoryId) },
    data: { isActive: 2 }
  });

  res.status(200).json({
    status: 1,
    message: "Category deleted successfully"
  });
});
exports.addFoodType = catchAsync(async (req, res) => {
  const { name, image } = req.body;

  if (!name) {
    return res.status(400).json({ status: 0, message: "Restaurant type name is required" });
  }

  const newFoodType = await prisma.foodtype.create({
    data: { name, image, type: "KITCHEN" },
  });

  res.status(201).json({
    status: 1,
    message: "Restaurant type added successfully",
  });
});

exports.updateFoodType = catchAsync(async (req, res) => {
  const { foodTypeId } = req.params;
  const { name, image, isActive, question } = req.body;

  const existing = await prisma.foodtype.findUnique({
    where: { id: Number(foodTypeId), type: "KITCHEN" }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Restaurant type not found" });
  }

  const updatedFoodType = await prisma.foodtype.update({
    where: { id: Number(foodTypeId), type: "KITCHEN" },
    data: {
      ...(name && { name }),
      ...(image && { image }),
      ...(isActive !== undefined && { isActive: Number(isActive) }),
      ...(question && { question }),
    }
  });

  res.status(200).json({
    status: 1,
    message: "Restaurant type updated successfully",
  });
});

exports.getFoodTypes = catchAsync(async (req, res) => {
  const BASE_URL = process.env.categories_s3;
  const { search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const where = {
    isActive: { not: 2 },
    type: "KITCHEN",
    ...(search && {
      name: {
        contains: search,
        mode: 'insensitive'
      }
    })
  };

  // 🧮 Total count
  const totalFoodTypes = await prisma.foodtype.count({ where });

  // 📦 Fetch paginated data
  const foodTypes = await prisma.foodtype.findMany({
    where,
    skip,
    take: limit,
    orderBy: { createdAt: "desc" }
  });

  const formatted = foodTypes.map(f => ({
    ...f,
    image: f.image ? `${BASE_URL}${f.image}` : null
  }));

  return res.status(200).json({
    status: 1,
    foodTypes: formatted,
    pagination: {
      totalRecords: totalFoodTypes,
      currentPage: page,
      totalPages: Math.ceil(totalFoodTypes / limit)
    }
  });
});

exports.getFoodTypeById = catchAsync(async (req, res) => {
  const { foodTypeId } = req.params;
  const BASE_URL = process.env.categories_s3;

  const foodType = await prisma.foodtype.findUnique({
    where: { id: Number(foodTypeId), type: "KITCHEN" }
  });

  if (!foodType || foodType.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Restaurant type not found" });
  }

  const formatted = {
    ...foodType,
    image: foodType.image ? `${BASE_URL}${foodType.image}` : null
  };

  res.status(200).json({
    status: 1,
    foodType: formatted,
  });
});

exports.deleteFoodType = catchAsync(async (req, res) => {
  const { foodTypeId } = req.params;

  const existing = await prisma.foodtype.findUnique({
    where: { id: Number(foodTypeId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Restaurant type not found" });
  }

  await prisma.foodtype.update({
    where: { id: Number(foodTypeId) },
    data: { isActive: 2 }
  });

  res.status(200).json({
    status: 1,
    message: "Restaurant type deleted successfully"
  });
});

exports.addMenuType = catchAsync(async (req, res) => {
  const { name, image } = req.body;

  if (!name) {
    return res.status(400).json({ status: 0, message: "Food type name is required" });
  }

  const newFoodType = await prisma.foodtype.create({
    data: { name, image, type: "MENU" },
  });

  res.status(201).json({
    status: 1,
    message: "Food type added successfully",
  });
});

exports.updateMenuType = catchAsync(async (req, res) => {
  const { menuTypeId } = req.params;
  const { name, image, isActive, question } = req.body;

  const existing = await prisma.foodtype.findUnique({
    where: { id: Number(menuTypeId), type: "MENU" }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Food type not found" });
  }

  const updatedMenuType = await prisma.foodtype.update({
    where: { id: Number(menuTypeId), type: "MENU" },
    data: {
      ...(name && { name }),
      ...(image && { image }),
      ...(isActive !== undefined && { isActive: Number(isActive) }),
    }
  });

  res.status(200).json({
    status: 1,
    message: "Food type updated successfully",
  });
});


exports.getMenuTypes = catchAsync(async (req, res) => {
  const BASE_URL = process.env.categories_s3;
  const { search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const where = {
    isActive: { not: 2 },
    type: "MENU",
    ...(search && {
      name: {
        contains: search,
        mode: 'insensitive'
      }
    })
  };

  // 🧮 Total count
  const totalFoodTypes = await prisma.foodtype.count({ where });

  // 📦 Fetch paginated data
  const foodTypes = await prisma.foodtype.findMany({
    where,
    skip,
    take: limit,
    orderBy: { createdAt: "desc" }
  });

  const formatted = foodTypes.map(f => ({
    ...f,
    image: f.image ? `${BASE_URL}${f.image}` : null
  }));

  return res.status(200).json({
    status: 1,
    menuTypes: formatted,
    pagination: {
      totalRecords: totalFoodTypes,
      currentPage: page,
      totalPages: Math.ceil(totalFoodTypes / limit)
    }
  });
});

exports.getMenuTypeById = catchAsync(async (req, res) => {
  const { menuTypeId } = req.params;
  const BASE_URL = process.env.categories_s3;

  const menuType = await prisma.foodtype.findUnique({
    where: { id: Number(menuTypeId), type: "MENU" }
  });

  if (!menuType || menuType.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Food type not found" });
  }

  const formatted = {
    ...menuType,
    image: menuType.image ? `${BASE_URL}${menuType.image}` : null
  };

  res.status(200).json({
    status: 1,
    menuType: formatted,
  });
});

exports.deleteMenuType = catchAsync(async (req, res) => {
  const { menuTypeId } = req.params;

  const existing = await prisma.foodtype.findUnique({
    where: { id: Number(menuTypeId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Food type not found" });
  }

  await prisma.foodtype.update({
    where: { id: Number(menuTypeId) },
    data: { isActive: 2 }
  });

  res.status(200).json({
    status: 1,
    message: "Food type deleted successfully"
  });
});

exports.getCuisines = catchAsync(async (req, res) => {
  const BASE_URL = process.env.cuisines_s3;
  const { search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const where = {
    isActive: { not: 2 },
    ...(search && {
      name: {
        contains: search,
        mode: 'insensitive'
      }
    })
  };

  // 🧮 Total count
  const totalCuisines = await prisma.cuisine.count({ where });

  // 📦 Fetch paginated cuisines
  const cuisines = await prisma.cuisine.findMany({
    where,
    skip,
    take: limit,
    orderBy: { name: "asc" }
  });

  const formatted = cuisines.map(c => ({
    ...c,
    image: c.image ? `${BASE_URL}${c.image}` : null
  }));

  return res.status(200).json({
    status: 1,
    cuisines: formatted,
    pagination: {
      totalRecords: totalCuisines,
      currentPage: page,
      totalPages: Math.ceil(totalCuisines / limit)
    }
  });
});


exports.getCuisineById = catchAsync(async (req, res) => {
  const { cuisineId } = req.params;
  const BASE_URL = process.env.cuisines_s3;

  const cuisine = await prisma.cuisine.findUnique({
    where: { id: Number(cuisineId) }
  });

  if (!cuisine || cuisine.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Cuisine not found" });
  }

  const formatted = {
    ...cuisine,
    image: cuisine.image ? `${BASE_URL}${cuisine.image}` : null
  };

  res.status(200).json({
    status: 1,
    cuisine: formatted,
  });
});

exports.addCuisine = catchAsync(async (req, res) => {
  const { name, image, isPopular } = req.body;

  if (!name) {
    return res.status(400).json({ status: 0, message: "Cuisine name is required" });
  }
  if (isPopular === 1 & !image) {
    return res.status(400).json({
      status: 0,
      message: "Popular Cuisine Must have Image"
    });

  }

  if (isPopular === 1) {
    const popularCount = await prisma.cuisine.count({
      where: {
        isPopular: 1,
        isActive: 1
      }
    });

    if (popularCount >= 3) {
      return res.status(400).json({
        status: 0,
        message: "Only 3 cuisines can be marked as popular"
      });
    }
  }

  const newCuisine = await prisma.cuisine.create({
    data: { name, image },
  });

  res.status(201).json({
    status: 1,
    message: "Cuisine added successfully",
  });
});

exports.updateCuisine = catchAsync(async (req, res) => {
  const { cuisineId } = req.params;
  const { name, image, isActive, is_popular } = req.body;
  const isPopular = is_popular === 1 ? 1 : 0;
  const existing = await prisma.cuisine.findUnique({
    where: { id: Number(cuisineId) }
  });
  

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({
      status: 0,
      message: "Cuisine not found"
    });
  }

  // ⭐ Popular cuisine must have image
  if (isPopular === 1 && !image && !existing.image) {
    return res.status(400).json({
      status: 0,
      message: "Popular cuisine must have an image"
    });
  }

  // ⭐ Max 3 popular cuisines (excluding current one)
  if (isPopular === 1 && existing.isPopular !== 1) {
    const popularCount = await prisma.cuisine.count({
      where: {
        isPopular: 1,
        isActive: 1,
        id: { not: Number(cuisineId) }
      }
    });

    if (popularCount >= 3) {
      return res.status(400).json({
        status: 0,
        message: "Only 3 cuisines can be marked as popular"
      });
    }
  }

  await prisma.cuisine.update({
    where: { id: Number(cuisineId) },
    data: {
      ...(name && { name }),
      ...(image && { image }),
      ...(isActive !== undefined && { isActive: Number(isActive) }),
      ...(isPopular !== undefined && { isPopular: Number(isPopular) })
    }
  });

  return res.status(200).json({
    status: 1,
    message: "Cuisine updated successfully"
  });
});


exports.deleteCuisine = catchAsync(async (req, res) => {
  const { cuisineId } = req.params;

  const existing = await prisma.cuisine.findUnique({
    where: { id: Number(cuisineId) }
  });

  if (!existing || existing.isActive === 2) {
    return res.status(404).json({ status: 0, message: "Cuisine not found" });
  }

  await prisma.cuisine.update({
    where: { id: Number(cuisineId) },
    data: { isActive: 2 }
  });

  res.status(200).json({
    status: 1,
    message: "Cuisine deleted successfully"
  });
});


exports.getAllKitchens = catchAsync(async (req, res) => {
  const { status } = req.query;
  const { search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const KITCHEN_IMG = process.env.kitchen_s3 || "";
  const PROFILE_IMG = process.env.kitchen_s3 || "";

  // ⭐ Build where condition
  let where = {};

  // 🔍 Special handling for "EXPIRING" status
  if (status === "EXPIRING") {
    // ⏰ Get kitchens with certificates expiring in next 30 days
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);

    where.kyc = {
      expireDate: {
        lte: thirtyDaysFromNow,
        gte: new Date()
      }
    };
  } else if (status) {
    // Regular status filter (PENDING, APPROVED, REJECTED)
    where.status = status;
  }

  // 🔍 Add search filter if provided
  if (search) {
    where.kitchenName = {
      contains: search,
      mode: 'insensitive'
    };
  }

  // 🧮 Total count
  const totalKitchens = await prisma.kitchen.count({ where });

  // 📦 Fetch paginated kitchens
  const kitchens = await prisma.kitchen.findMany({
    where,
    skip,
    take: limit,
    orderBy: { kitchenId: "desc" },
    include: {
      address: true,
      photos: true,
      cuisines: true,
      ...(status === "EXPIRING" && {
        kyc: {
          select: {
            expireDate: true
          }
        }
      })
    }
  });

  const formatted = kitchens.map((kitchen) => {

    const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
      ? kitchen.photos.kitchenImages
        .map(img =>
          img && img.trim() !== "" && img.trim() !== "NA"
            ? `${KITCHEN_IMG}${img.trim()}`
            : null
        )
        .filter(Boolean)
      : [];

    return {
      kitchenId: kitchen.kitchenId,
      restaurantCode: "REST" + String(kitchen.kitchenId).padStart(4, "0"),
      kitchenName: kitchen.kitchenName,
      email: kitchen.email,
      ownerName: kitchen.ownerName,
      contactNumber: kitchen.contactNumber,
      openingTime: kitchen.openingTime,
      closingTime: kitchen.closingTime,
      description: kitchen.description,
      status: kitchen.status,
      isActive: kitchen.isActive,
      rating: kitchen.rating,
      ratingCount: kitchen.ratingCount,
      createdAt: kitchen.createdAt,
      deviceToken: kitchen.deviceToken,

      address: kitchen.address || null,

      photos: kitchen.photos
        ? {
          kitchenImages,
          kitchenProfilePhoto:
            kitchen.photos.kitchenProfilePhoto &&
              kitchen.photos.kitchenProfilePhoto.trim() !== "" &&
              kitchen.photos.kitchenProfilePhoto.trim() !== "NA"
              ? `${PROFILE_IMG}${kitchen.photos.kitchenProfilePhoto.trim()}`
              : null
        }
        : null,

      cuisines: kitchen.cuisines || []
    };
  });

  return res.status(200).json({
    status: 1,
    message: "Kitchens fetched successfully",
    kitchens: formatted,
    pagination: {
      totalRecords: totalKitchens,
      currentPage: page,
      totalPages: Math.ceil(totalKitchens / limit)
    }
  });
});


// exports.getAllKitchens = catchAsync(async (req, res) => {
//   const { status } = req.query; // Optional filter (e.g. 1=active)

//   const KITCHEN_IMG = process.env.kitchen_s3 || "";
//   const PROFILE_IMG = process.env.kitchen_s3 || "";
//   const MENU_IMG = process.env.menu_s3 || "";
//   const KYC_IMG = process.env.kyc_s3 || "";

//   // Build dynamic where condition
//   const where = {};
//   if (status) where.status = status;

//   const kitchens = await prisma.kitchen.findMany({
//     where,
//     orderBy: { kitchenId: "desc" },
//     include: {
//       address: true,
//       photos: true,
//       cuisines: true
//     }
//   });

//   const formatted = kitchens.map((kitchen) => {

//     // Trim and format kitchenImages
//     const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
//       ? kitchen.photos.kitchenImages
//         .map((img) => img && img.trim() !== "" && img.trim() !== "NA"
//           ? `${KITCHEN_IMG}${img.trim()}` : null
//         )
//         .filter(Boolean) // remove null values
//       : [];

//     return {
//       kitchenId: kitchen.kitchenId,
//       kitchenName: kitchen.kitchenName,
//       email: kitchen.email,
//       ownerName: kitchen.ownerName,
//       contactNumber: kitchen.contactNumber,
//       openingTime: kitchen.openingTime,
//       closingTime: kitchen.closingTime,
//       description: kitchen.description,
//       status: kitchen.status,
//       isActive: kitchen.isActive,
//       rating: kitchen.rating,
//       ratingCount: kitchen.ratingCount,
//       createdAt: kitchen.createdAt,
//       deviceToken: kitchen.deviceToken,

//       // Address
//       address: kitchen.address || null,

//       // Photos
//       photos: kitchen.photos
//         ? {
//           kitchenImages,
//           kitchenProfilePhoto:
//             kitchen.photos.kitchenProfilePhoto &&
//               kitchen.photos.kitchenProfilePhoto.trim() !== "" &&
//               kitchen.photos.kitchenProfilePhoto.trim() !== "NA"
//               ? `${PROFILE_IMG}${kitchen.photos.kitchenProfilePhoto.trim()}`
//               : null
//         }
//         : null,

//       cuisines: kitchen.cuisines || []
//     };
//   });

//   return res.status(200).json({
//     status: 1,
//     message: "Kitchens fetched successfully",
//     kitchens: formatted
//   });
// });



exports.getKitchenDetailsById = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;

  const KITCHEN_IMG = process.env.kitchen_s3 || "";
  const PROFILE_IMG = process.env.kitchen_s3 || "";
  const MENU_IMG = process.env.menu_s3 || "";
  const KYC_IMG = process.env.kyc_s3 || "";

  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) },
    include: {
      address: true,
      kyc: true,
      photos: true,
      items: true,
      cuisines: true,
    }
  });

  if (!kitchen) {
    return res.status(404).json({ status: 0, message: "Kitchen not found" });
  }

  const kitchenImages = Array.isArray(kitchen.photos?.kitchenImages)
    ? kitchen.photos.kitchenImages.map(img => `${KITCHEN_IMG}${img}`)
    : [];

  const formattedKitchen = {
    kitchenId: kitchen.kitchenId,
    kitchenName: kitchen.kitchenName,
    email: kitchen.email,
    ownerName: kitchen.ownerName,
    contactNumber: kitchen.contactNumber,
    openingTime: kitchen.openingTime,
    closingTime: kitchen.closingTime,
    description: kitchen.description,
    status: kitchen.status,
    isActive: kitchen.isActive,
    rating: kitchen.rating,
    ratingCount: kitchen.ratingCount,
    createdAt: kitchen.createdAt,
    deviceToken: kitchen.deviceToken,
    stripeAccountId: kitchen.stripeAccountId,
    address: kitchen.address || null,
    stripeAccountConnected: kitchen.stripeAccountConnected,
    stripeOnboardingCompleted: kitchen.stripeOnboardingCompleted,
    stripeConnectedAt: kitchen.stripeConnectedAt,
    complianceStatus: kitchen.complianceStatus,
    kyc: kitchen.kyc ? {
      abnNumber: kitchen.kyc.abnNumber,
      acn: kitchen.kyc.acn,
      foodCertificateNumber: kitchen.kyc.foodCertificateNumber,
      foodCertificateImage: kitchen.kyc.foodCertificateImage
        ? `${KYC_IMG}${kitchen.kyc.foodCertificateImage}`
        : null,
      // ✅ MULTIPLE CERTIFICATES WITH URL (sorted by latest first)
      foodCertificateImages: Array.isArray(kitchen.kyc.foodCertificateImages)
        ? kitchen.kyc.foodCertificateImages
          .map(cert => ({
            image: cert.image ? `${KYC_IMG}${cert.image}` : null,
            expireDate: cert.expireDate || null,
            addedAt: cert.addedAt || null
          }))
          .sort((a, b) => {
            if (!a.addedAt) return 1;
            if (!b.addedAt) return -1;
            return new Date(b.addedAt) - new Date(a.addedAt);
          })
        : [],

      expireDate: kitchen.kyc.expireDate,
      fssaiNumber: kitchen.kyc.fssaiNumber,
    } : null,

    photos: kitchen.photos ? {
      kitchenImages,
      kitchenProfilePhoto: kitchen.photos.kitchenProfilePhoto
        ? `${PROFILE_IMG}${kitchen.photos.kitchenProfilePhoto}`
        : null,
    } : null,

    items: kitchen.items.map(item => ({
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      price: item.price,
      description: item.description,
      isVegetarian: item.isVegetarian,
      isSpicy: item.isSpicy,
      rating: item.rating,
      ratingCount: item.ratingCount,
      isActive: item.isActive,
      image: item.image ? `${MENU_IMG}${item.image}` : null
    })),

    cuisines: kitchen.cuisines,
  };

  return res.status(200).json({
    status: 1,
    message: "Kitchen details fetched successfully",
    kitchen: formattedKitchen
  });
});

// update kitchen stripe account id 

exports.updateKitchenStripeAccountId = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;
  const { stripeAccountId } = req.body;

  if (!stripeAccountId) {
    return res.status(400).json({
      status: 0,
      message: "stripeAccountId is required"
    });
  }

  // Fetch kitchen
  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  // Determine action type based on whether account already exists
  const oldStripeAccountId = kitchen.stripeAccountId;
  const actionType = oldStripeAccountId
    ? 'STRIPE_ACCOUNT_CHANGED'
    : 'STRIPE_ACCOUNT_LINKED_MANUAL';

  // Update kitchen with Stripe account ID
  await prisma.kitchen.update({
    where: { kitchenId: Number(kitchenId) },
    data: { stripeAccountId }
  });

  // 🔍 CREATE AUDIT LOG
  const auditLogger = require('../utils/auditLogger');
  await auditLogger.createAuditLog({
    kitchenId: Number(kitchenId),
    actorType: 'ADMIN',
    actorId: req.adminId,
    actorName: req.admin?.name || 'Admin',
    actorRole: req.admin?.role || 'ADMIN',
    actionType,
    actionDescription: oldStripeAccountId
      ? `Stripe account ID changed from ${oldStripeAccountId} to ${stripeAccountId}`
      : `Stripe account manually linked: ${stripeAccountId}`,
    oldData: oldStripeAccountId ? oldStripeAccountId : null,
    newData: stripeAccountId,
    metadata: {
      linkedBy: 'ADMIN',
      previousAccountId: oldStripeAccountId || null
    },
    ipAddress: auditLogger.getIpAddress(req),
    userAgent: auditLogger.getUserAgent(req)
  });

  return res.status(200).json({
    status: 1,
    message: "Stripe account added successfully",
    data: {
      kitchenId: kitchen.kitchenId,
      kitchenName: kitchen.kitchenName,
      stripeAccountId
    }
  });
});

// exports.updateKitchenStatus = catchAsync(async (req, res) => {
//   const { kitchenId } = req.params;
//   const { status, expireDate, reason } = req.body;

//   const validStatuses = ["APPROVED", "REJECTED"];

//   if (!validStatuses.includes(status)) {
//     return res.status(400).json({
//       status: 0,
//       message: "Invalid status. Use APPROVED or REJECTED."
//     });
//   }

//   const kitchen = await prisma.kitchen.findUnique({
//     where: { kitchenId: Number(kitchenId) },
//     include: { kyc: true }
//   });

//   if (!kitchen) {
//     return res.status(404).json({
//       status: 0,
//       message: "Kitchen not found"
//     });
//   }

//   // ⭐ APPROVED FLOW
//   if (status === "APPROVED") {

//     if (!expireDate) {
//       return res.status(400).json({
//         status: 0,
//         message: "expireDate is required for APPROVED status"
//       });
//     }

//     const dbExpire = kitchen.kyc?.expireDate
//       ? kitchen.kyc.expireDate.toISOString().split("T")[0]
//       : null;

//     if (dbExpire !== expireDate) {
//       return res.status(400).json({
//         status: 0,
//         message: "expireDate does not match KYC record"
//       });
//     }

//     await prisma.kitchen.update({
//       where: { kitchenId: Number(kitchenId) },
//       data: {
//         status: "APPROVED",
//         isActive: 1,
//         rejectReason: null
//       }
//     });

//     // 🔔 PUSH NOTIFICATION
//     if (kitchen.deviceToken) {
//       await exports.sendNotificationToUser(
//         kitchen.kitchenId,
//         getKitchenStatusNotification("APPROVED"),
//         kitchen.deviceToken
//       );
//     }

//     return res.status(200).json({
//       status: 1,
//       message: "Kitchen approved successfully"
//     });
//   }

//   // ⭐ REJECTED FLOW
//   if (status === "REJECTED") {
//     await prisma.kitchen.update({
//       where: { kitchenId: Number(kitchenId) },
//       data: {
//         status: "REJECTED",
//         isActive: 0,
//         rejectReason: reason || null
//       }
//     });

//     // 🔔 PUSH NOTIFICATION
//     if (kitchen.deviceToken) {
//       await exports.sendNotificationToUser(
//         kitchen.kitchenId,
//         getKitchenStatusNotification("REJECTED", reason),
//         kitchen.deviceToken
//       );
//     }

//     return res.status(200).json({
//       status: 1,
//       message: "Kitchen rejected successfully"
//     });
//   }
// });

const getKitchenStatusNotification = (status, reason) => {
  if (status === "APPROVED") {
    return {
      title: "Kitchen Approved 🎉",
      body: "Your kitchen has been approved successfully. You can now start receiving orders.",
      orderId: "",
      status: "APPROVED"
    };
  }

  return {
    title: "Kitchen Rejected ❌",
    body: reason
      ? `Your kitchen was rejected. Reason: ${reason}`
      : "Your kitchen was rejected. Please contact support for more details.",
    orderId: "",
    status: "REJECTED"
  };
};


// ============================================================
// ⭐ API 1: Update Compliance Status (complianceStatus field)
// - APPROVED → only complianceStatus = APPROVED (status untouched)
// - REJECTED → complianceStatus = REJECTED + status = REJECTED (cascade)
// ============================================================
exports.updateComplianceStatus = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;
  const { status, expireDate, reason } = req.body;

  const validStatuses = ["APPROVED", "REJECTED"];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      status: 0,
      message: "Invalid status. Use APPROVED or REJECTED."
    });
  }

  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) },
    include: { kyc: true }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  // ******************************
  // ⭐ COMPLIANCE APPROVED
  // ******************************
  if (status === "APPROVED") {

    if (!expireDate) {
      return res.status(400).json({
        status: 0,
        message: "expireDate is required for APPROVED status"
      });
    }

    // Compare with DB expireDate
    const dbExpire = kitchen.kyc?.expireDate
      ? kitchen.kyc.expireDate.toISOString().split("T")[0]
      : null;

    if (dbExpire !== expireDate) {
      return res.status(400).json({
        status: 0,
        message: "expireDate does not match KYC record. Enter correct expireDate to approve."
      });
    }

    const previousComplianceStatus = kitchen.complianceStatus;

    // Approve complianceStatus only — status remains unchanged
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        complianceStatus: "APPROVED",
        rejectReason: null
      }
    });

    // 🔍 AUDIT LOG - Compliance Approval
    console.log('🔍 Admin object for audit:', req.admin);
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousComplianceStatus === 'REJECTED' ? 'COMPLIANCE_REAPPROVED' : 'COMPLIANCE_APPROVED',
      actionDescription: `Kitchen compliance status changed from ${previousComplianceStatus} to APPROVED`,
      oldData: previousComplianceStatus,
      newData: 'APPROVED',
      metadata: {
        expireDate,
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 💾 SAVE NOTIFICATION TO DATABASE
    await prisma.notification.create({
      data: {
        ownerId: kitchen.kitchenId,
        ownerType: "KITCHEN",
        title: "Compliance Approved 🎉",
        message: "Your kitchen compliance has been approved. Awaiting final status approval.",
        type: 1
      }
    });

    // 🔔 PUSH NOTIFICATION
    await handleFactory.sendNotificationToKitchen(
      kitchen.kitchenId,
      {
        title: "Compliance Approved 🎉",
        body: "Your kitchen compliance has been approved. Awaiting final status approval.",
        orderId: "",
        status: "APPROVED"
      }
    );

    return res.status(200).json({
      status: 1,
      message: "Kitchen compliance approved successfully"
    });
  }

  // ******************************
  // ⭐ COMPLIANCE REJECTED → cascade to status = REJECTED too
  // ******************************

  if (status === "REJECTED") {
    const previousComplianceStatus = kitchen.complianceStatus;
    const previousStatus = kitchen.status;

    // Reject both complianceStatus AND status
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        complianceStatus: "REJECTED",
        status: "REJECTED",
        isActive: 0,
        rejectReason: reason || null
      }
    });

    // 🔍 AUDIT LOG 1 - Compliance Rejected
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousComplianceStatus === 'PENDING' ? 'COMPLIANCE_REJECTED' : 'COMPLIANCE_REREJECTED',
      actionDescription: `Kitchen complianceStatus changed from ${previousComplianceStatus} to REJECTED`,
      oldData: previousComplianceStatus,
      newData: 'REJECTED',
      reason: reason || 'No reason provided',
      metadata: {
        isActive: 0,
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 🔍 AUDIT LOG 2 - Status Rejected (cascaded from compliance rejection)
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousStatus === 'PENDING' ? 'STATUS_REJECTED' : 'STATUS_REREJECTED',
      actionDescription: `Kitchen status changed from ${previousStatus} to REJECTED (cascaded from compliance rejection)`,
      oldData: previousStatus,
      newData: 'REJECTED',
      reason: reason || 'No reason provided',
      metadata: {
        isActive: 0,
        cascadedFrom: 'COMPLIANCE_REJECTED',
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 💾 SAVE NOTIFICATION TO DATABASE
    await prisma.notification.create({
      data: {
        ownerId: kitchen.kitchenId,
        ownerType: "KITCHEN",
        title: "Kitchen Rejected ❌",
        message: reason
          ? `Your kitchen was rejected. Reason: ${reason}`
          : "Your kitchen was rejected. Please contact support for more details.",
        type: 1
      }
    });

    // 🔔 PUSH NOTIFICATION
    await handleFactory.sendNotificationToKitchen(
      kitchen.kitchenId,
      getKitchenStatusNotification("REJECTED", reason)
    );

    // 📧 SEND REJECTION EMAIL
    if (kitchen.email && process.env.NODE_ENV === "production") {
      const { sendKitchenRejectionEmail } = require('../utils/emailService');
      const emailResult = await sendKitchenRejectionEmail(kitchen.email, kitchen.kitchenName, reason);
      if (emailResult.success) {
        console.log(`✅ Rejection email sent to ${kitchen.email}`);
      } else {
        console.error(`⚠️ Failed to send rejection email to ${kitchen.email}:`, emailResult.error);
      }
    }

    return res.status(200).json({
      status: 1,
      message: "Kitchen compliance rejected successfully (status also rejected)"
    });
  }
});


// ============================================================
// ⭐ API 2: Update Kitchen Status (status field)
// - APPROVED → requires complianceStatus = APPROVED first; only status = APPROVED
// - REJECTED → status = REJECTED + complianceStatus = REJECTED (cascade)
// ============================================================
exports.updateKitchenStatus = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;
  const { status, reason } = req.body;

  const validStatuses = ["APPROVED", "REJECTED"];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      status: 0,
      message: "Invalid status. Use APPROVED or REJECTED."
    });
  }

  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) },
    include: { kyc: true }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  // ******************************
  // ⭐ STATUS APPROVED
  // ******************************
  if (status === "APPROVED") {

    // Guard: complianceStatus must be APPROVED before status can be approved
    if (kitchen.complianceStatus !== "APPROVED") {
      return res.status(400).json({
        status: 0,
        message: `Cannot approve kitchen status. Compliance status is currently '${kitchen.complianceStatus}'. Please approve compliance first.`
      });
    }

    const previousStatus = kitchen.status;

    // Approve status only — complianceStatus remains unchanged
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        status: "APPROVED",
        isActive: 1,
        rejectReason: null
      }
    });

    // 🔍 AUDIT LOG - Status Approval
    console.log('🔍 Admin object for audit:', req.admin);
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousStatus === 'REJECTED' ? 'STATUS_REAPPROVED' : 'STATUS_APPROVED',
      actionDescription: `Kitchen status changed from ${previousStatus} to APPROVED`,
      oldData: previousStatus,
      newData: 'APPROVED',
      metadata: {
        isActive: 1,
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 💾 SAVE NOTIFICATION TO DATABASE
    await prisma.notification.create({
      data: {
        ownerId: kitchen.kitchenId,
        ownerType: "KITCHEN",
        title: "Kitchen Approved 🎉",
        message: "Your kitchen has been approved successfully. You can now start receiving orders.",
        type: 1
      }
    });

    // 🔔 PUSH NOTIFICATION
    await handleFactory.sendNotificationToKitchen(
      kitchen.kitchenId,
      getKitchenStatusNotification("APPROVED")
    );

    // 📧 SEND APPROVAL EMAIL
    if (kitchen.email && process.env.NODE_ENV === "production") {
      const { sendKitchenApprovalEmail } = require('../utils/emailService');
      const emailResult = await sendKitchenApprovalEmail(kitchen.email, kitchen.kitchenName);
      if (emailResult.success) {
        console.log(`✅ Approval email sent to ${kitchen.email}`);
      } else {
        console.error(`⚠️ Failed to send approval email to ${kitchen.email}:`, emailResult.error);
      }
    }
  
    // Automatically set payout schedule if stripeAccountId exists
    if (kitchen.stripeAccountId) {
      try {
        const { setWeeklyPayoutSchedule } = require('../utils/stripePayoutScheduler');
        await setWeeklyPayoutSchedule(kitchen.stripeAccountId);
        console.log(`✅ [AUTO] Set payout schedule for approved kitchen ${kitchenId}`);
      } catch (error) {
        console.error(`⚠️ [AUTO] Failed to set payout schedule for approved kitchen ${kitchenId}:`, error.message);
      }
    }

    return res.status(200).json({
      status: 1,
      message: "Kitchen approved successfully"
    });
  }

  // ******************************
  // ⭐ STATUS REJECTED → cascade to complianceStatus = REJECTED too
  // ******************************
  if (status === "REJECTED") {
    const previousStatus = kitchen.status;
    const previousComplianceStatus = kitchen.complianceStatus;

    // Reject both status AND complianceStatus
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        status: "REJECTED",
        complianceStatus: "REJECTED",
        isActive: 0,
        rejectReason: reason || null
      }
    });

    // 🔍 AUDIT LOG 1 - Status Rejected
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousStatus === 'PENDING' ? 'STATUS_REJECTED' : 'STATUS_REREJECTED',
      actionDescription: `Kitchen status changed from ${previousStatus} to REJECTED`,
      oldData: previousStatus,
      newData: 'REJECTED',
      reason: reason || 'No reason provided',
      metadata: {
        isActive: 0,
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 🔍 AUDIT LOG 2 - Compliance Rejected (cascaded from status rejection)
    await auditLogger.createAuditLog({
      kitchenId: Number(kitchenId),
      actorType: 'ADMIN',
      actorId: req.admin.adminId,
      actorName: req.admin.name || req.admin.emailId || 'Admin User',
      actorRole: req.admin.roleName || 'ADMIN',
      actionType: previousComplianceStatus === 'PENDING' ? 'COMPLIANCE_REJECTED' : 'COMPLIANCE_REREJECTED',
      actionDescription: `Kitchen complianceStatus changed from ${previousComplianceStatus} to REJECTED (cascaded from status rejection)`,
      oldData: previousComplianceStatus,
      newData: 'REJECTED',
      reason: reason || 'No reason provided',
      metadata: {
        isActive: 0,
        cascadedFrom: 'STATUS_REJECTED',
        adminRoleId: req.admin.roleId
      },
      ipAddress: auditLogger.getIpAddress(req),
      userAgent: auditLogger.getUserAgent(req)
    });

    // 💾 SAVE NOTIFICATION TO DATABASE
    await prisma.notification.create({
      data: {
        ownerId: kitchen.kitchenId,
        ownerType: "KITCHEN",
        title: "Kitchen Rejected ❌",
        message: reason
          ? `Your kitchen was rejected. Reason: ${reason}`
          : "Your kitchen was rejected. Please contact support for more details.",
        type: 1
      }
    });

    // 🔔 PUSH NOTIFICATION
    await handleFactory.sendNotificationToKitchen(
      kitchen.kitchenId,
      getKitchenStatusNotification("REJECTED", reason)
    );

    // 📧 SEND REJECTION EMAIL
    if (kitchen.email && process.env.NODE_ENV === "production") {
      const { sendKitchenRejectionEmail } = require('../utils/emailService');
      const emailResult = await sendKitchenRejectionEmail(kitchen.email, kitchen.kitchenName, reason);
      if (emailResult.success) {
        console.log(`✅ Rejection email sent to ${kitchen.email}`);
      } else {
        console.error(`⚠️ Failed to send rejection email to ${kitchen.email}:`, emailResult.error);
      }
    }

    return res.status(200).json({
      status: 1,
      message: "Kitchen rejected successfully (compliance status also rejected)"
    });
  }
});


// ✅ Get all config
exports.getConfig = catchAsync(async (req, res) => {
  try {
    console.log("Fetching all configs...");
    const config = await prisma.config.findMany();
    console.log("Configs found:", config);

    // Force no caching
    res.set({
      "Cache-Control": "no-cache, no-store, must-revalidate",
      Pragma: "no-cache",
      Expires: "0",
    });

    return res.json({
      status: 1,
      message: "Config fetched successfully",
      data: config,
      count: config.length,
    });
  } catch (error) {
    console.error("Error fetching configs:", error);
    return res.status(500).json({
      status: 0,
      message: "Error fetching configs",
      error: error.message,
    });
  }
});

exports.updateConfig = catchAsync(async (req, res) => {
  const { configId, configValue } = req.body;

  // Validate that configId is a number
  if (!configId || isNaN(parseInt(configId))) {
    return res.status(400).json({
      status: 0,
      message: "configId must be a valid number",
    });
  }

  try {
    const config = await prisma.config.update({
      where: { configId: parseInt(configId) },
      data: { configValue },
    });

    return res.json({
      status: 1,
      message: "Config updated successfully",
      data: config,
    });
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({
        status: 0,
        message: "Config not found",
      });
    }
    throw error;
  }
});

exports.getAllUserDetails = catchAsync(async (req, res) => {
  const USER_S3 = process.env.user_s3;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  const search = req.query.search?.toLowerCase() || "";
  const filter = req.query.filter; // ACTIVE, INACTIVE, DELETED, DELETING_SOON
  const isSeen = req.query.isSeen;
  // ⭐ Combined Search Filter (name, phone, email)
  const searchFilter = search
    ? {
      OR: [
        { name: { contains: search } },
        { phoneNumber: { contains: search } },
        { email: { contains: search } },
      ]
    }
    : {};

  // 📂 Status Filter
  let statusFilter = {};
  if (filter === "ACTIVE") {
    statusFilter = { status: "ACTIVE" };
  } else if (filter === "INACTIVE") {
    statusFilter = { status: "INACTIVE" };
  } else if (filter === "DELETED") {
    statusFilter = { status: "DELETED" };
  } else if (filter === "DELETING_SOON") {
    statusFilter = { status: "DELETING_SOON" };
  }

  const combinedWhere = {
    ...searchFilter,
    ...statusFilter
  };

  const totalUsers = await prisma.user.count({
    where: combinedWhere
  });

  const unseenCount = await prisma.userAccountRequest.count({
    where: { isSeen: false, status: "PENDING", requestType: "DELETE" }
  });

  // 📂 Deleting Soon Condition for priority sorting
  const deletingSoonCondition = { status: "DELETING_SOON" };

  // 📊 Get count of Deleting Soon users to handle priority pagination
  const dsCount = await prisma.user.count({
    where: { ...combinedWhere, ...deletingSoonCondition }
  });

  const includeConfig = {
    userAccountRequests: {
      orderBy: {
        requestedAt: "desc"
      },
      take: 1
    }
  };

  let users = [];

  if (skip < dsCount) {
    // 💡 Fetch from "Deleting Soon" bucket first
    const dsToFetch = Math.min(limit, dsCount - skip);
    const dsUsers = await prisma.user.findMany({
      where: { ...combinedWhere, ...deletingSoonCondition },
      include: includeConfig,
      orderBy: { userId: "desc" },
      skip,
      take: dsToFetch
    });
    users.push(...dsUsers);

    // 💡 Fill remaining limit from the "Normal" bucket
    if (users.length < limit) {
      const remainingNeeded = limit - users.length;
      const normalUsers = await prisma.user.findMany({
        where: { ...combinedWhere, NOT: deletingSoonCondition },
        include: includeConfig,
        orderBy: { userId: "desc" },
        skip: 0,
        take: remainingNeeded
      });
      users.push(...normalUsers);
    }
  } else {
    // 💡 Page starts beyond the Deleting Soon bucket
    const normalSkip = skip - dsCount;
    const normalUsers = await prisma.user.findMany({
      where: { ...combinedWhere, NOT: deletingSoonCondition },
      include: includeConfig,
      orderBy: { userId: "desc" },
      skip: normalSkip,
      take: limit
    });
    users.push(...normalUsers);
  }

  const formattedUsers = users.map(user => {
    const latestRequest = user.userAccountRequests[0];

    return {
      userId: user.userId,
      name: user.name,
      lastName: user.lastName || '',
      phoneNumber: user.phoneNumber,
      email: user.email,
      profilePicture: user.profilePicture
        ? (user.profilePicture.startsWith('http') ? user.profilePicture : `${USER_S3}${user.profilePicture}`)
        : null,
      deviceToken: user.deviceToken,
      isNotify: user.isNotify,
      status: user.status,
      // Status & Deletion Details
      isDeletingSoon: user.status === "DELETING_SOON",
      reasonType: latestRequest?.reasonType || null,
      reasonText: latestRequest?.reasonText || null,
      requestedAt: latestRequest?.requestedAt || null,
      scheduledDeletionAt: latestRequest?.scheduledDeletionAt || null,
      requestStatus: latestRequest?.status || null,
      isSeen: latestRequest?.isSeen || false
    };
  });

  // ⭐ Mark requests as seen in DB after generating the list
  if (isSeen === 'true' || isSeen === '1') {
    const requestIds = users
      .map(u => u.userAccountRequests[0]?.id)
      .filter(id => id !== undefined);

    if (requestIds.length > 0) {
      await prisma.userAccountRequest.updateMany({
        where: { id: { in: requestIds }, isSeen: false },
        data: { isSeen: true }
      });
    }
  }

  return res.status(200).json({
    status: 1,
    message: "User details fetched",
    unseenCount,
    users: formattedUsers,
    pagination: {
      currentPage: page,
      totalPages: Math.ceil(totalUsers / limit),
      totalUsers,
    }
  });
});


exports.adminGetAllOrders = catchAsync(async (req, res) => {
  const { status, userId, date, search } = req.query;

  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  // ⏳ Build base filters (AND)
  const baseFilters = {
    ...(status ? { status } : {}),
    ...(userId ? { userId: parseInt(userId) } : {}),
    ...(date ? {
      orderedAt: {
        gte: new Date(`${date}T00:00:00.000Z`),
        lte: new Date(`${date}T23:59:59.999Z`)
      }
    } : {})
  };

  // 🔍 Search filter (orderNumber OR user.name OR user.phoneNumber)
  let searchFilter = {};
  if (search) {
    // Strip "OD" prefix if present (case-insensitive)
    const cleanSearch = search.replace(/^od/i, '').trim();
    const searchInt = parseInt(cleanSearch);
    const isValidOrderNumber = !isNaN(searchInt) && searchInt >= -2147483648 && searchInt <= 2147483647;

    const orConditions = [
      { user: { name: { contains: search.toLowerCase(), mode: 'insensitive' } } },
      { user: { phoneNumber: { equals: search } } }  // Exact match for phone number
    ];

    // Only add orderNumber search if the number is within INT4 range
    if (isValidOrderNumber) {
      orConditions.unshift({ orderNumber: searchInt });
    }

    searchFilter = { OR: orConditions };
  }

  // 🧮 Total count for pagination
  const totalOrders = await prisma.order.count({
    where: {
      AND: [
        baseFilters,
        searchFilter
      ]
    }
  });

  // 📦 Paginated fetch
  const orders = await prisma.order.findMany({
    where: {
      AND: [
        baseFilters,
        searchFilter
      ]
    },
    skip,
    take: limit,
    orderBy: { orderedAt: "desc" },
    include: {
      user: {
        select: { userId: true, name: true, phoneNumber: true }
      },
      kitchen: {
        select: { kitchenId: true, kitchenName: true }
      }
    }
  });

  // Format orders with orderDisplayId
  const formattedOrders = orders.map(order => ({
    ...order,
    orderDisplayId: order.orderNumber ? "OD" + String(order.orderNumber) : null
  }));

  return res.status(200).json({
    status: 1,
    message: "Orders fetched successfully",
    orders: formattedOrders,
    pagination: {
      totalOrders,
      currentPage: page,
      totalPages: Math.ceil(totalOrders / limit),
    }

  });
});


exports.getOrderDetails = catchAsync(async (req, res) => {
  const { orderUid } = req.params;

  const MENU_IMG = process.env.menu_s3;
  const KITCHEN_IMG = process.env.kitchen_s3;

  const order = await prisma.order.findFirst({
    where: { orderUid },
    include: {
      kitchen: {
        include: {
          photos: true,
          address: true
        }
      },
      items: {
        include: {
          menu: true
        }
      }
    }
  });

  if (!order) {
    return res.status(404).json({
      status: 0,
      message: "Order not found"
    });
  }

  // 👇 Format Order ID like OD00000125
  const orderDisplayId = order.orderNumber ? "OD" + String(order.orderNumber) : null;

  // ⭐ Format items
  const formattedItems = order.items.map((oi) => ({
    menuItemId: oi.menuItemId,
    name: oi.menu?.name,
    quantity: oi.quantity,
    image: oi.menu?.image ? `${MENU_IMG}${oi.menu.image}` : null,
    startTime: oi.menu?.startTime,
    endTime: oi.menu?.endTime
  }));

  // take gst percentage from config 

  const config = await prisma.config.findMany({
    where: {
      configKey: { in: ["GST Percentage"] }
    }
  });
  const TAX_PERCENT = Number(config.find(c => c.configKey === "GST Percentage")?.configValue) || 5;

  return res.json({
    status: 1,
    message: "Order details fetched successfully",
    order: {
      orderDisplayId,
      ...order,
      taxPercent: TAX_PERCENT,
      items: formattedItems,
      kitchen: {
        kitchenId: order.kitchen.kitchenId,
        kitchenName: order.kitchen.kitchenName,
        kitchenImage: order.kitchen.photos?.kitchenProfilePhoto
          ? `${KITCHEN_IMG}${order.kitchen.photos.kitchenProfilePhoto}`
          : null,
        address: order.kitchen.address
      }
    }
  });
});

exports.getPagePermissions = catchAsync(async (req, res) => {
  try {

    const pages = await prisma.pages.findMany({
      select: { pageName: true }
    });

    const permissions = pages.map(page => ({
      PageName: page.pageName,
      read: 0,
      write: 0,
      edit: 0,
      delete: 0
    }));

    return res.status(200).json({ status: 1, permissions });
  } catch (error) {
    return res.status(500).json({ message: "Something went wrong" });
  }
});


exports.getCurrentPayouts = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || "";
    const status = req.query.status || "";

    // Get Service Fee Percentage from config (fetch once)
    const serviceFeeConfig = await prisma.config.findFirst({
      where: { configKey: "Service Fee Percentage" }
    });
    const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

    // 1️⃣ Fetch ALL kitchens matching search (we need to calculate amounts before filtering by status)
    const kitchens = await prisma.kitchen.findMany({
      include: { address: true },
      where: search ? {
        kitchenName: { contains: search, mode: 'insensitive' }
      } : {}
    });

    // 2️⃣ Get last payout date for each kitchen
    const lastPayouts = await prisma.kitchenPayout.groupBy({
      by: ["kitchenId"],
      _max: { periodEnd: true }
    });

    // 3️⃣ Build response with per-kitchen calculations
    const allResults = await Promise.all(kitchens.map(async (k) => {
      const lastPayoutRow = lastPayouts.find(p => p.kitchenId === k.kitchenId);

      // Determine the period start date
      const periodStart = lastPayoutRow?._max.periodEnd
        ? new Date(lastPayoutRow._max.periodEnd.getTime() + 86400000) // Add 1 day
        : k.createdAt || new Date(0); // Fallback to kitchen creation or epoch

      const periodEnd = new Date(); // Current date/time

      // 4️⃣ Sum orders ONLY in the unpaid period (excluding REJECTED orders)
      const orderTotals = await prisma.order.aggregate({
        where: {
          kitchenId: k.kitchenId,
          paymentStatus: "PAID",
          status: { not: "REJECTED" }, // ✅ Exclude rejected orders
          orderedAt: {
            gte: periodStart,
            lte: periodEnd
          }
        },
        _sum: {
          totalAmount: true,
          platformFee: true
        },
        _count: { orderId: true }
      });

      const totalOrderAmount = Number(orderTotals._sum.totalAmount || 0);
      const totalPlatformFees = Number(orderTotals._sum.platformFee || 0);
      const orderCount = Number(orderTotals._count.orderId || 0);

      // Calculate item total (excluding platform fees)
      const itemTotal = totalOrderAmount - totalPlatformFees;

      // Service fee is calculated on item total (product amount only)
      const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));

      // Amount to pay = total order amount - platform fees - service fee
      const amount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

      // Generate restaurant code like REST001, REST002, etc.
      const restaurantCode = "REST" + String(k.kitchenId).padStart(4, "0");

      return {
        kitchenId: k.kitchenId,
        restaurantCode,
        restaurantName: k.kitchenName,
        address: k.address,
        orders: orderCount,
        amount: amount > 0 ? amount : 0, // Don't show negative amounts
        status: amount > 0 ? "Pending" : "Paid",
        canPay: amount > 0,
        periodStart: periodStart.toISOString(),
        periodEnd: periodEnd.toISOString()
      };
    }));

    // 4️⃣ Filter by status if provided
    const filteredResults = status
      ? allResults.filter(item => item.status.toLowerCase() === status.toLowerCase())
      : allResults;

    // 5️⃣ Apply pagination to filtered results
    const totalFiltered = filteredResults.length;
    const skip = (page - 1) * limit;
    const paginatedResults = filteredResults.slice(skip, skip + limit);

    res.status(200).json({
      status: 1,
      message: "Payouts loaded successfully",
      data: paginatedResults,
      pagination: {
        totalKitchens: totalFiltered, // ✅ Correct total after filtering
        currentPage: page,
        totalPages: Math.ceil(totalFiltered / limit)
      }
    });
  } catch (error) {
    console.error("Get current payouts error:", error);
    res.status(500).json({ message: "Failed to load payouts" });
  }
};

// import Stripe from "stripe";
const Stripe = require("stripe");
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const { getNextInvoiceNumber, generatePayoutInvoice } = require("../utils/invoiceGenerator");

exports.payKitchen = async (req, res) => {
  try {
    const { kitchenId, from, to } = req.body;

    // 1️⃣ Fetch ALL paid orders in date range
    const orders = await prisma.order.findMany({
      where: {
        kitchenId,
        paymentStatus: "PAID", // Only include paid orders
        orderedAt: {
          gte: new Date(from),
          lte: new Date(to)
        }
      },
      select: {
        orderId: true,
        totalAmount: true,
        platformFee: true,
        status: true,
        orderedAt: true,
        items: {
          select: {
            quantity: true
          }
        }
      }
    });

    // 2️⃣ Calculate totals from ALL orders
    const totalOrderAmount = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
    const totalPlatformFees = orders.reduce((sum, o) => sum + Number(o.platformFee), 0);

    // Get Service Fee Percentage from config
    const serviceFeeConfig = await prisma.config.findFirst({
      where: { configKey: "Service Fee Percentage" }
    });
    const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

    // Calculate item total (excluding platform fees)
    const itemTotal = totalOrderAmount - totalPlatformFees;

    // Service fee is calculated on item total (product amount only)
    const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));

    // 3️⃣ Calculate actual payout amount (order total - platform fees - service fee)
    const payoutAmount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

    if (payoutAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: "No payable amount in selected range"
      });
    }

    // 4️⃣ Get kitchen with address and KYC (for ABN)
    const kitchen = await prisma.kitchen.findUnique({
      where: { kitchenId },
      include: {
        address: true,
        kyc: true  // Include KYC data for ABN
      }
    });

    // 🐛 DEBUG: Log kitchen KYC data
    console.log("\n========== KITCHEN KYC DEBUG ==========");
    console.log("Kitchen ID:", kitchenId);
    console.log("Kitchen Name:", kitchen?.kitchenName);
    console.log("KYC Object:", kitchen?.kyc);
    console.log("ABN Number:", kitchen?.kyc?.abnNumber);
    console.log("ACN:", kitchen?.kyc?.acn);
    console.log("=======================================\n");

    // Validate Stripe onboarding completion
    if (!kitchen) {
      return res.status(404).json({
        success: false,
        message: "Kitchen not found"
      });
    }

    if (!kitchen.stripeAccountId || !kitchen.stripeOnboardingCompleted) {
      return res.status(400).json({
        success: false,
        message: "Kitchen has not completed Stripe authentication. Please ask the kitchen owner to complete Stripe onboarding before processing payouts.",
        stripeStatus: {
          hasStripeAccount: !!kitchen.stripeAccountId,
          onboardingCompleted: kitchen.stripeOnboardingCompleted || false,
          connectedAt: kitchen.stripeConnectedAt || null
        }
      });
    }

    // 5️⃣ Stripe transfer (REAL MONEY) - excluding platform fees
    let transfer;
    const isTestMode = process.env.NODE_ENV !== 'production' || process.env.STRIPE_SECRET_KEY?.includes('test');

    if (isTestMode) {
      // 🧪 TEST MODE: Simulate transfer to avoid regional restrictions
      console.log(`⚠️ TEST MODE: Simulating Stripe transfer of $${payoutAmount} to ${kitchen.stripeAccountId}`);
      transfer = {
        id: `simulated_transfer_${Date.now()}`,
        amount: Math.round(payoutAmount * 100),
        currency: "usd",
        destination: kitchen.stripeAccountId,
        description: `Kitchen payout ${from} to ${to}`,
        created: Math.floor(Date.now() / 1000),
        object: 'transfer'
      };
    } else {
      // 💰 PRODUCTION: Real Stripe transfer
      transfer = await stripe.transfers.create({
        amount: Math.round(payoutAmount * 100),
        currency: "usd",
        destination: kitchen.stripeAccountId,
        description: `Kitchen payout ${from} to ${to}`
      });
    }

    // 6️⃣ Ledger DEBIT (settlement) - record the settlement
    await prisma.kitchenLedger.create({
      data: {
        kitchenId,
        type: "DEBIT",
        amount: -totalOrderAmount,
        description: `Payout settlement (${from} → ${to})`
      }
    });

    // 7️⃣ Save payout record with complete financial breakdown
    const payout = await prisma.kitchenPayout.create({
      data: {
        kitchenId,
        periodStart: new Date(from),
        periodEnd: new Date(to),
        totalOrderAmount,           // Total from all orders
        platformFeeAmount: totalPlatformFees, // Total platform fees deducted
        payoutAmount,               // Net amount paid to kitchen
        ordersCount: orders.length,
        stripeTransferId: transfer.id
      }
    });

    // 8️⃣ Generate invoice
    const invoiceNumber = await getNextInvoiceNumber();
    const restaurantCode = "REST" + String(kitchenId).padStart(4, "0");

    // 🐛 DEBUG: Log the totals being used for invoice
    console.log("\n========== INVOICE GENERATION DEBUG ==========");
    console.log("Total Order Amount:", totalOrderAmount);
    console.log("Platform Fees:", totalPlatformFees);
    console.log("Payout Amount:", payoutAmount);
    console.log("Number of Orders:", orders.length);
    console.log("Order IDs:", orders.map(o => o.orderId));
    console.log("==============================================\n");

    const invoiceData = {
      invoiceNumber,
      kitchen,
      restaurantCode,
      periodStart: new Date(from),
      periodEnd: new Date(to),
      totalCredits: totalOrderAmount,  // ✅ Use order totals
      platformFeesDeducted: totalPlatformFees,
      serviceFeeAmount: serviceFeeAmount,
      serviceFeePercent: serviceFeePercent,
      payoutAmount,
      orderCount: orders.length,
      orders: orders.map(o => ({
        orderId: o.orderId,
        orderDisplayId: "OD" + String(o.orderNumber),
        numberOfItems: o.items.reduce((sum, item) => sum + item.quantity, 0),
        totalAmount: Number(o.totalAmount),
        status: o.status,
        orderedAt: o.orderedAt
      })),
      stripeTransferId: transfer.id,
      createdAt: new Date()
    };


    const { pdfUrl } = await generatePayoutInvoice(invoiceData);

    // 9️⃣ Save invoice record
    const invoice = await prisma.payoutInvoice.create({
      data: {
        payoutId: payout.payoutId,
        invoiceNumber,
        pdfUrl
      }
    });

    res.json({
      success: true,
      payoutId: payout.payoutId,
      amountPaid: payoutAmount,
      totalOrderAmount,
      platformFeesDeducted: totalPlatformFees,
      invoice: {
        invoiceId: invoice.invoiceId,
        invoiceNumber: invoice.invoiceNumber,
        pdfUrl: invoice.pdfUrl
      }
    });
  } catch (error) {
    console.error("Pay kitchen error:", error);
    res.status(500).json({ message: "Payout failed", error: error.message });
  }
};

exports.getInvoices = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [invoices, totalInvoices] = await Promise.all([
      prisma.payoutInvoice.findMany({
        include: {
          payout: {
            include: { kitchen: true }
          }
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit
      }),
      prisma.payoutInvoice.count()
    ]);

    // Format the response with required fields
    const formattedInvoices = await Promise.all(invoices.map(async (invoice) => {
      const restaurantCode = "REST" + String(invoice.payout.kitchen.kitchenId).padStart(4, "0");

      // If ordersCount is not stored, calculate it from orders in the period
      let numberOfOrders = invoice.payout.ordersCount || 0;

      if (!numberOfOrders && invoice.payout.periodStart && invoice.payout.periodEnd) {
        numberOfOrders = await prisma.order.count({
          where: {
            kitchenId: invoice.payout.kitchen.kitchenId,
            paymentStatus: "PAID",
            orderedAt: {
              gte: invoice.payout.periodStart,
              lte: invoice.payout.periodEnd
            }
          }
        });
      }

      return {
        invoiceId: invoice.invoiceId,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.createdAt,
        restaurantName: invoice.payout.kitchen.kitchenName,
        restaurantId: Number(invoice.payout.kitchen.kitchenId),
        restaurantCode: restaurantCode,
        kitchenId: invoice.payout.kitchen.kitchenId,
        numberOfOrders: numberOfOrders,
        invoicedAmount: Number(invoice.payout.payoutAmount),
        periodStart: invoice.payout.periodStart,
        periodEnd: invoice.payout.periodEnd,
        invoice: invoice.pdfUrl,
        stripeTransferId: invoice.payout.stripeTransferId
      };
    }));

    res.json({
      status: 1,
      message: "Invoices fetched successfully",
      data: formattedInvoices,
      pagination: {
        totalInvoices,
        currentPage: page,
        totalPages: Math.ceil(totalInvoices / limit)
      }
    });
  } catch (error) {
    console.error("Get invoices error:", error);
    res.status(500).json({
      status: 0,
      message: "Failed to fetch invoices",
      error: error.message
    });
  }
};


exports.adminGetSupportChats = catchAsync(async (req, res) => {
  const USER_S3 = process.env.user_s3;
  const KITCHEN_S3 = process.env.kitchen_s3;

  const rooms = await prisma.chatRoom.findMany({
    orderBy: { updatedAt: "desc" }
  });

  // 🔹 Separate chats
  const userChats = [];
  const kitchenChats = [];

  // 🔹 Fetch user and kitchen data separately
  for (const room of rooms) {
    // 🔹 Fetch last message for this room
    const lastMessage = await prisma.chatMessage.findFirst({
      where: { roomId: room.roomId },
      orderBy: { createdAt: "desc" },
      select: {
        message: true,
        createdAt: true
      }
    });

    // 🔹 Count unread messages (messages not from ADMIN and not read)
    const unreadCount = await prisma.chatMessage.count({
      where: {
        roomId: room.roomId,
        isRead: 0,
        senderRole: { not: "ADMIN" }
      }
    });

    if (room.userId) {
      const user = await prisma.user.findUnique({
        where: { userId: room.userId },
        select: {
          userId: true,
          name: true,
          phoneNumber: true,
          profilePicture: true,
          email: true
        }
      });

      userChats.push({
        roomId: room.roomId,
        status: room.status,
        lastMessage: lastMessage?.message || null,
        lastMessageAt: lastMessage?.createdAt || null,
        unreadCount,
        user: {
          userId: user?.userId,
          name: user?.name,
          phoneNumber: user?.phoneNumber,
          profilePicture: user?.profilePicture ? (user.profilePicture.startsWith('http') ? user.profilePicture : `${USER_S3}${user.profilePicture}`) : null,
          email: user?.email
        }
      });
    }

    if (room.kitchenId) {
      const kitchen = await prisma.kitchen.findUnique({
        where: { kitchenId: room.kitchenId },
        select: {
          kitchenId: true,
          kitchenName: true,
          email: true,
          photos: {
            select: {
              kitchenProfilePhoto: true
            }
          }
        }
      });

      kitchenChats.push({
        roomId: room.roomId,
        status: room.status,
        lastMessage: lastMessage?.message || null,
        lastMessageAt: lastMessage?.createdAt || null,
        unreadCount,
        kitchen: {
          kitchenId: kitchen?.kitchenId,
          kitchenName: kitchen?.kitchenName,
          kitchenProfilePhoto: kitchen?.photos?.kitchenProfilePhoto
            ? `${KITCHEN_S3}${kitchen.photos.kitchenProfilePhoto}`
            : null,
          email: kitchen?.email
        }
      });
    }
  }

  // Sort both arrays by lastMessageAt (most recent first)
  userChats.sort((a, b) => {
    if (!a.lastMessageAt) return 1;
    if (!b.lastMessageAt) return -1;
    return new Date(b.lastMessageAt) - new Date(a.lastMessageAt);
  });

  kitchenChats.sort((a, b) => {
    if (!a.lastMessageAt) return 1;
    if (!b.lastMessageAt) return -1;
    return new Date(b.lastMessageAt) - new Date(a.lastMessageAt);
  });

  return res.json({
    status: 1,
    userChats,
    kitchenChats
  });
});

exports.getChatMessages = catchAsync(async (req, res) => {
  const { chatRoomId } = req.params;

  const messages = await prisma.chatMessage.findMany({
    where: { roomId: Number(chatRoomId) },
    orderBy: { createdAt: "asc" },
    select: {
      messageId: true,
      senderRole: true,
      senderId: true,
      message: true,
      image: true,
      createdAt: true
    }
  });

  // 🔹 Mark all unread messages from USER/KITCHEN as read
  await prisma.chatMessage.updateMany({
    where: {
      roomId: Number(chatRoomId),
      isRead: 0,
      senderRole: { not: "ADMIN" }
    },
    data: {
      isRead: 1
    }
  });

  return res.json({
    status: 1,
    messages
  });
});


exports.sendAdminSupportMessage = catchAsync(async (req, res) => {
  const io = getIO(); // ✅ FIX
  const { adminId } = req;
  const { roomId, message, image } = req.body;

  if (!roomId || (!message && !image)) {
    return res.status(400).json({
      status: 0,
      message: "roomId and message/image required"
    });
  }

  const room = await prisma.chatRoom.findUnique({
    where: { roomId: Number(roomId) }
  });

  if (!room || room.status !== "OPEN") {
    return res.status(400).json({
      status: 0,
      message: "Chat room not available"
    });
  }

  // 💾 Save admin message
  const savedMessage = await prisma.chatMessage.create({
    data: {
      roomId,
      senderRole: "ADMIN",
      adminId,
      message: message || null,
      image: image || null
    }
  });

  const response = {
    messageId: savedMessage.messageId,
    roomId,
    senderRole: "ADMIN",
    message: savedMessage.message,
    image: savedMessage.image,
    createdAt: savedMessage.createdAt
  };

  // 📡 Send to USER / KITCHEN
  if (room.userId) {
    io.to(`user_${room.userId}`).emit("support-message", response);
  }
  if (room.kitchenId) {
    io.to(`kitchen_${room.kitchenId}`).emit("support-message", response);
  }

  return res.json({
    status: 1,
    message: "Message sent",
    data: response
  });
});


/**
 * Close a support chat room
 * @route PUT /api/admin/closeSupportChat/:roomId
 */
exports.closeSupportChat = catchAsync(async (req, res) => {
  const { roomId } = req.params;

  if (!roomId) {
    return res.status(400).json({
      status: 0,
      message: "roomId is required"
    });
  }

  // Check if room exists
  const room = await prisma.chatRoom.findUnique({
    where: { roomId: Number(roomId) }
  });

  if (!room) {
    return res.status(404).json({
      status: 0,
      message: "Chat room not found"
    });
  }

  // Update room status to CLOSED
  const updatedRoom = await prisma.chatRoom.update({
    where: { roomId: Number(roomId) },
    data: {
      status: "CLOSED",
      updatedAt: new Date()
    }
  });

  // // Optionally, notify the user/kitchen via socket that the chat is closed
  // const io = getIO();
  // if (room.userId) {
  //   io.to(`user_${room.userId}`).emit("chat-closed", {
  //     roomId: updatedRoom.roomId,
  //     message: "This support chat has been closed by admin"
  //   });
  // }
  // if (room.kitchenId) {
  //   io.to(`kitchen_${room.kitchenId}`).emit("chat-closed", {
  //     roomId: updatedRoom.roomId,
  //     message: "This support chat has been closed by admin"
  //   });
  // }

  return res.json({
    status: 1,
    message: "Chat room closed successfully",
    data: {
      roomId: updatedRoom.roomId,
      status: updatedRoom.status,
      updatedAt: updatedRoom.updatedAt
    }
  });
});


// 📦 Get all orders by kitchenId
exports.getOrdersByKitchenId = async (req, res) => {
  try {
    const { kitchenId } = req.params;
    const { status, date, search } = req.query;

    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const MENU_IMG = process.env.menu_s3;
    const USER_S3 = process.env.user_s3;

    // Build filters
    const baseFilters = {
      kitchenId: Number(kitchenId),
      status: { not: "REJECTED" }, // ✅ Exclude rejected orders
      ...(status ? { status } : {}),
      ...(date ? {
        orderedAt: {
          gte: new Date(`${date}T00:00:00.000Z`),
          lte: new Date(`${date}T23:59:59.999Z`)
        }
      } : {})
    };

    // Search filter (orderId OR user name OR phone)
    let searchFilter = {};
    if (search) {
      searchFilter = {
        OR: [
          { orderId: parseInt(search) || 0 },
          { user: { name: { contains: search.toLowerCase() } } },
          { user: { phoneNumber: { contains: search } } }
        ]
      };
    }

    // Total count
    const totalOrders = await prisma.order.count({
      where: {
        AND: [baseFilters, searchFilter]
      }
    });

    // Fetch orders
    const orders = await prisma.order.findMany({
      where: {
        AND: [baseFilters, searchFilter]
      },
      skip,
      take: limit,
      orderBy: { orderedAt: "desc" },
      include: {
        user: {
          select: {
            userId: true,
            name: true,
            phoneNumber: true,
            profilePicture: true
          }
        },
        items: {
          include: {
            menu: {
              select: {
                id: true,
                name: true,
                image: true,
                price: true
              }
            }
          }
        }
      }
    });

    // Format response
    const formattedOrders = orders.map(order => {
      const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);
      const amountExcludingPlatformFee = order.totalAmount - order.platformFee;

      return {
        orderId: order.orderId,
        orderDisplayId: order.orderNumber ? "OD" + String(order.orderNumber) : null,
        numberOfItems: itemCount,
        totalAmount: amountExcludingPlatformFee,
        status: order.status,
        orderedAt: order.orderedAt
      };
    });

    return res.json({
      status: 1,
      message: "Orders fetched successfully",
      orders: formattedOrders,
      pagination: {
        totalOrders,
        currentPage: page,
        totalPages: Math.ceil(totalOrders / limit)
      }
    });
  } catch (error) {
    console.error("Get orders by kitchen error:", error);
    return res.status(500).json({
      status: 0,
      message: "Failed to fetch orders"
    });
  }
};

// 🔔 Admin Broadcast Notification
exports.sendAdminNotification = catchAsync(async (req, res) => {
  const { title, message, type } = req.body;

  if (!title || !message || !type) {
    return res.status(400).json({
      status: 0,
      message: "title, message and type are required"
    });
  }

  if (!["USER", "KITCHEN"].includes(type)) {
    return res.status(400).json({
      status: 0,
      message: "type must be USER or KITCHEN"
    });
  }

  let recipients = [];

  if (type === "KITCHEN") {
    recipients = await prisma.kitchen.findMany({
      where: {
        isActive: 1,
        status: "APPROVED"
      },
      select: {
        kitchenId: true,
        deviceToken: true,
        deviceTokens: true
      }
    });
  } else {
    recipients = await prisma.user.findMany({
      where: {
        isActive: 1
      },
      select: {
        userId: true,
        deviceToken: true
      }
    });
  }

  // ✅ Always save ONE admin notification
  const adminNotification = await prisma.notification.create({
    data: {
      ownerId: 0,
      ownerType: type,
      title,
      message,
      type: 2,
      isRead: false,
      isAdminNotification: true
    }
  });

  // ✅ Extract valid device tokens (handling multiple tokens for kitchen)
  const deviceTokens = [];
  recipients.forEach(r => {
    if (type === "KITCHEN") {
      const tokens = new Set();
      if (r.deviceToken) tokens.add(r.deviceToken);
      if (Array.isArray(r.deviceTokens)) {
        r.deviceTokens.forEach(t => {
          if (t && typeof t === 'string') tokens.add(t);
        });
      }
      tokens.forEach(token => {
        deviceTokens.push({ id: r.kitchenId, token });
      });
    } else if (r.deviceToken) {
      deviceTokens.push({ id: r.userId, token: r.deviceToken });
    }
  });

  console.log(`📊 Admin Notification Summary:`);
  console.log(`   Type: ${type}`);
  console.log(`   Total Recipients: ${recipients.length}`);
  console.log(`   Valid Tokens: ${deviceTokens.length}`);

  // ✅ Send push ONLY if tokens exist
  let successCount = 0;
  let failureCount = 0;
  const invalidTokenIds = []; // Track IDs with invalid tokens

  if (deviceTokens.length > 0) {
    // Use Promise.allSettled to handle all notifications without failing on errors
    const results = await Promise.allSettled(
      deviceTokens.map(({ id, token }) =>
        handleFactory.sendNotificationToUser(id, {
          title,
          body: message,
          orderId: "",
          status: ""
        }, token)
      )
    );

    // Count successes and failures, track invalid tokens
    results.forEach((result, index) => {
      const { id } = deviceTokens[index];

      if (result.status === 'fulfilled' && result.value?.success) {
        successCount++;
      } else {
        failureCount++;

        // Check if it's an invalid/expired token error
        const errorMessage = result.reason?.message || result.value?.error || '';
        const isInvalidToken =
          errorMessage.includes('Requested entity was not found') ||
          errorMessage.includes('Invalid or expired token') ||
          errorMessage.includes('registration-token-not-registered') ||
          errorMessage.includes('invalid-registration-token');

        if (isInvalidToken) {
          invalidTokenIds.push(id);
          console.log(`🗑️  Marking token for cleanup - ${type} ${id}`);
        } else {
          console.log(`❌ Failed to send to ${type} ${id}: ${errorMessage}`);
        }
      }
    });

    // ✅ Clean up invalid tokens from database
    if (invalidTokenIds.length > 0) {
      console.log(`🧹 Cleaning up ${invalidTokenIds.length} invalid device tokens...`);

      try {
        if (type === "KITCHEN") {
          await prisma.kitchen.updateMany({
            where: {
              kitchenId: { in: invalidTokenIds }
            },
            data: {
              deviceToken: null
            }
          });
        } else {
          await prisma.user.updateMany({
            where: {
              userId: { in: invalidTokenIds }
            },
            data: {
              deviceToken: null
            }
          });
        }
        console.log(`✅ Successfully cleared ${invalidTokenIds.length} invalid tokens from database`);
      } catch (cleanupError) {
        console.error(`⚠️  Failed to clean up invalid tokens:`, cleanupError.message);
      }
    }

    console.log(`📊 Notification Results: ${successCount} sent, ${failureCount} failed out of ${deviceTokens.length} total`);
  } else {
    console.log(`⚠️ No valid device tokens found for ${type}`);
  }

  return res.status(200).json({
    status: 1,
    message: `Admin notification sent successfully`,
    stats: {
      totalRecipients: recipients.length,
      validTokens: deviceTokens.length,
      sent: successCount,
      failed: failureCount,
      invalidTokensCleared: invalidTokenIds.length
    }
  });
});

exports.getAdminNotifications = catchAsync(async (req, res) => {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const [notifications, totalCount] = await Promise.all([
    prisma.notification.findMany({
      where: {
        isAdminNotification: true,
        ownerId: 0
      },
      orderBy: {
        createdAt: "desc"
      },
      skip,
      take: limit,
      select: {
        id: true,
        title: true,
        message: true,
        ownerType: true, // USER or KITCHEN
        type: true,
        createdAt: true
      }
    }),
    prisma.notification.count({
      where: {
        isAdminNotification: true,
        ownerId: 0
      }
    })
  ]);

  return res.status(200).json({
    status: 1,
    message: "Admin notifications fetched successfully",
    data: notifications,
    pagination: {
      page,
      limit,
      total: totalCount,
      totalPages: Math.ceil(totalCount / limit)
    }
  });
});

exports.getAdminAlerts = catchAsync(async (req, res) => {
  const page = Number(req.query.page) || 1;
  const limit = Number(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  const { isViewed, alertType } = req.query;

  // Build where clause
  const where = {};
  if (isViewed !== undefined) {
    where.isViewed = isViewed === 'true' || isViewed === '1';
  }
  if (alertType) {
    where.alertType = alertType;
  }

  const [alerts, totalCount, unviewedCount] = await Promise.all([
    prisma.adminAlert.findMany({
      where,
      orderBy: {
        createdAt: "desc"
      },
      skip,
      take: limit
    }),
    prisma.adminAlert.count({ where }),
    prisma.adminAlert.count({ where: { isViewed: false } })
  ]);

  // Fetch related kitchen and user data
  const KYC_IMG = process.env.kyc_s3 || "";

  const enrichedAlerts = await Promise.all(
    alerts.map(async (alert) => {
      const enriched = { ...alert };

      // Append S3 URL to certificateImage if it exists in metadata
      if (enriched.metadata && typeof enriched.metadata === 'object') {
        if (enriched.metadata.certificateImage) {
          enriched.metadata.certificateImage = `${KYC_IMG}${enriched.metadata.certificateImage}`;
        }
      }

      if (alert.kitchenId) {
        const kitchen = await prisma.kitchen.findUnique({
          where: { kitchenId: alert.kitchenId },
          select: { kitchenId: true, kitchenName: true }
        });
        enriched.kitchen = kitchen;
      }

      if (alert.userId) {
        const user = await prisma.user.findUnique({
          where: { userId: alert.userId },
          select: { userId: true, name: true }
        });
        enriched.user = user;
      }

      return enriched;
    })
  );

  return res.status(200).json({
    status: 1,
    message: "Admin alerts fetched successfully",
    data: enrichedAlerts,
    pagination: {
      page,
      limit,
      total: totalCount,
      totalPages: Math.ceil(totalCount / limit)
    },
    unviewedCount
  });
});

/**
 * Mark alert as viewed
 */
exports.markAlertAsViewed = catchAsync(async (req, res) => {
  const { alertId } = req.params;
  const { adminId } = req.admin; // From auth middleware

  const alert = await prisma.adminAlert.findUnique({
    where: { id: Number(alertId) }
  });

  if (!alert) {
    return res.status(404).json({
      status: 0,
      message: "Alert not found"
    });
  }

  if (alert.isViewed) {
    return res.status(200).json({
      status: 1,
      message: "Alert already marked as viewed"
    });
  }

  await prisma.adminAlert.update({
    where: { id: Number(alertId) },
    data: {
      isViewed: true,
      viewedAt: new Date(),
      viewedBy: adminId
    }
  });

  return res.status(200).json({
    status: 1,
    message: "Alert marked as viewed successfully"
  });
});

/**
 * Generate monthly invoices for all kitchens
 * This function is called by the cron job or manually
 * Saves to MonthlyInvoice table (separate from payouts)
 */
async function generateMonthlyInvoicesForAllKitchens(month, year) {
  try {
    // Calculate date range for the specified month
    const targetDate = new Date(year, month - 1, 1); // month is 1-indexed
    const periodStart = new Date(targetDate.getFullYear(), targetDate.getMonth(), 1);
    const periodEnd = new Date(targetDate.getFullYear(), targetDate.getMonth() + 1, 0, 23, 59, 59, 999);

    console.log(`\n========== MONTHLY INVOICE GENERATION ==========`);
    console.log(`Period: ${periodStart.toISOString()} to ${periodEnd.toISOString()}`);
    console.log(`Month: ${month}, Year: ${year}`);
    console.log(`================================================\n`);

    // Fetch all active kitchens with Stripe onboarding completed
    const kitchens = await prisma.kitchen.findMany({
      where: {
        isActive: 1,
        stripeOnboardingCompleted: true,
        stripeAccountId: { not: null }
      },
      include: {
        address: true,
        kyc: true  // ✅ Include KYC data for ABN in invoices
      }
    });

    console.log(`Found ${kitchens.length} eligible kitchens for invoice generation`);

    const results = {
      success: [],
      skipped: [],
      failed: [],
      totalProcessed: 0
    };

    // Process each kitchen
    for (const kitchen of kitchens) {
      try {
        results.totalProcessed++;

        // Fetch orders for this kitchen in the specified month
        const orders = await prisma.order.findMany({
          where: {
            kitchenId: kitchen.kitchenId,
            paymentStatus: "PAID", // Only include paid orders
            orderedAt: {
              gte: periodStart,
              lte: periodEnd
            }
          },
          select: {
            orderId: true,
            totalAmount: true,
            platformFee: true,
            orderNumber: true,
            status: true,
            orderedAt: true,
            items: {
              select: {
                quantity: true
              }
            }
          }
        });

        // Skip if no orders
        if (orders.length === 0) {
          console.log(`⏭️  Skipping kitchen ${kitchen.kitchenId} (${kitchen.kitchenName}) - No orders in period`);
          results.skipped.push({
            kitchenId: kitchen.kitchenId,
            kitchenName: kitchen.kitchenName,
            reason: "No orders in period"
          });
          continue;
        }

        // Get Service Fee Percentage from config (separate from Platform Fee)
        const serviceFeeConfig = await prisma.config.findFirst({
          where: { configKey: "Service Fee Percentage" }
        });
        const serviceFeePercent = Number(serviceFeeConfig?.configValue) || 15;

        // Calculate totals
        const totalOrderAmount = orders.reduce((sum, o) => sum + Number(o.totalAmount), 0);
        const totalPlatformFees = orders.reduce((sum, o) => sum + Number(o.platformFee), 0);

        // Calculate item total (excluding platform fees)
        const itemTotal = totalOrderAmount - totalPlatformFees;

        // Service fee is calculated on item total (product amount only)
        const serviceFeeAmount = Number(((itemTotal * serviceFeePercent) / 100).toFixed(2));

        // Net amount = Total - Platform Fee - Service Fee
        const netAmount = totalOrderAmount - totalPlatformFees - serviceFeeAmount;

        // Skip if net amount is 0 or negative
        if (netAmount <= 0) {
          console.log(`⏭️  Skipping kitchen ${kitchen.kitchenId} (${kitchen.kitchenName}) - Net amount: $${netAmount}`);
          results.skipped.push({
            kitchenId: kitchen.kitchenId,
            kitchenName: kitchen.kitchenName,
            reason: `Net amount: $${netAmount.toFixed(2)}`
          });
          continue;
        }

        console.log(`📊 Processing kitchen ${kitchen.kitchenId} (${kitchen.kitchenName})`);
        console.log(`   Orders: ${orders.length}, Total: $${totalOrderAmount.toFixed(2)}`);
        console.log(`   Item Total: $${itemTotal.toFixed(2)}`);
        console.log(`   Platform Fee (from user): $${totalPlatformFees.toFixed(2)}`);
        console.log(`   Service Fee (${serviceFeePercent}% of items): $${serviceFeeAmount.toFixed(2)}`);
        console.log(`   Net Payout: $${netAmount.toFixed(2)}`);

        // Check if invoice already exists for this period
        const existingInvoice = await prisma.monthlyInvoice.findUnique({
          where: {
            kitchenId_month_year: {
              kitchenId: kitchen.kitchenId,
              month: month,
              year: year
            }
          }
        });

        if (existingInvoice) {
          console.log(`⚠️  Invoice already exists for kitchen ${kitchen.kitchenId} for ${month}/${year}`);
          results.skipped.push({
            kitchenId: kitchen.kitchenId,
            kitchenName: kitchen.kitchenName,
            reason: "Invoice already exists for this period"
          });
          continue;
        }

        // Generate invoice number
        const invoiceNumber = await getNextInvoiceNumber();
        const restaurantCode = "REST" + String(kitchen.kitchenId).padStart(4, "0");

        // Prepare invoice data for PDF generation
        const invoiceData = {
          invoiceNumber,
          kitchen,
          restaurantCode,
          periodStart: periodStart,
          periodEnd: periodEnd,
          totalCredits: totalOrderAmount,
          platformFeesDeducted: totalPlatformFees,
          serviceFeeAmount: serviceFeeAmount,
          serviceFeePercent: serviceFeePercent,
          payoutAmount: netAmount,
          orderCount: orders.length,
          orders: orders.map(o => ({
            orderId: o.orderId,
            orderDisplayId: "OD" + String(o.orderNumber),
            numberOfItems: o.items.reduce((sum, item) => sum + item.quantity, 0),
            totalAmount: Number(o.totalAmount),
            status: o.status,
            orderedAt: o.orderedAt
          })),
          stripeTransferId: `monthly_invoice_${kitchen.kitchenId}_${year}${String(month).padStart(2, '0')}`,
          isMonthly: true, // ⭐ Flag as monthly invoice
          createdAt: new Date()
        };

        // Generate PDF invoice
        const { pdfUrl } = await generatePayoutInvoice(invoiceData);

        // Save to MonthlyInvoice table
        await prisma.monthlyInvoice.create({
          data: {
            kitchenId: kitchen.kitchenId,
            invoiceNumber,
            month,
            year,
            periodStart,
            periodEnd,
            totalOrderAmount,
            platformFeeAmount: totalPlatformFees,
            netAmount,
            ordersCount: orders.length,
            pdfUrl
          }
        });

        console.log(`✅ Monthly invoice generated for kitchen ${kitchen.kitchenId}: ${invoiceNumber}`);

        results.success.push({
          kitchenId: kitchen.kitchenId,
          kitchenName: kitchen.kitchenName,
          invoiceNumber,
          netAmount,
          ordersCount: orders.length,
          pdfUrl
        });

      } catch (kitchenError) {
        console.error(`❌ Error processing kitchen ${kitchen.kitchenId}:`, kitchenError);
        results.failed.push({
          kitchenId: kitchen.kitchenId,
          kitchenName: kitchen.kitchenName,
          error: kitchenError.message
        });
      }
    }

    console.log(`\n========== INVOICE GENERATION SUMMARY ==========`);
    console.log(`Total Processed: ${results.totalProcessed}`);
    console.log(`Successful: ${results.success.length}`);
    console.log(`Skipped: ${results.skipped.length}`);
    console.log(`Failed: ${results.failed.length}`);
    console.log(`================================================\n`);

    return {
      success: true,
      summary: {
        totalProcessed: results.totalProcessed,
        successCount: results.success.length,
        skippedCount: results.skipped.length,
        failedCount: results.failed.length,
        period: {
          month,
          year,
          start: periodStart.toISOString(),
          end: periodEnd.toISOString()
        }
      },
      details: results
    };

  } catch (error) {
    console.error("❌ Monthly invoice generation failed:", error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Manual trigger endpoint for generating monthly invoices
 */
exports.manualGenerateMonthlyInvoices = catchAsync(async (req, res) => {
  // Get month and year from query params, default to previous month
  const now = new Date();
  const previousMonthDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const defaultMonth = previousMonthDate.getMonth() + 1; // Convert to 1-indexed (1-12)
  const defaultYear = previousMonthDate.getFullYear();

  const month = parseInt(req.query.month) || defaultMonth;
  const year = parseInt(req.query.year) || defaultYear;

  // Validate month and year
  if (month < 1 || month > 12) {
    return res.status(400).json({
      status: 0,
      message: "Invalid month. Must be between 1 and 12."
    });
  }

  if (year < 2020 || year > now.getFullYear()) {
    return res.status(400).json({
      status: 0,
      message: `Invalid year. Must be between 2020 and ${now.getFullYear()}.`
    });
  }

  console.log(`\n🔧 Manual invoice generation triggered for ${month}/${year}`);

  const result = await generateMonthlyInvoicesForAllKitchens(month, year);

  if (result.success) {
    return res.status(200).json({
      status: 1,
      message: "Monthly invoices generated successfully",
      ...result
    });
  } else {
    return res.status(500).json({
      status: 0,
      message: "Failed to generate monthly invoices",
      error: result.error
    });
  }
});

/**
 * Get all monthly invoices with filtering
 */
exports.getMonthlyInvoices = catchAsync(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  const { month, year, kitchenId } = req.query;

  // Build filter
  const where = {};
  if (month) where.month = parseInt(month);
  if (year) where.year = parseInt(year);
  if (kitchenId) where.kitchenId = parseInt(kitchenId);

  const [invoices, totalInvoices] = await Promise.all([
    prisma.monthlyInvoice.findMany({
      where,
      include: {
        kitchen: {
          select: {
            kitchenId: true,
            kitchenName: true,
            email: true
          }
        }
      },
      orderBy: { createdAt: "desc" },
      skip,
      take: limit
    }),
    prisma.monthlyInvoice.count({ where })
  ]);

  // Format the response
  const formattedInvoices = invoices.map((invoice) => {
    const restaurantCode = "REST" + String(invoice.kitchen.kitchenId).padStart(4, "0");

    return {
      invoiceId: invoice.invoiceId,
      invoiceNumber: invoice.invoiceNumber,
      month: invoice.month,
      year: invoice.year,
      periodStart: invoice.periodStart,
      periodEnd: invoice.periodEnd,
      restaurantCode,
      restaurantName: invoice.kitchen.kitchenName,
      kitchenId: invoice.kitchen.kitchenId,
      ordersCount: invoice.ordersCount,
      totalOrderAmount: Number(invoice.totalOrderAmount),
      platformFeeAmount: Number(invoice.platformFeeAmount),
      netAmount: Number(invoice.netAmount),
      pdfUrl: invoice.pdfUrl,
      createdAt: invoice.createdAt
    };
  });

  res.json({
    status: 1,
    message: "Monthly invoices fetched successfully",
    data: formattedInvoices,
    pagination: {
      totalInvoices,
      currentPage: page,
      totalPages: Math.ceil(totalInvoices / limit)
    }
  });
});

/**
 * Get monthly invoice by ID
 */
exports.getMonthlyInvoiceById = catchAsync(async (req, res) => {
  const { invoiceId } = req.params;

  const invoice = await prisma.monthlyInvoice.findUnique({
    where: { invoiceId: Number(invoiceId) },
    include: {
      kitchen: {
        include: {
          address: true
        }
      }
    }
  });

  if (!invoice) {
    return res.status(404).json({
      status: 0,
      message: "Invoice not found"
    });
  }

  const restaurantCode = "REST" + String(invoice.kitchen.kitchenId).padStart(4, "0");

  res.json({
    status: 1,
    message: "Invoice details fetched successfully",
    data: {
      invoiceId: invoice.invoiceId,
      invoiceNumber: invoice.invoiceNumber,
      month: invoice.month,
      year: invoice.year,
      periodStart: invoice.periodStart,
      periodEnd: invoice.periodEnd,
      restaurantCode,
      kitchen: {
        kitchenId: invoice.kitchen.kitchenId,
        kitchenName: invoice.kitchen.kitchenName,
        email: invoice.kitchen.email,
        address: invoice.kitchen.address
      },
      ordersCount: invoice.ordersCount,
      totalOrderAmount: Number(invoice.totalOrderAmount),
      platformFeeAmount: Number(invoice.platformFeeAmount),
      netAmount: Number(invoice.netAmount),
      pdfUrl: invoice.pdfUrl,
      createdAt: invoice.createdAt
    }
  });
});

// Export the function for use in cron jobs
exports.generateMonthlyInvoicesForAllKitchens = generateMonthlyInvoicesForAllKitchens;

// ========================================
// 🔐 FORGOT PASSWORD APIs FOR ADMIN
// ========================================

// 1️⃣ Send Forgot Password OTP
exports.sendForgotPasswordOTP = catchAsync(async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({
      status: 0,
      message: "Email is required"
    });
  }

  // Check if email exists in AdminUsers
  const admin = await prisma.adminUsers.findFirst({
    where: {
      emailId: email,
      status: 1 // Only active admins
    }
  });

  if (!admin) {
    return res.status(404).json({
      status: 0,
      message: "Email not found"
    });
  }

  // Generate 4-digit OTP
  let otp;
  if (process.env.NODE_ENV === 'production') {
    otp = Math.floor(100000 + Math.random() * 900000).toString(); // Random 4-digit OTP in production
  } else {
    otp = '123456'; // Fixed OTP for development
  }

  // Store OTP in database
  await prisma.adminUsers.update({
    where: { adminId: admin.adminId },
    data: {
      otp,
      otpStatus: 1
    }
  });

  // Send OTP via email (only in production)
  if (process.env.NODE_ENV === 'production') {
    const { sendAdminForgotPasswordOTP } = require('../utils/emailService');

    const emailResult = await sendAdminForgotPasswordOTP(email, otp);

    if (emailResult.success) {
      console.log(`✅ [ADMIN FORGOT PASSWORD] OTP sent to ${email}`);
    } else {
      console.error(`❌ [ADMIN FORGOT PASSWORD] Failed to send OTP to ${email}:`, emailResult.error);
      // Still return success to user for security (don't reveal if email exists)
    }
  } else {
    // Development mode - just log OTP
    console.log(`🔐 [ADMIN FORGOT PASSWORD] OTP for ${email}: ${otp} (Development mode - email not sent)`);
  }

  return res.status(200).json({
    status: 1,
    message: "OTP sent to your email"
  });
});

// 2️⃣ Verify Forgot Password OTP
exports.verifyForgotPasswordOTP = catchAsync(async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({
      status: 0,
      message: "Email and OTP are required"
    });
  }

  // Fetch admin user
  const admin = await prisma.adminUsers.findFirst({
    where: {
      emailId: email,
      status: 1
    }
  });

  if (!admin) {
    return res.status(404).json({
      status: 0,
      message: "Email not found"
    });
  }

  // Verify OTP length
  if (otp.length !== 6) {
    return res.status(400).json({
      status: 0,
      message: "Invalid OTP format"
    });
  }

  // Verify OTP matches
  if (admin.otp !== otp || admin.otpStatus !== 1) {
    return res.status(400).json({
      status: 0,
      message: "Invalid or expired OTP"
    });
  }

  // Mark OTP as verified
  await prisma.adminUsers.update({
    where: { adminId: admin.adminId },
    data: {
      otpStatus: 0
    }
  });

  return res.status(200).json({
    status: 1,
    message: "OTP verified successfully",
    email
  });
});

// 3️⃣ Reset Password
exports.resetPassword = catchAsync(async (req, res) => {
  const { email, newPassword } = req.body;

  if (!email || !newPassword) {
    return res.status(400).json({
      status: 0,
      message: "Email and new password are required"
    });
  }

  // Fetch admin user
  const admin = await prisma.adminUsers.findFirst({
    where: {
      emailId: email,
      status: 1
    }
  });

  if (!admin) {
    return res.status(404).json({
      status: 0,
      message: "Email not found"
    });
  }

  // Hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  // Update password
  await prisma.adminUsers.update({
    where: { adminId: admin.adminId },
    data: {
      password: hashedPassword,
      otp: null, // Clear OTP
      otpStatus: 0 // Reset OTP status
    }
  });

  return res.status(200).json({
    status: 1,
    message: "Password reset successfully"
  });
});



exports.resetOldPassword = catchAsync(async (req, res) => {
  const { email } = req.admin;
  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || !newPassword) {
    return res.status(400).json({
      status: 0,
      message: "Old password and new password are required"
    });
  }

  // Fetch admin user
  const admin = await prisma.adminUsers.findFirst({
    where: {
      emailId: email,
      status: 1
    }
  });

  if (!admin) {
    return res.status(404).json({
      status: 0,
      message: "Email not found"
    });
  }

  // Verify old password
  const isPasswordValid = await bcrypt.compare(oldPassword, admin.password);

  if (!isPasswordValid) {
    return res.status(400).json({
      status: 0,
      message: "Old password is incorrect"
    });
  }

  // Hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 10);

  // Update password
  await prisma.adminUsers.update({
    where: { adminId: admin.adminId },
    data: {
      password: hashedPassword,
      otp: null, // Clear OTP
      otpStatus: 0 // Reset OTP status
    }
  });

  return res.status(200).json({
    status: 1,
    message: "Password reset successfully"
  });
});

/**
 * Add/Update Stripe Account ID for a kitchen
 * Automatically sets payout schedule to weekly on Mondays
 */
exports.addStripeAccountToKitchen = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;
  const { stripeAccountId } = req.body;

  if (!stripeAccountId) {
    return res.status(400).json({
      status: 0,
      message: "stripeAccountId is required"
    });
  }

  // Fetch kitchen
  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  // Determine action type based on whether account already exists
  const oldStripeAccountId = kitchen.stripeAccountId;
  const actionType = oldStripeAccountId
    ? 'STRIPE_ACCOUNT_CHANGED'
    : 'STRIPE_ACCOUNT_LINKED_MANUAL';

  // 🔍 VALIDATE STRIPE ACCOUNT CAPABILITIES
  try {


    console.log(`🔍 [STRIPE] Validating account: ${stripeAccountId}`);
    const account = await stripe.accounts.retrieve(stripeAccountId);

    // Check if transfers are active (Required for platform to transfer funds/split payments)
    if (account.capabilities?.transfers !== 'active') {
      console.error(`❌ [STRIPE] Account ${stripeAccountId} lacks 'transfers' capability. Current status: ${account.capabilities?.transfers || 'inactive'}`);

      return res.status(400).json({
        status: 0,
        message: "This Stripe account is not fully setup. The 'transfers' capability must be 'active' to receive payments.",
        details: {
          accountId: stripeAccountId,
          currentStatus: account.capabilities?.transfers || 'inactive',
          requirements: "Ensure business details and bank account are verified in Stripe dashboard."
        }
      });
    }

    console.log(`✅ [STRIPE] Account validated successfully (transfers: active)`);
  } catch (stripeError) {
    console.error("❌ [STRIPE] Error retrieving account:", stripeError.message);
    return res.status(400).json({
      status: 0,
      message: `Failed to verify Stripe account: ${stripeError.message}`
    });
  }

  // Update kitchen with Stripe account ID and mark account as connected
  await prisma.kitchen.update({
    where: { kitchenId: Number(kitchenId) },
    data: {
      stripeAccountId,
      stripeAccountConnected: true  // ✅ Account is connected
    }
  });

  console.log(`✅ [STRIPE] Kitchen ${kitchenId} - Stripe account connected`);

  // ⭐ Automatically set payout schedule
  try {
    const { setWeeklyPayoutSchedule } = require('../utils/stripePayoutScheduler');
    const result = await setWeeklyPayoutSchedule(stripeAccountId);

    // ✅ Mark onboarding as complete only if payout schedule succeeds
    await prisma.kitchen.update({
      where: { kitchenId: Number(kitchenId) },
      data: {
        stripeOnboardingCompleted: true,
        stripeConnectedAt: new Date()
      }
    });

    // 📡 Trigger socket to kitchen to update UI
    try {
      const io = getIO();
      io.to(`kitchen_${kitchenId}`).emit("stripe-onboarding-completed", {
        success: true,
        message: "Stripe onboarding completed successfully and payout schedule configured"
      });
      console.log(`📡 [SOCKET] Notified kitchen ${kitchenId} about onboarding completion`);
    } catch (socketError) {
      console.error(`⚠️ [SOCKET] Failed to notify kitchen ${kitchenId}:`, socketError.message);
    }

    console.log(`✅ [STRIPE] Kitchen ${kitchenId} - Onboarding completed with payout schedule`);

    // 🔍 CREATE AUDIT LOG for successful Stripe account linking
    try {
      const auditLogger = require('../utils/auditLogger');
      await auditLogger.createAuditLog({
        kitchenId: Number(kitchenId),
        actorType: 'ADMIN',
        actorId: req.adminId,
        actorName: req.admin?.name || 'Admin',
        actorRole: req.admin?.role || 'ADMIN',
        actionType,
        actionDescription: oldStripeAccountId
          ? `Stripe account ID changed from ${oldStripeAccountId} to ${stripeAccountId} with payout schedule`
          : `Stripe account manually linked: ${stripeAccountId} with weekly payout schedule`,
        oldData: oldStripeAccountId || null,
        newData: stripeAccountId,
        metadata: {
          linkedBy: 'ADMIN',
          previousAccountId: oldStripeAccountId || null,
          stripeAccountConnected: true,
          stripeOnboardingCompleted: true,
          payoutSchedule: result.payoutSchedule,
          autoConfigured: true
        },
        ipAddress: auditLogger.getIpAddress(req),
        userAgent: auditLogger.getUserAgent(req)
      });
      console.log(`📝 [STRIPE] Audit log created for kitchen ${kitchenId}`);
    } catch (auditError) {
      console.error(`⚠️  [STRIPE] Failed to create audit log:`, auditError.message);
      // Don't fail the entire process if audit logging fails
    }

    return res.status(200).json({
      status: 1,
      message: "Stripe account added and payout schedule configured successfully",
      data: {
        kitchenId: kitchen.kitchenId,
        kitchenName: kitchen.kitchenName,
        stripeAccountId,
        stripeAccountConnected: true,
        stripeOnboardingCompleted: true,
        payoutSchedule: result.payoutSchedule
      }
    });

  } catch (error) {
    console.error("❌ [STRIPE] Error setting payout schedule:", error);

    // 🔍 CREATE AUDIT LOG for partial success (account linked but payout failed)
    try {
      const auditLogger = require('../utils/auditLogger');
      await auditLogger.createAuditLog({
        kitchenId: Number(kitchenId),
        actorType: 'ADMIN',
        actorId: req.adminId,
        actorName: req.admin?.name || 'Admin',
        actorRole: req.admin?.role || 'ADMIN',
        actionType,
        actionDescription: oldStripeAccountId
          ? `Stripe account ID changed from ${oldStripeAccountId} to ${stripeAccountId} (payout schedule failed)`
          : `Stripe account manually linked: ${stripeAccountId} (payout schedule failed)`,
        oldData: oldStripeAccountId || null,
        newData: stripeAccountId,
        metadata: {
          linkedBy: 'ADMIN',
          previousAccountId: oldStripeAccountId || null,
          stripeAccountConnected: true,
          stripeOnboardingCompleted: false,
          payoutScheduleError: error.message,
          autoConfigured: false
        },
        ipAddress: auditLogger.getIpAddress(req),
        userAgent: auditLogger.getUserAgent(req)
      });
      console.log(`📝 [STRIPE] Audit log created for kitchen ${kitchenId} (partial success)`);
    } catch (auditError) {
      console.error(`⚠️  [STRIPE] Failed to create audit log:`, auditError.message);
    }

    // Kitchen account is connected but onboarding not complete (payout schedule failed)
    return res.status(200).json({
      status: 1,
      message: "Stripe account connected but payout schedule configuration failed",
      data: {
        kitchenId: kitchen.kitchenId,
        kitchenName: kitchen.kitchenName,
        stripeAccountId,
        stripeAccountConnected: true,
        stripeOnboardingCompleted: false
      },
      warning: error.message
    });
  }
});


/**
 * Update User Status (Admin Only)
 * Allows admin to change user status to ACTIVE or INACTIVE
 * For INACTIVE: Captures reason and schedules deletion after 6 months
 */
exports.updateUserStatus = catchAsync(async (req, res) => {
  const { userId } = req.params;
  const { status, reasonType, reasonText } = req.body;

  // Validate status
  const validStatuses = ["ACTIVE", "INACTIVE"];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      status: 0,
      message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`
    });
  }

  // Check if user exists
  const user = await prisma.user.findUnique({
    where: { userId: Number(userId) }
  });

  if (!user) {
    return res.status(404).json({
      status: 0,
      message: "User not found"
    });
  }

  if (status === "INACTIVE") {
    if (!reasonType) {
      return res.status(400).json({
        status: 0,
        message: "Reason type is required for inactivation (e.g., FRAUD, SCAM)"
      });
    }

    // 1. Create UserAccountRequest for INACTIVE status
    const deletionDate = new Date();
    deletionDate.setMonth(deletionDate.getMonth() + 6);

    await prisma.userAccountRequest.create({
      data: {
        userId: Number(userId),
        requestType: "INACTIVE",
        reasonType: reasonType,
        reasonText: reasonText || null,
        requestedAt: new Date(),
        scheduledDeletionAt: deletionDate,
        status: "PENDING"
      }
    });
  } else if (status === "ACTIVE") {
    // 2. If moving to ACTIVE, cancel any pending requests
    await prisma.userAccountRequest.updateMany({
      where: {
        userId: Number(userId),
        status: "PENDING"
      },
      data: { status: "CANCELLED" }
    });
  }

  // Update user status
  const updatedUser = await prisma.user.update({
    where: { userId: Number(userId) },
    data: {
      status,
      statusReason: reasonText || reasonType || null,
      isActive: status === "ACTIVE" ? 1 : 0
    }
  });

  // 📧 Send email notification when marking INACTIVE
  if (status === "INACTIVE" && user.email) {
    try {
      const { sendUserAccountInactiveEmail } = require("../utils/emailService");
      const userName = [user.name, user.lastName].filter(Boolean).join(" ") || "User";
      await sendUserAccountInactiveEmail(
        user.email,
        userName,
        reasonType,       // e.g. "Policy Violation", "FRAUD", "SCAM"
        reasonText || "Please contact support for more details."
      );
      console.log(`📧 [ADMIN] Inactive email sent to user ${userId} (${user.email})`);
    } catch (emailErr) {
      console.error(`⚠️ [ADMIN] Failed to send inactive email to user ${userId}:`, emailErr.message);
      // Don't fail the request if email fails
    }
  }

  // 🔔 Socket + Push notification when marking INACTIVE
  if (status === "INACTIVE") {
    const notifTitle = "Your account has been marked Inactive";
    const notifBody = reasonText
      ? `Reason: ${reasonText}. Please contact support@resqboxfood.com for assistance.`
      : "Please contact support@resqboxfood.com for assistance.";

    // 1️⃣ Real-time socket event (if user is online)
    try {
      const { getIO } = require("../utils/socket");
      getIO().to(`user_${userId}`).emit("account_status_changed", {
        status: "INACTIVE",
        reasonType: reasonType || null,
        reasonText: reasonText || null,
        message: notifTitle
      });
      console.log(`🔌 [SOCKET] account_status_changed emitted to user_${userId}`);
    } catch (socketErr) {
      console.error(`⚠️ [SOCKET] Failed to emit to user_${userId}:`, socketErr.message);
    }

    // 2️⃣ FCM push notification (if user has a device token)
    if (user.deviceToken) {
      try {
        await handleFactory.sendNotificationToUser(
          Number(userId),
          { title: notifTitle, body: notifBody, orderId: "" },
          user.deviceToken
        );
        console.log(`📲 [PUSH] Inactive push sent to user ${userId}`);
      } catch (pushErr) {
        console.error(`⚠️ [PUSH] Failed to send push to user ${userId}:`, pushErr.message);
      }
    }

    // 3️⃣ Save in-app notification record
    try {
      await prisma.notification.create({
        data: {
          ownerId: Number(userId),
          ownerType: "USER",
          title: notifTitle,
          message: notifBody,
          type: 1
        }
      });
    } catch (notifErr) {
      console.error(`⚠️ [NOTIFY] Failed to save notification for user ${userId}:`, notifErr.message);
    }
  }

  console.log(`✅ [ADMIN] User ${userId} status updated to ${status} by admin ${req.user?.adminId}`);

  res.json({
    status: 1,
    message: `User status updated to ${status} successfully`,
    user: {
      userId: updatedUser.userId,
      status: updatedUser.status,
      isActive: updatedUser.isActive
    }
  });
});

const { checkAndProcessAccountDeletions } = require("../cron/accountDeletionChecker");

/**
 * Endpoint to process pending deletions (Can be called by a cron job or manually)
 */
exports.processScheduledDeletions = catchAsync(async (req, res) => {
  const result = await checkAndProcessAccountDeletions();

  if (result.success) {
    return res.json({
      status: 1,
      message: "Scheduled deletions processed",
      results: {
        total: result.total,
        success: result.count,
        failed: result.failed
      }
    });
  } else {
    return res.status(500).json({
      status: 0,
      message: "Failed to process scheduled deletions",
      error: result.error
    });
  }
});
exports.getStripeLogs = catchAsync(async (req, res) => {
  try {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const total = await prisma.stripeEventLog.count();
    const logs = await prisma.stripeEventLog.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' }
    });

    return res.status(200).json({
      status: 1,
      message: "Stripe logs fetched successfully",
      total,
      data: logs,
      pagination: {
        total,
        currentPage: page,
        totalPages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error("❌ Error in getStripeLogs:", error);
    return res.status(500).json({ status: 0, message: "Internal server error" });
  }
});

// ========================================
// 🔍 RESTAURANT AUDIT TRAIL ENDPOINTS
// ========================================

/**
 * Get all audit logs (Super Admin view)
 */
exports.getAllAuditLogs = catchAsync(async (req, res) => {

  const result = await auditLogger.getAllAuditLogs(req.query);

  return res.status(200).json({
    status: 1,
    message: "Audit logs fetched successfully",
    logs: result.logs,
    pagination: result.pagination
  });
});

/**
 * Get audit logs for a specific kitchen
 */
exports.getKitchenAuditLogs = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;

  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) },
    select: { kitchenId: true, kitchenName: true, status: true }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  const result = await auditLogger.getKitchenAuditLogs(Number(kitchenId), req.query);

  return res.status(200).json({
    status: 1,
    message: "Kitchen audit logs fetched successfully",
    kitchen,
    logs: result.logs,
    pagination: result.pagination
  });
});

/**
 * Get audit log statistics for a kitchen
 */
exports.getKitchenAuditStats = catchAsync(async (req, res) => {
  const { kitchenId } = req.params;

  const kitchen = await prisma.kitchen.findUnique({
    where: { kitchenId: Number(kitchenId) }
  });

  if (!kitchen) {
    return res.status(404).json({
      status: 0,
      message: "Kitchen not found"
    });
  }

  const [totalLogs, statusChanges, stripeActions, lastActivity] = await Promise.all([
    prisma.restaurantAuditLog.count({
      where: { kitchenId: Number(kitchenId) }
    }),
    prisma.restaurantAuditLog.count({
      where: {
        kitchenId: Number(kitchenId),
        actionType: {
          in: ['STATUS_APPROVED', 'STATUS_REJECTED', 'STATUS_REAPPLIED', 'STATUS_REAPPROVED', 'STATUS_REREJECTED']
        }
      }
    }),
    prisma.restaurantAuditLog.count({
      where: {
        kitchenId: Number(kitchenId),
        actionType: {
          in: ['STRIPE_ACCOUNT_LINKED', 'STRIPE_ACCOUNT_LINKED_AUTO', 'STRIPE_ACCOUNT_LINKED_MANUAL', 'STRIPE_ACCOUNT_CHANGED']
        }
      }
    }),
    prisma.restaurantAuditLog.findFirst({
      where: { kitchenId: Number(kitchenId) },
      orderBy: { createdAt: 'desc' },
      select: {
        actionType: true,
        actorType: true,
        actorName: true,
        createdAt: true
      }
    })
  ]);

  return res.status(200).json({
    status: 1,
    message: "Audit statistics fetched successfully",
    stats: {
      totalLogs,
      statusChanges,
      stripeActions,
      lastActivity
    }
  });
});
