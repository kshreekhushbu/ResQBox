const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const vendorController = require("../controllers/vendorController");
const timezoneController = require("../controllers/timezoneController");

const multer = require("multer");
const uploadImage = require("../controllers/imageUpload"); // Import Controller
const { ro } = require("date-fns/locale");

const upload = multer({ storage: multer.memoryStorage() });

router.post("/upload", upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", upload.array("files"), uploadImage.uploadMultipleImages);

router.post('/loginKitchen', vendorController.loginKitchen)
router.post('/registerKitchen', vendorController.registerKitchen)
router.get('/getConfig', vendorController.getConfig)
router.get('/getCuisines', vendorController.getCuisines)

router.post('/checkEmailExists', vendorController.checkEmailExists)
router.get('/getAbnDetails', vendorController.getAbnDetails)

// Forgot Password Routes (No authentication required)
router.post('/sendForgotPasswordOTP', vendorController.sendForgotPasswordOTP)
router.post('/verifyForgotPasswordOTP', vendorController.verifyForgotPasswordOTP)
router.post('/resetPassword', vendorController.resetPassword)

router.get('/getActiveTimezones', timezoneController.getActiveTimezones)
router.get('/getFoodTypes', vendorController.getFoodTypes)
router.get('/getMenuTypes', vendorController.getMenuTypes)

// Stripe Onboarding Callbacks (No authentication required)
router.get('/stripe-onboarding-return', vendorController.stripeOnboardingReturn)
router.get('/stripe-onboarding-refresh', vendorController.stripeOnboardingRefresh)

router.use(auth.authenticateOptionalKitchen)
router.get('/getKitchenStatus', vendorController.getKitchenStatus)
router.get('/getKitchenDetails', vendorController.getKitchenDetails)
router.put('/reapplyKitchen', vendorController.reapplyKitchen)
router.put('/updateKitchen', vendorController.updateKitchen)


router.use(auth.authenticateKitchen)
router.post('/resetOldPassword', vendorController.resetOldPassword)
router.post('/logoutKitchen', vendorController.logoutKitchen)

router.get('/getCategories', vendorController.getCategories)
router.post('/addMenuItem', vendorController.addMenuItem)
router.get('/getAllMenuItems', vendorController.getAllMenuItems)
router.get('/getMenuItemById/:id', vendorController.getMenuItemById)
router.put('/updateMenuItem/:id', vendorController.updateMenuItem)
router.put('/inactivateMenuItem/:id', vendorController.inactivateMenuItem)
router.put('/updateKitchenActiveStatus ', vendorController.updateKitchenActiveStatus)
router.delete('/deleteMenuItem/:id', vendorController.deleteMenuItem)
router.get('/getKitchenOrders', vendorController.getKitchenOrders)
router.get('/getKitchenOrderById/:orderId', vendorController.getKitchenOrderById)

router.put('/acceptOrder/:orderId', vendorController.acceptOrder)
router.put('/rejectOrder/:orderId', vendorController.rejectOrder)
router.put('/updateOrderStatus/:orderId', vendorController.updateStatus)
router.put('/updateNotificationTime', vendorController.updateNotificationTime)
router.post('/addTeamMember', vendorController.addTeamMember)
router.get('/getTeamMembers', vendorController.getTeamMembers)
router.get('/getTeamMemberById/:id', vendorController.getTeamMemberById)
router.put('/updateTeamMember/:id', vendorController.updateTeamMember)
router.delete('/deleteTeamMember/:id', vendorController.deleteTeamMember)

router.post('/startKitchenSupportChat', vendorController.startKitchenSupportChat)
router.get('/getKitchenSupportChatMessages', vendorController.getKitchenSupportChatMessages)

router.get('/getNotifications', vendorController.getNotifications)
router.get('/getPayoutInvoices', vendorController.getPayoutInvoices)
router.get('/getPayoutInvoiceDetails/:payoutId', vendorController.getPayoutInvoiceDetails)

// Monthly Invoice Routes
router.get('/getMonthlyInvoices', vendorController.getMonthlyInvoices)
router.get('/getMonthlyInvoiceDetails/:invoiceId', vendorController.getMonthlyInvoiceDetails)

router.get('/getAllTransactions', vendorController.getAllTransactions)
router.get('/getKitchenDashboard', vendorController.getKitchenDashboard)

router.get('/getFoodCertificates', vendorController.getFoodCertificates)
router.post('/addFoodCertificate', vendorController.addFoodCertificate)

// Vendor Notifications
router.get('/getVendorNotifications', vendorController.getVendorNotifications)

// Manual trigger for testing certificate expiry check
router.post('/triggerCertificateExpiryCheck', vendorController.triggerCertificateExpiryCheck)

// Timezone Management for Vendors
router.put('/updateKitchenTimezone', timezoneController.updateKitchenTimezone)

router.post('/validateOfferPrice', vendorController.validateOfferPrice)

// Stripe Dashboard Access
router.get('/getStripeDashboardLink', vendorController.getStripeDashboardLink)

module.exports = router;

