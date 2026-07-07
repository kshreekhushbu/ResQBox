import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:resqbox_user/Models/cart_model.dart';
import 'package:resqbox_user/Models/order_success_model.dart';
import 'package:resqbox_user/Screens/MainSection/Cart/order_succes_screen.dart';
import 'package:resqbox_user/Services/apis.dart';
import 'package:resqbox_user/Services/dynamic_response.dart';
import 'package:resqbox_user/Utils/custom_loader.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/toast.dart';

class CartController extends ChangeNotifier {
  bool isLoading = false;
  CartModel? cartData;
  OrderSuccessModel? orderSuccessData;

  Future<void> placeOrderApi({
    required Map<String, dynamic> body,
  }) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.placeOrderApi}";
      debugPrint("placeOrder URL: $url");
      final response = await ApiService().postRequest(url, body);
      debugPrint("placeOrder response: $response");

      if (response != null && response["status"] == 1) {
        orderSuccessData = OrderSuccessModel.fromJson(response);

        // Check if payment is required
        final clientSecret = response["clientSecret"];
        final requiresPayment = response["requiresPayment"] == true;

        Loaders.hideLoadingDialog();

        if (requiresPayment &&
            clientSecret != null &&
            clientSecret.toString().isNotEmpty) {
          // Log the clientSecret for debugging (first part only for security)
          final secretPreview = clientSecret.toString().length > 30
              ? "${clientSecret.toString().substring(0, 30)}..."
              : clientSecret.toString();
          debugPrint("💳 ClientSecret received: $secretPreview");
          debugPrint("💳 Full clientSecret: ${clientSecret.toString()}");

          // Process Stripe payment
          await _processStripePayment(clientSecret.toString());
        } else {
          // No payment required, navigate directly to success screen
          NavigateTo().nextPage(
            child: OrderSuccesScreen(
              orderdata: orderSuccessData,
            ),
          );
        }
      } else {
        Loaders.hideLoadingDialog();
        customToast(
          message: response["message"] ?? "Failed to place order",
        );
      }
    } catch (e) {
      debugPrint("❌ Error placing order: $e");
      Loaders.hideLoadingDialog();
      customToast(message: "Failed to place order. Please try again.");
    }
  }

  Future<void> _processStripePayment(String clientSecret) async {
    try {
      // Validate clientSecret format
      if (clientSecret.isEmpty || !clientSecret.startsWith('pi_')) {
        debugPrint("❌ Invalid clientSecret format: $clientSecret");
        customToast(
          message:
              "Invalid payment information. Please try placing the order again.",
        );
        return;
      }

      // Extract payment intent ID from clientSecret for debugging
      // Format: pi_xxxxx_secret_yyyyy
      final parts = clientSecret.split('_secret_');
      final paymentIntentId = parts.isNotEmpty ? parts[0] : 'unknown';

      debugPrint("💳 Processing Stripe payment");
      debugPrint("💳 Payment Intent ID: $paymentIntentId");
      debugPrint("💳 ClientSecret length: ${clientSecret.length}");
      final publishableKey = Stripe.publishableKey;
      if (publishableKey.length > 7) {
        debugPrint(
            "💳 Current publishable key starts with: ${publishableKey.substring(0, 7)}");
      } else {
        debugPrint("💳 Publishable key too short");
      }

      // Show loading while initializing payment sheet
      Loaders.showLoadingDialog();

      try {
        // Initialize payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'ResQBox',
            style: ThemeMode.system,
          ),
        );
        debugPrint("✅ Payment sheet initialized successfully");
      } catch (initError) {
        Loaders.hideLoadingDialog();
        debugPrint("❌ Error during payment sheet initialization: $initError");
        throw initError; // Re-throw to be caught by outer catch
      }

      Loaders.hideLoadingDialog();

      // Present payment sheet with comprehensive error handling
      try {
        await Stripe.instance.presentPaymentSheet();

        // Payment successful
        debugPrint("✅ Payment successful");
        customToast(message: "Payment successful!");

        // Navigate to order success screen
        NavigateTo().nextPage(
          child: OrderSuccesScreen(
            orderdata: orderSuccessData,
          ),
        );
      } catch (presentError, stackTrace) {
        // Handle errors during payment sheet presentation
        debugPrint("❌ Error presenting payment sheet: $presentError");
        debugPrint("❌ Stack trace: $stackTrace");
        // Re-throw to be caught by StripeException handler below
        rethrow;
      }
    } on StripeException catch (e) {
      Loaders.hideLoadingDialog();
      debugPrint("❌ Stripe Exception Details:");
      debugPrint("   Code: ${e.error.code}");
      debugPrint("   Type: ${e.error.type}");
      debugPrint("   Message: ${e.error.message}");
      debugPrint("   Localized Message: ${e.error.localizedMessage}");
      debugPrint("   Decline Code: ${e.error.declineCode}");

      if (e.error.code == FailureCode.Canceled) {
        customToast(message: "Payment was cancelled");
      } else if (e.error.message
                  ?.toLowerCase()
                  .contains("no such payment_intent") ==
              true ||
          e.error.message?.toLowerCase().contains("payment_intent") == true ||
          e.error.type?.toString().contains("invalidRequestError") == true) {
        // Handle payment intent not found error
        debugPrint("❌ Payment intent issue detected");
        debugPrint("❌ Possible causes:");
        debugPrint(
            "   1. Payment intent created with different Stripe account");
        debugPrint("   2. Payment intent expired or was deleted");
        debugPrint("   3. Mismatch between test/live mode");
        debugPrint("   4. Backend using different Stripe secret key");
        customToast(
          message:
              "Payment session issue. Please verify Stripe account settings match between backend and app.",
        );
      } else {
        customToast(
          message: e.error.message ?? "Payment failed. Please try again.",
        );
      }
    } catch (e, stackTrace) {
      Loaders.hideLoadingDialog();
      debugPrint("❌ General error processing payment: $e");
      debugPrint("❌ Error type: ${e.runtimeType}");
      debugPrint("❌ Stack trace: $stackTrace");

      // Handle specific crash scenarios
      final errorString = e.toString().toLowerCase();
      if (errorString.contains("payment_intent") ||
          errorString.contains("no such")) {
        customToast(
          message: "Payment session expired. Please place the order again.",
        );
      } else {
        customToast(message: "Payment failed. Please try again.");
      }
    }
  }

  Future<void> initAddCardAndPlaceOrder(
      {required Map<String, dynamic> orderBody}) async {
    Loaders.showLoadingDialog();

    try {
      // 1. Create Setup Intent
      final url = "${Apis.baseUrl}${Apis.createPaymentIntentApi}";
      debugPrint("createSetupIntent URL: $url");
      final response = await ApiService().postRequest(url, {});
      debugPrint("createSetupIntent response: $response");

      if (response != null && response["status"] == 1) {
        final clientSecret = response['data']["clientSecret"];
        final customerId = response['data']["setupIntentId"] ??
            response['data']["setupIntentId"];

        if (clientSecret == null) {
          Loaders.hideLoadingDialog();
          customToast(message: "Failed to initialize card setup");
          return;
        }

        // 2. Initialize Payment Sheet for Setup Intent
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: clientSecret,
            merchantDisplayName: 'ResQBox Food',
            customerId: customerId,
            style: ThemeMode.system,
          ),
        );

        Loaders.hideLoadingDialog();

        // 3. Present Payment Sheet
        await Stripe.instance.presentPaymentSheet();

        // 4. Retrieve SetupIntent to get paymentMethodId
        final setupIntent =
            await Stripe.instance.retrieveSetupIntent(clientSecret);
        final paymentMethodId = setupIntent.paymentMethodId;

        debugPrint(
            "✅ SetupIntent confirmed, PaymentMethod ID: $paymentMethodId");

        // 5. Confirm to backend to save the card
        final saveUrl = "${Apis.baseUrl}${Apis.saveCardApi}";
        final saveBody = {
          "paymentMethodId": paymentMethodId,
          "setAsDefault": true,
        };

        debugPrint("confirmSavedCard URL: $saveUrl");
        final saveResponse = await ApiService().postRequest(saveUrl, saveBody);
        debugPrint("confirmSavedCard response: $saveResponse");

        if (saveResponse != null && saveResponse["status"] == 1) {
          // customToast(
          //     message: saveResponse["message"] ?? "Card saved successfully");

          // 6. Get the cardId from the saved card response
          int? newCardId;
          if (saveResponse["data"] != null &&
              saveResponse["data"]["cardId"] != null) {
            newCardId = saveResponse["data"]["cardId"];
          }

          // 7. Proceed to place order with the new cardId
          orderBody["paymentMethod"] = "CARD";
          if (newCardId != null) {
            orderBody["cardId"] = newCardId;
          }

          await placeOrderApi(body: orderBody);
        } else {
          Loaders.hideLoadingDialog();
          customToast(
              message:
                  saveResponse?["message"] ?? "Failed to confirm card saving");
        }
      } else {
        Loaders.hideLoadingDialog();
        customToast(
            message: response?["message"] ?? "Failed to initialize card setup");
      }
    } catch (e) {
      Loaders.hideLoadingDialog();
      debugPrint("❌ Error in add card and place order flow: $e");
      if (e is StripeException) {
        debugPrint("Stripe Error: ${e.error.localizedMessage}");
        if (e.error.code != FailureCode.Canceled) {
          customToast(message: e.error.localizedMessage ?? "Payment failed");
        }
      } else {
        customToast(message: "An unexpected error occurred");
      }
    }
  }

  Future<void> getCartApi() async {
    isLoading = true;
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.getCartApi}";
      debugPrint("getCart URL: $url");
      final response = await ApiService().getRequest(url);
      debugPrint("getCart data: $response");
      if (response != null && response["status"] == 1) {
        cartData = CartModel.fromJson(response);
      } else {
        cartData = null;
      }
    } catch (e) {
      cartData = null;
      debugPrint("❌ Error fetching cart data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCartApi({
    required int menuItemId,
    required int quantity,
  }) async {
    Loaders.showLoadingDialog();
    notifyListeners();

    try {
      final url = "${Apis.baseUrl}${Apis.addToCartApi}";
      debugPrint("addToCart URL: $url");
      final body = {
        "menuItemId": menuItemId,
        "quantity": quantity,
      };
      final response = await ApiService().postRequest(url, body);
      debugPrint("addToCart data: $response");
      if (response != null && response["status"] == 1) {
        customToast(
            message:
                response["message"] ?? 'Item updated in cart successfully');
        await getCartApi();
      } else {
        customToast(message: response?["message"] ?? 'Failed to update cart');
      }
    } catch (e) {
      debugPrint("❌ Error adding to cart: $e");
      customToast(message: 'Error adding item to cart');
    } finally {
      Loaders.hideLoadingDialog();
      notifyListeners();
    }
  }

  CartItem? findItem(int? menuItemId) {
    if (menuItemId == null) return null;
    final items = cartData?.cartItems ?? [];
    final match =
        items.where((element) => element.menuItemId == menuItemId).toList();
    return match.isNotEmpty ? match.first : null;
  }
}
