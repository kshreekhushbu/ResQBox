const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const adminController = require("../controllers/adminController");
const timezoneController = require("../controllers/timezoneController");

const multer = require("multer");
const uploadImage = require("../controllers/imageUpload"); // Import Controller

const upload = multer({ storage: multer.memoryStorage() });

router.post("/upload", upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", upload.array("files"), uploadImage.uploadMultipleImages);

router.post('/adminSignUp', adminController.adminSignUp)
router.post('/adminLogin', adminController.adminLogin)

// 🔐 Forgot Password Routes (Public - No Auth Required)
router.post('/sendForgotPasswordOTP', adminController.sendForgotPasswordOTP)
router.post('/verifyForgotPasswordOTP', adminController.verifyForgotPasswordOTP)
router.post('/resetPassword', adminController.resetPassword)
router.put('/addStripeAccountToKitchen/:kitchenId', adminController.addStripeAccountToKitchen)

router.use(auth.authenticateAdmin)
router.post('/resetOldPassword', adminController.resetOldPassword)
router.get('/getDashboard', adminController.getDashboard)

router.post('/createAdminUser', adminController.createAdminUser)
router.get('/getAdminUsers', adminController.getSubAdmins)
router.put('/updateAdminUser/:adminId', adminController.updateSubAdmin)
router.get('/getAdminUserById/:id', adminController.getAdminUserById)
router.delete('/deleteAdminUser/:adminId', adminController.deleteSubAdmin)

router.post('/createRole', adminController.createRole)
router.get('/getRoles', adminController.getAllRoles)
router.get('/getRoleById/:id', adminController.getRoleById)
router.put('/updateRole/:id', adminController.updateRolePermissions)

router.post('/addBanner', adminController.addBanner)
router.put('/updateBanner/:bannerId', adminController.updateBanner)
router.get('/getBanners', adminController.getBanners)
router.get('/getBannerById/:bannerId', adminController.getBannerById)
router.delete('/deleteBanner/:bannerId', adminController.deleteBanner)

router.post('/addCategory', adminController.addCategory)
router.put('/updateCategory/:categoryId', adminController.updateCategory)
router.get('/getCategories', adminController.getCategories)
router.get('/getCategoryById/:categoryId', adminController.getCategoryById)
router.delete('/deleteCategory/:categoryId', adminController.deleteCategory)

// Timezone Management
router.post('/addTimezone', timezoneController.addTimezone)
router.post('/bulkAddTimezones', timezoneController.bulkAddTimezones)
router.get('/getAllTimezones', timezoneController.getAllTimezones)
router.get('/getTimezoneById/:id', timezoneController.getTimezoneById)
router.put('/updateTimezone/:id', timezoneController.updateTimezone)
router.delete('/deleteTimezone/:id', timezoneController.deleteTimezone)


router.post('/addFoodType', adminController.addFoodType)
router.put('/updateFoodType/:foodTypeId', adminController.updateFoodType)
router.get('/getFoodTypes', adminController.getFoodTypes)

router.get('/getFoodTypeById/:foodTypeId', adminController.getFoodTypeById)
router.delete('/deleteFoodType/:foodTypeId', adminController.deleteFoodType)


router.post('/addCuisine', adminController.addCuisine)
router.put('/updateCuisine/:cuisineId', adminController.updateCuisine)
router.get('/getCuisines', adminController.getCuisines)
router.get('/getCuisineById/:cuisineId', adminController.getCuisineById)
router.delete('/deleteCuisine/:cuisineId', adminController.deleteCuisine)

// Bulk upload cuisines from Excel
const bulkUploadController = require('../controllers/bulkUpload');
router.post('/bulkUploadCuisines', upload.single('file'), bulkUploadController.bulkUploadCuisines)

// Bulk upload food categories from Excel
router.post('/bulkUploadFoodCategories', upload.single('file'), bulkUploadController.bulkUploadFoodCategories)

router.get('/getKitchenDetailsById/:kitchenId', adminController.getKitchenDetailsById)
router.get('/getAllKitchens', adminController.getAllKitchens)
router.put('/updateComplianceStatus/:kitchenId', adminController.updateComplianceStatus)
router.put('/updateKitchenStatus/:kitchenId', adminController.updateKitchenStatus)
router.put('/updateKitchenStripeAccountId/:kitchenId', adminController.addStripeAccountToKitchen)

router.get('/getConfig', adminController.getConfig)
router.put('/updateConfig', adminController.updateConfig)

router.get('/getAllUserDetails', adminController.getAllUserDetails)
router.get('/adminGetAllOrders', adminController.adminGetAllOrders)

router.get('/getOrderDetails/:orderUid', adminController.getOrderDetails)

router.get('/getPagePermissions', adminController.getPagePermissions)
// router.get('/getWeeklyPayouts', adminController.getWeeklyPayouts)

router.get('/getCurrentPayouts', adminController.getCurrentPayouts)

router.post('/payKitchen', adminController.payKitchen)

router.get('/getInvoices', adminController.getInvoices)

router.get('/adminGetSupportChats', adminController.adminGetSupportChats)

router.get('/getChatMessages/:chatRoomId', adminController.getChatMessages)

router.post('/sendAdminSupportMessage', adminController.sendAdminSupportMessage)

router.put('/closeSupportChat/:roomId', adminController.closeSupportChat)

router.get('/getOrdersByKitchenId/:kitchenId', adminController.getOrdersByKitchenId)

router.post('/sendAdminNotification', adminController.sendAdminNotification)

router.get('/getAdminNotifications', adminController.getAdminNotifications)

// Admin Alerts routes
router.get('/getAdminAlerts', adminController.getAdminAlerts)

router.put('/markAlertAsViewed/:alertId', adminController.markAlertAsViewed)

// Monthly invoice generation and management
router.post('/generateMonthlyInvoices', adminController.manualGenerateMonthlyInvoices)
router.get('/getMonthlyInvoices', adminController.getMonthlyInvoices)
router.get('/getMonthlyInvoiceById/:invoiceId', adminController.getMonthlyInvoiceById)

// Stripe payout schedule management

router.put('/addStripeAccountToKitchen/:kitchenId', adminController.addStripeAccountToKitchen);

router.put('/closeSupportChat/:roomId', adminController.closeSupportChat);

// 💳 Stripe Webhook Logs
router.get('/getStripeLogs', adminController.getStripeLogs)

// 👤 User Status & Account Requests
router.put('/updateUserStatus/:userId', adminController.updateUserStatus)
router.post('/processScheduledDeletions', adminController.processScheduledDeletions)


// Menu Type Routes
router.post('/addMenuType', adminController.addMenuType)
router.put('/updateMenuType/:menuTypeId', adminController.updateMenuType)
router.get('/getMenuTypes', adminController.getMenuTypes)
router.get('/getMenuTypeById/:menuTypeId', adminController.getMenuTypeById)
router.delete('/deleteMenuType/:menuTypeId', adminController.deleteMenuType)

// ========================================
// 🔍 RESTAURANT AUDIT TRAIL ROUTES
// ========================================
router.get('/audit-logs', adminController.getAllAuditLogs)
router.get('/audit-logs/kitchen/:kitchenId', adminController.getKitchenAuditLogs)
router.get('/audit-logs/kitchen/:kitchenId/stats', adminController.getKitchenAuditStats)


module.exports = router;
