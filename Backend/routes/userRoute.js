const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const userController = require("../controllers/userController");

const multer = require("multer");
const uploadImage = require("../controllers/imageUpload"); // Import Controller
const { ro } = require("date-fns/locale");
// const { use } = require("react");

const upload = multer({ storage: multer.memoryStorage() });

router.post("/upload", upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", upload.array("files"), uploadImage.uploadMultipleImages);

router.post('/sendOtp', userController.sendOtp)
router.post('/verifyOtp', userController.verifyOtp)

router.post('/sendSignupOtp', userController.sendSignupOtp)
router.post('/signup', userController.signup)
router.post('/stripeWebhook', userController.stripeWebhook)

router.post('/googleLogin', userController.googleLogin)
router.post('/facebookLogin', userController.facebookLogin)
router.post('/appleLogin', userController.appleLogin)

// Guest Login - No OTP required, just deviceId
// router.post('/guestLogin', userController.guestLogin)

// ========================================
// 🌐 PUBLIC / OPTIONAL AUTH ROUTES
// These routes work with or without login
// ========================================
router.use(auth.optionalAuthenticateUser)

router.get('/homePage', userController.homePage)
router.get('/getActiveRestaurants', userController.getActiveRestaurants)
router.get('/getPopularProducts', userController.getPopularProducts)

router.get('/getAllCategories', userController.getAllCategories)
router.get('/getFoodType', userController.getFoodType)
router.get('/getMenu', userController.getMenu)
router.get('/getMenuById/:id', userController.getMenuById)

router.get('/getAllKitchens', userController.getAllKitchens)
router.get('/kitchenSearch', userController.kitchenSearch)
router.get('/getKitchenDetailsById/:kitchenId', userController.getKitchenDetailsById)

router.get('/getConfig', userController.getConfig)
router.get('/getKitchenReviews/:kitchenId', userController.getKitchenReviews)

// ⭐ Optional Auth - User-specific data if logged in, empty if not
router.get('/getNotifications', userController.getNotifications)
router.get('/getCart', userController.getCart)
router.get('/getWishlist', userController.getWishlist)

// ========================================
// 🔒 AUTHENTICATED ROUTES ONLY
// These routes require login
// ========================================
router.use(auth.authenticateUser)

router.get('/getUserDetails', userController.getUserDetails)
router.post('/updateUserDetails', userController.updateUserDetails)

router.post('/addToWishlist', userController.addToWishlist)
router.post('/removeFromWishlist/:kitchenId', userController.removeFromWishlist)

router.post('/addToCart', userController.addToCart)
router.post('/removeCartItem/:id', userController.removeCartItem)
router.post('/clearCart', userController.clearCart)

router.post('/placeOrder', userController.placeOrder)
router.get('/getMyOrders', userController.getMyOrders)
router.get('/getOrderDetails/:orderId', userController.getOrderDetails)

router.post('/cancelOrder', userController.cancelOrder)
router.post('/rateOrderAndKitchen', userController.rateOrderAndKitchen)

router.post('/startUserSupportChat', userController.startUserSupportChat)
router.get('/getUserSupportChatMessages', userController.getUserSupportChatMessages)

router.post('/deleteAccount', userController.deleteAccount)

// ========================================
// 💳 SAVED CARDS MANAGEMENT (SetupIntent Flow)
// ========================================
router.post('/createSetupIntent', userController.createSetupIntent) // Step 1: Create SetupIntent
router.post('/confirmSavedCard', userController.confirmSavedCard)   // Step 2: Confirm & Save Card
router.get('/getSavedCards', userController.getSavedCards)
router.delete('/deleteCard/:cardId', userController.deleteCard)
router.put('/setDefaultCard/:cardId', userController.setDefaultCard)

module.exports = router;


