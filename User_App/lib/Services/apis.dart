class Apis {
  static const String devUrl = 'https://xapi.resqboxfood.com/api/';
  static const String socketDevUrl = 'https://xapi.resqboxfood.com';

  static const String prodUrl = 'https://api.resqboxfood.com/api/';
  static const String socketProdUrl = 'https://api.resqboxfood.com';

  static String baseUrl = '';

  static String socketBaseUrl = '';

  static const String uploadImage = 'user/upload';

  static const String loginApi = 'user/sendOtp';

  static const String signUpVerifyOtpApi = 'user/sendSignupOtp';

  static const String verifyOtpApi = 'user/verifyOtp';

  static const String signupApi = 'user/signup';

  static const String profileApi = 'user/getUserDetails';

  static const String updateProfileApi = 'user/updateUserDetails';

  static const String homeApi = 'user/homePage';

  static const String tabsCategoriesApi = 'user/getAllCategories';

  static const String getMenuApi = 'user/getMenu';

  static const String orderApi = 'user/order';

  static const String addToCartApi = 'user/addToCart';

  static const String getCartApi = 'user/getCart';

  static const String placeOrderApi = 'user/placeOrder';

  static const String getAllRestaurantsApi = 'user/getAllKitchens';

  static const String addToWishlistApi = 'user/addToWishlist';

  static const String removeFromWishlistApi = 'user/removeFromWishlist';

  static const String getWishlistApi = 'user/getWishlist';

  static const String getNotificationsApi = 'user/getNotifications';

  static const String menuViewApi = 'user/getMenuById';

  static const String kitchenViewApi = 'user/getKitchenDetailsById';

  static const String myOrdersApi = 'user/getMyOrders';

  static const String myOrdersByIdApi = 'user/getOrderDetails';

  static const String submitRatingApi = 'user/rateOrderAndKitchen';

  static const String kitchenReviewsApi = 'user/getKitchenReviews';

  static const String activeRestaurantsApi = 'user/getActiveRestaurants';

  static const String popularRestaurantsApi = 'user/getPopularProducts';

  static const String sendSupportMessageApi = 'user/getUserSupportChatMessages';

  static const String sendSupport = 'user/startUserSupportChat';

  static const String searchApi = 'user/kitchenSearch';

  static const String deleteAccountApi = 'user/deleteAccount';

  static const String googleLoginApi = "user/googleLogin";

  static const String facebookLoginApi = "user/facebookLogin";

  static const String appleLoginApi = "user/appleLogin";

  static const String createPaymentIntentApi = "user/createSetupIntent";

  static const String saveCardApi = "user/confirmSavedCard";

  static const String getSavedCardsApi = "user/getSavedCards";

  static const String deleteSavedCardApi = "user/deleteCard"; //card id

  static const String getSupportDetailsApi = "user/getConfig";

  static const String getFoodTypeApi = "user/getFoodType";
}

void isEnvironment({
  Environment environment = Environment.prod,
}) {
  if (environment == Environment.prod) {
    Apis.baseUrl = Apis.prodUrl;
    Apis.socketBaseUrl = Apis.socketProdUrl;
  } else {
    Apis.baseUrl = Apis.devUrl;
    Apis.socketBaseUrl = Apis.socketDevUrl;
  }
}

enum Environment { dev, uat, prod }
