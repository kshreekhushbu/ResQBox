import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Controller/OrdersController.dart';
import 'package:resqboxvendor/Models/order_model.dart';
import 'package:resqboxvendor/Screens/Menu/add_menu.dart';
import 'package:resqboxvendor/Screens/Notifications/notification_screen.dart';
import 'package:resqboxvendor/Controller/NotificationController.dart';
import 'package:resqboxvendor/Screens/Orders/new_order_detail_view.dart';
import 'package:resqboxvendor/Services/global_socket_service.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_switch_android.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/stripe_onboarding_dialog.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:resqboxvendor/utils/colors.dart';
import 'package:resqboxvendor/Utils/string_extensions.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _buttonLoaders = {};

  bool _isDialogShowing = false;
  KitchenProfileController? _kitchenController;
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadOrders();
    _initializeSocket();

    // Defer loading to allow context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKitchenDetails();

      // Add listener to controller to react to changes globally
      final kitchenController = Provider.of<KitchenProfileController>(
        context,
        listen: false,
      );
      kitchenController.addListener(_onKitchenDetailsChanged);

      // Fetch notifications
      Provider.of<NotificationController>(
        context,
        listen: false,
      ).getNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kitchenController = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
  }

  @override
  void dispose() {
    _kitchenController?.removeListener(_onKitchenDetailsChanged);

    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onKitchenDetailsChanged() {
    if (mounted) {
      _checkStripeStatus();
    }
  }

  void _loadKitchenDetails() async {
    final kitchenController = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );
    // Always fetch latest details
    await kitchenController.getKitchenDetails();
    // _checkStripeStatus called by listener triggers automatically after getKitchenDetails notifies
  }

  void _checkStripeStatus() {
    final kitchenController = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    if (kitchenController.kitchenDetails != null) {
      bool isCompleted =
          kitchenController.kitchenDetails?.stripeOnboardingCompleted ?? false;
      bool isConnected =
          kitchenController.kitchenDetails?.stripeAccountConnected ?? false;
      String? onboardingUrl =
          kitchenController.kitchenDetails?.stripeOnboardingUrl;

      // If completed, ensure dialog is closed
      if (isCompleted) {
        if (_isDialogShowing) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogShowing = false;
        }
        return;
      }

      // If we need to show dialog and it's NOT showing
      if (mounted && !isCompleted && !_isDialogShowing) {
        _showStripeOnboardingDialog(
          isPending: isConnected && (onboardingUrl == null),
          hasUrl: isConnected && (onboardingUrl != null),
        );
      }
    }
  }

  void _showStripeOnboardingDialog({
    bool isPending = false,
    bool hasUrl = false,
  }) {
    if (_isDialogShowing) return;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<KitchenProfileController>(
          builder: (context, controller, child) {
            final details = controller.kitchenDetails;
            final bool completed = details?.stripeOnboardingCompleted ?? false;
            final bool connected = details?.stripeAccountConnected ?? false;

            if (completed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
            }

            // For embedded flow, "Continue" or "Complete Onboarding" opens the WebView.
            final bool dynamicHasUrl = connected && !completed;
            final bool dynamicIsPending = false;

            return StripeOnboardingDialog(
              isPending: dynamicIsPending,
              hasUrl: dynamicHasUrl,
              isLoading: controller.isStripeLoading,
              onContinue: () async {
                final kitchenController = Provider.of<KitchenProfileController>(
                  context,
                  listen: false,
                );

                // Always start fresh session for embedded onboarding
                await kitchenController.startStripeOnboarding();
              },
            );
          },
        );
      },
    ).then((result) async {
      // Dialog closed
      _isDialogShowing = false;

      if (result == "logout") {
        // User logged out from dialog
        final prefernce = await SharedPreferencesHelper();
        await prefernce.clearAlldata();
        if (mounted) {
          NavigateTo().pushRemove(child: LoginScreen());
        }
        return;
      }

      if (mounted) {
        _checkStripeStatus();
      }
    });
  }

  void _initializeSocket() {
    GlobalSocketService().initialize(context);
    // Set callback to refresh orders when new order arrives via socket
    GlobalSocketService().setOnNewOrderCallback(() {
      if (mounted) {
        _refreshAllOrders();
      }
    });
  }

  void _refreshAllOrders() {
    final controller = Provider.of<OrdersController>(context, listen: false);
    controller.getKitchenOrders(1);
    controller.getKitchenOrders(2);
    controller.getKitchenOrders(3);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    final controller = Provider.of<OrdersController>(context, listen: false);
    final currentIndex = _tabController.index;
    switch (currentIndex) {
      case 0:
        controller.getKitchenOrders(1);
        break;
      case 1:
        controller.getKitchenOrders(2);
        break;
      case 2:
        String? formattedDate;
        if (_selectedDate != null) {
          formattedDate =
              "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
        }
        controller.getKitchenOrders(
          3,
          date: formattedDate,
          search: _searchController.text.trim(), // Use search controller text
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F8),
      body: Consumer<KitchenProfileController>(
        builder: (context, controller, child) {
          return SafeArea(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    color: Color(0xffEB7712),
                                    child: controller.isLoadingKitchenDetails
                                        ? Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                          )
                                        : (controller
                                                      .kitchenDetails
                                                      ?.photos
                                                      ?.kitchenProfilePhoto !=
                                                  null &&
                                              controller
                                                  .kitchenDetails!
                                                  .photos!
                                                  .kitchenProfilePhoto!
                                                  .isNotEmpty)
                                        ? Image.network(
                                            controller
                                                .kitchenDetails!
                                                .photos!
                                                .kitchenProfilePhoto!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      (controller
                                                                  .kitchenDetails
                                                                  ?.kitchenName ??
                                                              "N/A")
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Center(
                                            child: Text(
                                              (controller
                                                          .kitchenDetails
                                                          ?.kitchenName ??
                                                      "N/A")
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // NAME + VERIFIED
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    controller.isLoadingKitchenDetails
                                        ? Container(
                                            width: 100,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          )
                                        : Text(
                                            controller
                                                    .kitchenDetails
                                                    ?.kitchenName ??
                                                "N/A",
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.size16SemiBold,
                                          ),

                                    const SizedBox(height: 4),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffD5FFE2),
                                        border: Border.all(
                                          color: AppColors.mainAppColr,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: Color(0xff14B044),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Verified",
                                            style: AppTextStyles.size10Regular
                                                .copyWith(
                                                  color: Color(0xff14B044),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // 🔔 NOTIFICATION BELL WITH ORANGE DOT
                            Consumer<NotificationController>(
                              builder:
                                  (context, notificationController, child) {
                                    bool hasUnread = notificationController
                                        .hasUnreadNotifications;
                                    return GestureDetector(
                                      onTap: () {
                                        NavigateTo().nextPage(
                                          child: NotificationScreen(),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: SvgPicture.asset(
                                          hasUnread
                                              ? AppImages.notiifcation
                                              : AppImages.nonReadNotification,
                                          width: 28,
                                          height: 28,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        dividerColor: Colors.white,
                        controller: _tabController,
                        labelColor: Colors.black,
                        unselectedLabelColor: Color(0xff7A7A7A),
                        labelStyle: AppTextStyles.size16SemiBold,
                        unselectedLabelStyle: AppTextStyles.size14Medium,
                        indicatorColor: Color(0xffEB7712),
                        indicatorWeight: 2,
                        tabs: const [
                          Tab(text: 'New'),
                          Tab(text: 'Ongoing'),
                          Tab(text: 'Past'),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(),
                      _onGoingCard(),
                      _buildPastOrdersList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrdersController>(
      builder: (context, controller, child) {
        if (controller.isLoadingNewOrders) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.newOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(AppImages.noMenuImage),
                  SizedBox(height: 20),
                  Text("No Orders Yet", style: AppTextStyles.size20SemiBold),
                  SizedBox(height: 20),
                  Text(
                    "No new orders yet. Once customers start ordering, they’ll appear here!",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.size14Medium.copyWith(
                      color: Color(0xff777777),
                    ),
                  ),
                  SizedBox(height: 20),
                  CustomRectBtn(
                    width: MediaQuery.of(context).size.width * 0.45,
                    onTap: () {
                      NavigateTo().nextPage(child: AddMenu());
                    },
                    height: 49,
                    borderRadius: 8,
                    leading: Center(
                      child: Text(
                        "Add ResQBoxes",
                        style: AppTextStyles.size16SemiBold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    color: Color(0xffEB7712),
                    borderColor: const Color(0xffEB7712),
                    textColor: Colors.black,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: Color(0xffF5F5F5),
          child: RefreshIndicator(
            onRefresh: () => controller.getKitchenOrders(1),
            color: AppColors.mainAppColr,
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: controller.newOrders.length,
              itemBuilder: (context, index) {
                final order = controller.newOrders[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < controller.newOrders.length - 1 ? 8 : 0,
                  ),
                  child: _buildOrderCard(order: order),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _onGoingCard() {
    return Consumer<OrdersController>(
      builder: (context, controller, child) {
        if (controller.isLoadingOngoingOrders) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.ongoingOrders.isEmpty) {
          return Center(
            child: Text(
              'No Ongoing Orders',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return Container(
          color: Color(0xffF5F5F5),
          child: RefreshIndicator(
            onRefresh: () => controller.getKitchenOrders(2),
            color: AppColors.mainAppColr,
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: controller.ongoingOrders.length,
              itemBuilder: (context, index) {
                final order = controller.ongoingOrders[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: _buildOngoingOrderCard(order: order),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPastOrdersList() {
    return Column(
      children: [
        // Date Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Search Field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xffD5D5D5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    // textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: "Search Orders...",
                      hintStyle: AppTextStyles.size14Medium.copyWith(
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      // contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      contentPadding: EdgeInsets.zero,
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _searchController.clear();
                              _loadOrders();
                            },
                          );
                        },
                      ),
                    ),
                    onSubmitted: (value) => _loadOrders(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.mainAppColr,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                    _loadOrders();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xffD5D5D5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate == null
                            ? "Filter Date"
                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: AppTextStyles.size14Medium,
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = null;
                            });
                            _loadOrders();
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<OrdersController>(
            builder: (context, controller, child) {
              if (controller.isLoadingPastOrders) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.pastOrders.isEmpty) {
                return Center(
                  child: Text(
                    'No Past Orders',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              return Container(
                color: Color(0xffF5F5F5),
                child: RefreshIndicator(
                  onRefresh: () {
                    String? formattedDate;
                    if (_selectedDate != null) {
                      formattedDate =
                          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
                    }
                    return controller.getKitchenOrders(
                      3,
                      date: formattedDate,
                      search: _searchController.text.trim(),
                    );
                  },
                  color: AppColors.mainAppColr,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: controller.pastOrders.length,
                    itemBuilder: (context, index) {
                      final order = controller.pastOrders[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < controller.pastOrders.length - 1
                              ? 8
                              : 0,
                        ),
                        child: _buildOrderCard(
                          order: order,
                          showActions: false,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.size14Regular.copyWith(color: Colors.black),
          ),
        ),
        // Switch(
        //   value: value,
        //   onChanged: onChanged,
        //   activeColor: AppColors.green,
        //   activeTrackColor: AppColors.green.withOpacity(0.4),
        //   inactiveThumbColor: Colors.white,
        //   inactiveTrackColor: Colors.grey.shade400,
        //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // ),
        CustomThumbSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xff00D341),
          trackColor: Color(0xff30B435).withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    width: double.infinity,
    height: 1,
    color: const Color(0xffE2E2E2),
  );

  Widget _buildOrderCard({required Order order, bool showActions = true}) {
    final controller = Provider.of<OrdersController>(context, listen: false);
    final itemsText = _getItemsText(order);

    return GestureDetector(
      onTap: () {
        controller.getOrderDetailsById(order.orderId ?? 0);
        NavigateTo().nextPage(
          child: NewOrderDetailView(orderId: order.orderId ?? 0),
        );
      },
      child: Container(
        // padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.getStatusDisplayText(order.status),
                    style: AppTextStyles.size16Medium.copyWith(
                      color: _getStatusColor(order.status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Order Number and Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${order.orderDisplayId}",
                        style: AppTextStyles.size14Regular,
                      ),
                      Text(
                        '${controller.formatTime(order.orderedAt)}  ${controller.formatDate(order.orderedAt)}',
                        style: AppTextStyles.size12Regular.copyWith(
                          color: Color(0xff727272),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          itemsText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: AppTextStyles.size12Medium.copyWith(
                            color: Color(0xff727272),
                          ),
                        ),
                      ),
                      Text(
                        "\$ ${order.itemTotal?.toStringAsFixed(2) ?? '0.00'}",
                        style: AppTextStyles.size14Medium,
                      ),
                    ],
                  ),
                  // const SizedBox(height: 12),
                ],
              ),
            ),
            if (showActions) ...[
              // SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: Color(0xffD5D5D5),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      flex: 2,
                      child: CustomRectBtn(
                        color: AppColors.tWhiteColor,
                        borderColor: AppColors.mainAppColr,
                        height: 38,
                        width: MediaQuery.of(context).size.width / 5,
                        text:
                            (_buttonLoaders['${order.orderId}_reject'] ?? false)
                            ? ""
                            : "Reject",
                        leading:
                            (_buttonLoaders['${order.orderId}_reject'] ?? false)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.mainAppColr,
                                ),
                              )
                            : null,
                        onTap: () async {
                          if (_buttonLoaders['${order.orderId}_reject'] ??
                              false) {
                            return;
                          }
                          setState(() {
                            _buttonLoaders['${order.orderId}_reject'] = true;
                          });
                          await controller.rejectOrder(order.orderId ?? 0);
                          if (mounted) {
                            setState(() {
                              _buttonLoaders['${order.orderId}_reject'] = false;
                            });
                          }
                        },
                        textColor: AppColors.mainAppColr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 3,
                      child: CustomRectBtn(
                        color: Color(0xff00D341),
                        borderColor: Color(0xff00D341),
                        height: 38,
                        width: MediaQuery.of(context).size.width / 2.9,
                        text:
                            (_buttonLoaders['${order.orderId}_accept'] ?? false)
                            ? ""
                            : "Accept Order",
                        leading:
                            (_buttonLoaders['${order.orderId}_accept'] ?? false)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.tWhiteColor,
                                ),
                              )
                            : null,
                        onTap: () async {
                          if (_buttonLoaders['${order.orderId}_accept'] ??
                              false) {
                            return;
                          }
                          setState(() {
                            _buttonLoaders['${order.orderId}_accept'] = true;
                          });
                          await controller.acceptOrder(order.orderId ?? 0);
                          if (mounted) {
                            setState(() {
                              _buttonLoaders['${order.orderId}_accept'] = false;
                            });
                          }
                        },
                        textColor: AppColors.tWhiteColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingOrderCard({required Order order}) {
    final controller = Provider.of<OrdersController>(context, listen: false);
    final itemsText = _getItemsText(order);

    return Container(
      // padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.getStatusDisplayText(order.status),
                      style: AppTextStyles.size16Medium.copyWith(
                        color: AppColors.mainAppColr,
                      ),
                    ),
                    // Icon(Icons.more_horiz_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${order.orderDisplayId}",
                      style: AppTextStyles.size14Regular,
                    ),
                    Text(
                      controller.formatDate(order.orderedAt),
                      style: AppTextStyles.size12Regular.copyWith(
                        color: Color(0xff727272),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.formatTime(order.orderedAt),
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.size12Medium.copyWith(
                        color: Color(0xff727272),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Container(
                        color: Color(0xff707070),
                        height: 25,
                        width: 1,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        itemsText,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size12Medium.copyWith(
                          color: Color(0xff727272),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Container(
                        color: Color(0xff707070),
                        height: 25,
                        width: 1,
                      ),
                    ),
                    Text(
                      "\$ ${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.size12Medium.copyWith(
                        color: Color(0xff727272),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Color(0xffD5D5D5),
          ),
          // SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup ID",
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size12Medium.copyWith(
                          color: Color(0xff727272),
                        ),
                      ),
                      // Sized
                      Text(
                        order.pickupId ?? "N/A",
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14Medium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // CustomRectBtn(
                //   width: MediaQuery.of(context).size.width / 5,
                //   color: AppColors.tWhiteColor,
                //   borderColor: AppColors.mainAppColr,
                //   height: 38,
                //   leading: (_buttonLoaders['${order.orderId}_cancel'] ?? false)
                //       ? const SizedBox(
                //           height: 20,
                //           width: 20,
                //           child: CircularProgressIndicator(
                //             strokeWidth: 2,
                //             color: AppColors.mainAppColr,
                //           ),
                //         )
                //       : Text(
                //           "Cancel",
                //           style: AppTextStyles.size14SemiBold.copyWith(
                //             color: AppColors.mainAppColr,
                //           ),
                //         ),
                //   onTap: () async {
                //     if (_buttonLoaders['${order.orderId}_cancel'] ?? false) {
                //       return;
                //     }
                //     setState(() {
                //       _buttonLoaders['${order.orderId}_cancel'] = true;
                //     });
                //     await controller.cancelOrder(order.orderId ?? 0);
                //     if (mounted) {
                //       setState(() {
                //         _buttonLoaders['${order.orderId}_cancel'] = false;
                //       });
                //     }
                //   },
                //   textColor: AppColors.mainAppColr,
                // ),
                const SizedBox(width: 12),

                CustomRectBtn(
                  width: MediaQuery.of(context).size.width / 2.9,
                  color: const Color(0xff00D341),
                  borderColor: const Color(0xff00D341),
                  height: 38,
                  text: "Update Status",
                  textColor: AppColors.tWhiteColor,
                  onTap: () {
                    _showStatusUpdateModal(context, order);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateModal(BuildContext context, Order order) {
    final controller = Provider.of<OrdersController>(context, listen: false);
    final currentStatus = order.status?.toUpperCase() ?? "";

    bool isPreparing =
        currentStatus == "PREPARING" ||
        currentStatus == "READY" ||
        currentStatus == "PICKED" ||
        currentStatus == "NO_SHOW";

    bool isReady =
        currentStatus == "READY" ||
        currentStatus == "PICKED" ||
        currentStatus == "NO_SHOW";

    bool isComplete = currentStatus == "PICKED" || currentStatus == "NO_SHOW";

    bool isCustomerPicked = currentStatus == "PICKED";
    bool isCustomerNoShow = currentStatus == "NO_SHOW";
    bool isUpdatingStatus = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.getStatusDisplayText(order.status),
                            style: AppTextStyles.size16Medium.copyWith(
                              color: AppColors.mainAppColr,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                controller.formatTime(order.orderedAt),
                                style: AppTextStyles.size12Regular.copyWith(
                                  color: const Color(0xff727272),
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "#${order.orderDisplayId}",
                                style: AppTextStyles.size14Regular,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Item Details",
                                style: AppTextStyles.size12Medium.copyWith(
                                  color: const Color(0xff727272),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pickup ID",
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.size12Medium.copyWith(
                                  color: Color(0xff727272),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                order.pickupId ?? "N/A",
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: const Color(0xffD5D5D5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Update Status",
                        style: AppTextStyles.size16Medium.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusTile(
                        title: "Preparing",
                        value: isPreparing,
                        onChanged: (val) {
                          if (val) {
                            setState(() {
                              isPreparing = true;
                              isReady = false;
                              isComplete = false;
                              isCustomerPicked = false;
                              isCustomerNoShow = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _divider(),
                      const SizedBox(height: 12),

                      _buildStatusTile(
                        title: "Ready For Pickup",
                        value: isReady,
                        onChanged: (val) {
                          if (val) {
                            setState(() {
                              // When setting READY, PREPARING is automatically completed
                              isPreparing = true;
                              isReady = true;
                              isComplete = false;
                              isCustomerPicked = false;
                              isCustomerNoShow = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      _divider(),
                      const SizedBox(height: 12),

                      _buildStatusTile(
                        title: "Complete",
                        value: isComplete,
                        onChanged: (val) {
                          if (val) {
                            setState(() {
                              isPreparing = true;
                              isReady = true;
                              isComplete = true;
                            });
                          } else {
                            setState(() {
                              isComplete = false;
                              isCustomerPicked = false;
                              isCustomerNoShow = false;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Customer Status - Only enabled when Complete is selected
                      Opacity(
                        opacity: isComplete ? 1.0 : 0.5,
                        child: IgnorePointer(
                          ignoring: !isComplete,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Customer Status",
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: isCustomerPicked,
                                        onChanged: isComplete
                                            ? (val) {
                                                setState(() {
                                                  isCustomerPicked = true;
                                                  isCustomerNoShow = false;
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        "Customer Picked Up",
                                        style: AppTextStyles.size12Regular,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: isCustomerNoShow,
                                        onChanged: isComplete
                                            ? (val) {
                                                setState(() {
                                                  isCustomerPicked = false;
                                                  isCustomerNoShow = true;
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        "Customer No Show",
                                        style: AppTextStyles.size12Regular,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      CustomRectBtn(
                        width: MediaQuery.of(context).size.width,
                        onTap: () async {
                          if (isUpdatingStatus) return;

                          OrderStatus statusToUpdate;

                          if (isComplete) {
                            if (!isCustomerPicked && !isCustomerNoShow) {
                              customToast(
                                message: "Please select customer status",
                              );
                              return;
                            }
                            statusToUpdate = isCustomerPicked
                                ? OrderStatus.picked
                                : OrderStatus.noShow;
                          } else if (isReady) {
                            statusToUpdate = OrderStatus.ready;
                          } else if (isPreparing) {
                            statusToUpdate = OrderStatus.preparing;
                          } else {
                            customToast(message: "Please select a status");
                            return;
                          }

                          setState(() {
                            isUpdatingStatus = true;
                          });

                          // final success = await
                          await controller.updateOrderStatus(
                            order.orderId ?? 0,
                            statusToUpdate,
                          );
                          // if (success && context.mounted) {
                          if (context.mounted) {
                            setState(() {
                              isUpdatingStatus = false;
                            });
                            Navigator.pop(context);
                          }
                          // }
                        },
                        height: 49,
                        borderRadius: 8,
                        leading: isUpdatingStatus
                            ? Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  "Update Status",
                                  style: AppTextStyles.size16SemiBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                        color: Color(0xff00D341),
                        borderColor: Color(0xff00D341),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getItemsText(Order order) {
    if (order.items == null || order.items!.isEmpty) {
      return "No items";
    }
    if (order.items!.length == 1) {
      final item = order.items!.first;
      return (item.menu?.name ?? "Item").toTitleCase();
    }
    final firstItem = order.items!.first;
    final remainingCount = order.items!.length - 1;
    return "${(firstItem.menu?.name ?? "Item").toTitleCase()} , + $remainingCount Items";
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColors.mainAppColr;
    switch (status.toUpperCase()) {
      case "PENDING":
        return AppColors.mainAppColr; // Orange (Default)
      case "ACCEPTED":
        return Colors.blue;
      case "PREPARING":
        return Colors.orangeAccent;
      case "READY":
        return Color(0xff14B044); // Green
      case "PICKED":
        return Color(0xff00802b); // Darker Green
      case "NO_SHOW":
        return AppColors.mainAppColr;
      case "CANCELLED":
        return Colors.red;
      case "REJECTED":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
