class AppUrls {
  // ---------------- AUTH ----------------
  static String loginKitchen = "vendor/loginKitchen";
  static String getConfig = "vendor/getConfig";
  static String checkEmailExists = "vendor/checkEmailExists";
  static String sendForgotPasswordOTP = "vendor/sendForgotPasswordOTP";
  static String verifyForgotPasswordOTP = "vendor/verifyForgotPasswordOTP";
  static String resetPassword = "vendor/resetPassword";
  static String changePassword = "vendor/changePassword";
  static String resetOldPassword = "vendor/resetOldPassword";
  static String logoutKitchen = "vendor/logoutKitchen";

  // ---------------- KITCHEN ----------------
  static String registerKitchen = "vendor/registerKitchen";
  static String getKitchenStatus = "vendor/getKitchenStatus";
  static String getKitchenDetails = "vendor/getKitchenDetails";

  // ---------------- MENU ITEMS ----------------
  static String addMenuItem = "vendor/addMenuItem";
  static String getAllMenuItems = "vendor/getAllMenuItems";
  static String getMenuItemById = "vendor/getMenuItemById"; // append /:id
  static String updateMenuItem = "vendor/updateMenuItem"; // append /:id
  static String deleteMenuItem = "vendor/deleteMenuItem"; // append /:id
  static String activateMenuItem =
      "vendor/inactivateMenuItem"; // append /:id?isActive=<0|1>
  static String getCategories = "vendor/getCategories";
  static String getCuisines = "vendor/getCuisines";
  static String getFoodTypes = "vendor/getFoodTypes";
  static String getMenuTypes = "vendor/getMenuTypes";
  static String validateOfferPrice = "vendor/validateOfferPrice";
  static String getActiveTimezones = "vendor/getActiveTimezones";

  // ---------------- KITCHEN ACTIVE STATUS ----------------
  static String updateKitchenActiveStatus = "vendor/updateKitchenActiveStatus";
  // add ?isActive=<0|1>
  static String updateKitchen = "vendor/updateKitchen";
  static String updateNotificationTime = "vendor/updateNotificationTime";

  // ---------------- ORDERS ----------------
  static String getKitchenOrders = "vendor/getKitchenOrders";
  // add ?type=<1|2|3>
  static String getKitchenOrderById =
      "vendor/getKitchenOrderById"; // append /:orderId
  static String acceptOrder = "vendor/acceptOrder"; // append /:orderId
  static String rejectOrder = "vendor/rejectOrder"; // append /:orderId
  static String updateOrderStatus =
      "vendor/updateOrderStatus"; // append /:orderId

  // ---------------- TEAM ----------------
  static String addTeamMember = "vendor/addTeamMember";
  static String getTeamMembers = "vendor/getTeamMembers";
  static String getTeamMemberById = "vendor/getTeamMemberById";
  static String updateTeamMember = "vendor/updateTeamMember";
  static String deleteTeamMember = "vendor/deleteTeamMember";

  // ---------------- STRIPE ----------------
  static String stripeOAuthStart = "stripe/oauth/start"; // append /:kitchenId
  static String createStripeAccount = "stripe/create-stripe-account";
  static String createAccountSession = "stripe/create-account-session";

  // ---------------- REAPPLY ----------------
  static String reapplyKitchen = "vendor/reapplyKitchen";

  // ---------------- SUPPORT CHAT ----------------
  static String getKitchenSupportChatMessages =
      "vendor/getKitchenSupportChatMessages";
  static String startKitchenSupportChat = "vendor/startKitchenSupportChat";

  // ---------------- DASHBOARD ----------------
  static String getKitchenDashboard = "vendor/getKitchenDashboard";
  // add ?type=<today|week|month>

  // ---------------- DOCUMENTS ----------------
  static String getFoodCertificates = "vendor/getFoodCertificates";
  static String addFoodCertificate = "vendor/addFoodCertificate";

  // ---------------- TRANSACTIONS ----------------
  static String getAllTransactions = "vendor/getAllTransactions";
  // add ?download=pdf for PDF download

  // ---------------- INVOICES ----------------
  static String getPayoutInvoices = "vendor/getPayoutInvoices";
  static String getPayoutInvoiceDetails = "vendor/getPayoutInvoiceDetails";
  static String getNotifications = "vendor/getNotifications";
  static String getMonthlyInvoices = "vendor/getMonthlyInvoices";
  static String getMonthlyInvoiceDetails = "vendor/getMonthlyInvoiceDetails";
}
