const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const adminController = require("../controllers/adminController");
const timezoneController = require("../controllers/timezoneController");
const { upload } = require("../utils/upload");
const { authLimiter, uploadLimiter } = require("../utils/authLimiter");
const uploadImage = require("../controllers/imageUpload");

router.post("/adminLogin", authLimiter, adminController.adminLogin)
router.post("/adminSignUp", authLimiter, adminController.adminSignUp)

router.post("/sendForgotPasswordOTP", authLimiter, adminController.sendForgotPasswordOTP)
router.post("/verifyForgotPasswordOTP", authLimiter, adminController.verifyForgotPasswordOTP)
router.post("/resetPassword", authLimiter, adminController.resetPassword)

router.use(auth.authenticateAdmin)

router.post("/upload", uploadLimiter, upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", uploadLimiter, upload.array("files"), uploadImage.uploadMultipleImages);

router.post("/logout", adminController.adminLogout)
router.post("/resetOldPassword", adminController.resetOldPassword)
router.get("/getDashboard", auth.requirePermission("dashboard", "read"), adminController.getDashboard)

router.post("/createAdminUser", auth.requirePermission("teams", "write"), adminController.createAdminUser)
router.get("/getAdminUsers", auth.requirePermission("teams", "read"), adminController.getSubAdmins)
router.put("/updateAdminUser/:adminId", auth.requirePermission("teams", "edit"), adminController.updateSubAdmin)
router.get("/getAdminUserById/:id", auth.requirePermission("teams", "read"), adminController.getAdminUserById)
router.delete("/deleteAdminUser/:adminId", auth.requirePermission("teams", "delete"), adminController.deleteSubAdmin)

router.post("/createRole", auth.requirePermission("roles", "write"), adminController.createRole)
router.get("/getRoles", auth.requirePermission("roles", "read"), adminController.getAllRoles)
router.get("/getRoleById/:id", auth.requirePermission("roles", "read"), adminController.getRoleById)
router.put("/updateRole/:id", auth.requirePermission("roles", "edit"), adminController.updateRolePermissions)

router.post("/addBanner", auth.requirePermission("banners", "write"), adminController.addBanner)
router.put("/updateBanner/:bannerId", auth.requirePermission("banners", "edit"), adminController.updateBanner)
router.get("/getBanners", auth.requirePermission("banners", "read"), adminController.getBanners)
router.get("/getBannerById/:bannerId", auth.requirePermission("banners", "read"), adminController.getBannerById)
router.delete("/deleteBanner/:bannerId", auth.requirePermission("banners", "delete"), adminController.deleteBanner)

router.post("/addCategory", auth.requirePermission("categories", "write"), adminController.addCategory)
router.put("/updateCategory/:categoryId", auth.requirePermission("categories", "edit"), adminController.updateCategory)
router.get("/getCategories", auth.requirePermission("categories", "read"), adminController.getCategories)
router.get("/getCategoryById/:categoryId", auth.requirePermission("categories", "read"), adminController.getCategoryById)
router.delete("/deleteCategory/:categoryId", auth.requirePermission("categories", "delete"), adminController.deleteCategory)

router.post("/addTimezone", timezoneController.addTimezone)
router.post("/bulkAddTimezones", timezoneController.bulkAddTimezones)
router.get("/getAllTimezones", timezoneController.getAllTimezones)
router.get("/getTimezoneById/:id", timezoneController.getTimezoneById)
router.put("/updateTimezone/:id", timezoneController.updateTimezone)
router.delete("/deleteTimezone/:id", timezoneController.deleteTimezone)

router.post("/addFoodType", auth.requirePermission("categories", "write"), adminController.addFoodType)
router.put("/updateFoodType/:foodTypeId", auth.requirePermission("categories", "edit"), adminController.updateFoodType)
router.get("/getFoodTypes", auth.requirePermission("categories", "read"), adminController.getFoodTypes)
router.get("/getFoodTypeById/:foodTypeId", auth.requirePermission("categories", "read"), adminController.getFoodTypeById)
router.delete("/deleteFoodType/:foodTypeId", auth.requirePermission("categories", "delete"), adminController.deleteFoodType)

router.post("/addCuisine", auth.requirePermission("categories", "write"), adminController.addCuisine)
router.put("/updateCuisine/:cuisineId", auth.requirePermission("categories", "edit"), adminController.updateCuisine)
router.get("/getCuisines", auth.requirePermission("categories", "read"), adminController.getCuisines)
router.get("/getCuisineById/:cuisineId", auth.requirePermission("categories", "read"), adminController.getCuisineById)
router.delete("/deleteCuisine/:cuisineId", auth.requirePermission("categories", "delete"), adminController.deleteCuisine)

const bulkUploadController = require("../controllers/bulkUpload");
router.post("/bulkUploadCuisines", auth.requirePermission("categories", "write"), upload.single("file"), bulkUploadController.bulkUploadCuisines)
router.post("/bulkUploadFoodCategories", auth.requirePermission("categories", "write"), upload.single("file"), bulkUploadController.bulkUploadFoodCategories)

router.get("/getKitchenDetailsById/:kitchenId", auth.requirePermission("restaurants", "read"), adminController.getKitchenDetailsById)
router.get("/getAllKitchens", auth.requirePermission("restaurants", "read"), adminController.getAllKitchens)
router.put("/updateComplianceStatus/:kitchenId", auth.requirePermission("restaurants", "edit"), adminController.updateComplianceStatus)
router.put("/updateKitchenStatus/:kitchenId", auth.requirePermission("restaurants", "edit"), adminController.updateKitchenStatus)
router.put("/updateKitchenStripeAccountId/:kitchenId", auth.requirePermission("restaurants", "edit"), adminController.addStripeAccountToKitchen)
router.put("/addStripeAccountToKitchen/:kitchenId", auth.requirePermission("restaurants", "edit"), adminController.addStripeAccountToKitchen)

router.get("/getConfig", auth.requirePermission("config", "read"), adminController.getConfig)
router.put("/updateConfig", auth.requirePermission("config", "edit"), adminController.updateConfig)

router.get("/getAllUserDetails", auth.requirePermission("users", "read"), adminController.getAllUserDetails)
router.get("/adminGetAllOrders", auth.requirePermission("orders", "read"), adminController.adminGetAllOrders)
router.get("/getOrderDetails/:orderUid", auth.requirePermission("orders", "read"), adminController.getOrderDetails)

router.get("/getPagePermissions", adminController.getPagePermissions)

router.get("/getCurrentPayouts", auth.requirePermission("payouts", "read"), adminController.getCurrentPayouts)
router.post("/payKitchen", auth.requirePermission("payouts", "write"), adminController.payKitchen)
router.get("/getInvoices", auth.requirePermission("invoices", "read"), adminController.getInvoices)

router.get("/adminGetSupportChats", auth.requirePermission("support requests", "read"), adminController.adminGetSupportChats)
router.get("/getChatMessages/:chatRoomId", auth.requirePermission("support requests", "read"), adminController.getChatMessages)
router.post("/sendAdminSupportMessage", auth.requirePermission("support requests", "write"), adminController.sendAdminSupportMessage)
router.put("/closeSupportChat/:roomId", auth.requirePermission("support requests", "edit"), adminController.closeSupportChat)

router.get("/getOrdersByKitchenId/:kitchenId", auth.requirePermission("orders", "read"), adminController.getOrdersByKitchenId)

router.post("/sendAdminNotification", auth.requirePermission("notifications", "write"), adminController.sendAdminNotification)
router.get("/getAdminNotifications", auth.requirePermission("notifications", "read"), adminController.getAdminNotifications)

router.get("/getAdminAlerts", adminController.getAdminAlerts)
router.put("/markAlertAsViewed/:alertId", adminController.markAlertAsViewed)

router.post("/generateMonthlyInvoices", auth.requirePermission("invoices", "write"), adminController.manualGenerateMonthlyInvoices)
router.get("/getMonthlyInvoices", auth.requirePermission("invoices", "read"), adminController.getMonthlyInvoices)
router.get("/getMonthlyInvoiceById/:invoiceId", auth.requirePermission("invoices", "read"), adminController.getMonthlyInvoiceById)

router.get("/getStripeLogs", auth.requirePermission("invoices", "read"), adminController.getStripeLogs)

router.put("/updateUserStatus/:userId", auth.requirePermission("users", "edit"), adminController.updateUserStatus)
router.post("/processScheduledDeletions", auth.requirePermission("users", "delete"), adminController.processScheduledDeletions)

router.post("/addMenuType", auth.requirePermission("categories", "write"), adminController.addMenuType)
router.put("/updateMenuType/:menuTypeId", auth.requirePermission("categories", "edit"), adminController.updateMenuType)
router.get("/getMenuTypes", auth.requirePermission("categories", "read"), adminController.getMenuTypes)
router.get("/getMenuTypeById/:menuTypeId", auth.requirePermission("categories", "read"), adminController.getMenuTypeById)
router.delete("/deleteMenuType/:menuTypeId", auth.requirePermission("categories", "delete"), adminController.deleteMenuType)

router.get("/audit-logs", auth.requirePermission("restaurants", "read"), adminController.getAllAuditLogs)
router.get("/audit-logs/kitchen/:kitchenId", auth.requirePermission("restaurants", "read"), adminController.getKitchenAuditLogs)
router.get("/audit-logs/kitchen/:kitchenId/stats", auth.requirePermission("restaurants", "read"), adminController.getKitchenAuditStats)

module.exports = router;
