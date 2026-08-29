const express = require("express");
const auth = require("../utils/authentication");
const router = express.Router();
const userController = require("../controllers/userController");
const { upload } = require("../utils/upload");
const { authLimiter, uploadLimiter } = require("../utils/authLimiter");
const uploadImage = require("../controllers/imageUpload");

router.post("/upload", uploadLimiter, upload.single("file"), uploadImage.uploadImage);
router.post("/uploads", uploadLimiter, upload.array("files"), uploadImage.uploadMultipleImages);

router.post("/sendOtp", authLimiter, userController.sendOtp)
router.post("/verifyOtp", authLimiter, userController.verifyOtp)

router.post("/sendSignupOtp", authLimiter, userController.sendSignupOtp)
router.post("/signup", authLimiter, userController.signup)
router.post("/stripeWebhook", userController.stripeWebhook)

router.post("/googleLogin", authLimiter, userController.googleLogin)
router.post("/facebookLogin", authLimiter, userController.facebookLogin)
router.post("/appleLogin", authLimiter, userController.appleLogin)

router.use(auth.optionalAuthenticateUser)

router.get("/homePage", userController.homePage)
router.get("/getActiveRestaurants", userController.getActiveRestaurants)
router.get("/getPopularProducts", userController.getPopularProducts)

router.get("/getAllCategories", userController.getAllCategories)
router.get("/getFoodType", userController.getFoodType)
router.get("/getMenu", userController.getMenu)
router.get("/getMenuById/:id", userController.getMenuById)

router.get("/getAllKitchens", userController.getAllKitchens)
router.get("/kitchenSearch", userController.kitchenSearch)
router.get("/getKitchenDetailsById/:kitchenId", userController.getKitchenDetailsById)

router.get("/getConfig", userController.getConfig)
router.get("/getKitchenReviews/:kitchenId", userController.getKitchenReviews)

router.get("/getNotifications", userController.getNotifications)
router.get("/getCart", userController.getCart)
router.get("/getWishlist", userController.getWishlist)

router.use(auth.authenticateUser)

router.get("/getUserDetails", userController.getUserDetails)
router.post("/updateUserDetails", userController.updateUserDetails)

router.post("/addToWishlist", userController.addToWishlist)
router.post("/removeFromWishlist/:kitchenId", userController.removeFromWishlist)

router.post("/addToCart", userController.addToCart)
router.post("/removeCartItem/:id", userController.removeCartItem)
router.post("/clearCart", userController.clearCart)

router.post("/placeOrder", userController.placeOrder)
router.get("/getMyOrders", userController.getMyOrders)
router.get("/getOrderDetails/:orderId", userController.getOrderDetails)

router.post("/cancelOrder", userController.cancelOrder)
router.post("/rateOrderAndKitchen", userController.rateOrderAndKitchen)

router.post("/startUserSupportChat", userController.startUserSupportChat)
router.get("/getUserSupportChatMessages", userController.getUserSupportChatMessages)

router.post("/deleteAccount", userController.deleteAccount)

router.post("/createSetupIntent", userController.createSetupIntent)
router.post("/confirmSavedCard", userController.confirmSavedCard)
router.get("/getSavedCards", userController.getSavedCards)
router.delete("/deleteCard/:cardId", userController.deleteCard)
router.put("/setDefaultCard/:cardId", userController.setDefaultCard)

module.exports = router;
