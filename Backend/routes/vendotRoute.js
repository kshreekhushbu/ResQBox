const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const vendorController = require("../controllers/vendorController");
const timezoneController = require("../controllers/timezoneController");
const { upload } = require("../utils/upload");
const { authLimiter, uploadLimiter } = require("../utils/authLimiter");
const uploadImage = require("../controllers/imageUpload");

router.post("/upload", uploadLimiter, upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", uploadLimiter, upload.array("files"), uploadImage.uploadMultipleImages);

router.post("/loginKitchen", authLimiter, vendorController.loginKitchen)
router.post("/registerKitchen", vendorController.registerKitchen)
router.get("/getConfig", vendorController.getConfig)
router.get("/getCuisines", vendorController.getCuisines)

router.post("/checkEmailExists", vendorController.checkEmailExists)
router.get("/getAbnDetails", vendorController.getAbnDetails)

router.post("/sendForgotPasswordOTP", authLimiter, vendorController.sendForgotPasswordOTP)
router.post("/verifyForgotPasswordOTP", authLimiter, vendorController.verifyForgotPasswordOTP)
router.post("/resetPassword", authLimiter, vendorController.resetPassword)

router.get("/getActiveTimezones", timezoneController.getActiveTimezones)
router.get("/getFoodTypes", vendorController.getFoodTypes)
router.get("/getMenuTypes", vendorController.getMenuTypes)

router.get("/stripe-onboarding-return", vendorController.stripeOnboardingReturn)
router.get("/stripe-onboarding-refresh", vendorController.stripeOnboardingRefresh)

router.use(auth.authenticateOptionalKitchen)
router.get("/getKitchenStatus", vendorController.getKitchenStatus)
router.get("/getKitchenDetails", vendorController.getKitchenDetails)
router.put("/reapplyKitchen", auth.requireKitchenOwner, vendorController.reapplyKitchen)
router.put("/updateKitchen", auth.requireKitchenOwner, vendorController.updateKitchen)

router.use(auth.authenticateKitchen)
router.post("/resetOldPassword", auth.requireKitchenOwner, vendorController.resetOldPassword)
router.post("/logoutKitchen", vendorController.logoutKitchen)

router.get("/getCategories", vendorController.getCategories)
router.post("/addMenuItem", vendorController.addMenuItem)
router.get("/getAllMenuItems", vendorController.getAllMenuItems)
router.get("/getMenuItemById/:id", vendorController.getMenuItemById)
router.put("/updateMenuItem/:id", vendorController.updateMenuItem)
router.put("/inactivateMenuItem/:id", vendorController.inactivateMenuItem)
router.put("/updateKitchenActiveStatus ", auth.requireKitchenOwner, vendorController.updateKitchenActiveStatus)
router.delete("/deleteMenuItem/:id", vendorController.deleteMenuItem)
router.get("/getKitchenOrders", vendorController.getKitchenOrders)
router.get("/getKitchenOrderById/:orderId", vendorController.getKitchenOrderById)

router.put("/acceptOrder/:orderId", vendorController.acceptOrder)
router.put("/rejectOrder/:orderId", vendorController.rejectOrder)
router.put("/updateOrderStatus/:orderId", vendorController.updateStatus)
router.put("/updateNotificationTime", auth.requireKitchenOwner, vendorController.updateNotificationTime)
router.post("/addTeamMember", auth.requireKitchenOwner, vendorController.addTeamMember)
router.get("/getTeamMembers", auth.requireKitchenOwner, vendorController.getTeamMembers)
router.get("/getTeamMemberById/:id", auth.requireKitchenOwner, vendorController.getTeamMemberById)
router.put("/updateTeamMember/:id", auth.requireKitchenOwner, vendorController.updateTeamMember)
router.delete("/deleteTeamMember/:id", auth.requireKitchenOwner, vendorController.deleteTeamMember)

router.post("/startKitchenSupportChat", vendorController.startKitchenSupportChat)
router.get("/getKitchenSupportChatMessages", vendorController.getKitchenSupportChatMessages)

router.get("/getNotifications", vendorController.getNotifications)
router.get("/getPayoutInvoices", auth.requireKitchenOwner, vendorController.getPayoutInvoices)
router.get("/getPayoutInvoiceDetails/:payoutId", auth.requireKitchenOwner, vendorController.getPayoutInvoiceDetails)

router.get("/getMonthlyInvoices", auth.requireKitchenOwner, vendorController.getMonthlyInvoices)
router.get("/getMonthlyInvoiceDetails/:invoiceId", auth.requireKitchenOwner, vendorController.getMonthlyInvoiceDetails)

router.get("/getAllTransactions", auth.requireKitchenOwner, vendorController.getAllTransactions)
router.get("/getKitchenDashboard", auth.requireKitchenOwner, vendorController.getKitchenDashboard)

router.get("/getFoodCertificates", auth.requireKitchenOwner, vendorController.getFoodCertificates)
router.post("/addFoodCertificate", auth.requireKitchenOwner, vendorController.addFoodCertificate)

router.get("/getVendorNotifications", vendorController.getVendorNotifications)

router.post("/triggerCertificateExpiryCheck", auth.requireKitchenOwner, vendorController.triggerCertificateExpiryCheck)

router.put("/updateKitchenTimezone", auth.requireKitchenOwner, timezoneController.updateKitchenTimezone)

router.post("/validateOfferPrice", vendorController.validateOfferPrice)

router.get("/getStripeDashboardLink", auth.requireKitchenOwner, vendorController.getStripeDashboardLink)

module.exports = router;
