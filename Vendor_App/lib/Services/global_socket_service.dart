import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Services/kitchen_socket.dart';

class GlobalSocketService {
  static final GlobalSocketService _instance = GlobalSocketService._internal();
  factory GlobalSocketService() => _instance;
  GlobalSocketService._internal();

  KitchenSocket? _socket;
  int? _currentKitchenId;
  bool _isInitialized = false;
  Function()? _onNewOrderCallback;

  void setOnNewOrderCallback(Function()? callback) {
    _onNewOrderCallback = callback;
  }

  // Initialize socket service (call this after login/kitchen details loaded)
  void initialize(BuildContext? context) {
    if (_isInitialized && _socket != null && _socket!.isConnected) {
      debugPrint("🔌 Socket already initialized and connected");
      return;
    }

    if (context == null) {
      debugPrint("⚠️ Cannot initialize socket: context is null");
      return;
    }

    final kitchenController = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    final kitchenId = kitchenController.kitchenDetails?.kitchenId;

    // Connect if:
    // 1. Kitchen ID changed
    // 2. Kitchen ID is same, but socket is null or disconnected
    if (kitchenId != null &&
        (kitchenId != _currentKitchenId ||
            _socket == null ||
            !_socket!.isConnected)) {
      // Disconnect old socket if exists
      _socket?.disconnect();

      // Create new socket connection
      _socket = KitchenSocket();
      _socket!.connect(kitchenId);
      _currentKitchenId = kitchenId;
      _isInitialized = true;

      // Listen for new orders
      _socket!.onNewOrder((data) {
        debugPrint("📦 New order received via socket (Global): $data");
        // Call the registered callback to refresh orders
        if (_onNewOrderCallback != null) {
          try {
            _onNewOrderCallback!();
          } catch (e) {
            debugPrint("⚠️ Error in new order callback: $e");
          }
        }
      });

      // Listen for stripe onboarding completed
      _socket!.onStripeOnboardingCompleted((data) {
        debugPrint("✅ Stripe onboarding completed (Global)");
        // Refresh kitchen details to update UI/Status
        kitchenController.getKitchenDetails();
      });

      debugPrint("✅ Global socket service initialized for kitchen: $kitchenId");
    } else if (kitchenId == null) {
      // Try to load kitchen details first
      kitchenController.getKitchenDetails().then((_) {
        final newKitchenId = kitchenController.kitchenDetails?.kitchenId;
        if (newKitchenId != null && context.mounted) {
          initialize(context); // Retry initialization
        }
      });
    }
  }

  // Reinitialize when kitchen details are loaded
  void reinitialize(BuildContext? context) {
    _isInitialized = false;
    _currentKitchenId = null;
    initialize(context);
  }

  // Get socket instance
  KitchenSocket? get socket => _socket;

  // Check if connected
  bool get isConnected => _socket?.isConnected ?? false;

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _currentKitchenId = null;
    _isInitialized = false;
    debugPrint("🔌 Global socket service disconnected");
  }
}
