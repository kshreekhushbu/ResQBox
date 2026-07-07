import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenProfileController.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class AddressEditScreen extends StatefulWidget {
  final String? prefilledHouseNo;
  final String? prefilledStreet;
  final String? prefilledCity;
  final String? prefilledState;
  final String? prefilledCountry;
  final String? prefilledLandmark;
  final String? prefilledPincode;
  final double? prefilledLatitude;
  final double? prefilledLongitude;

  const AddressEditScreen({
    super.key,
    this.prefilledHouseNo,
    this.prefilledStreet,
    this.prefilledCity,
    this.prefilledState,
    this.prefilledCountry,
    this.prefilledLandmark,
    this.prefilledPincode,
    this.prefilledLatitude,
    this.prefilledLongitude,
  });

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  final TextEditingController houseController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double? latitude;
  double? longitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    houseController.dispose();
    stateController.dispose();
    cityController.dispose();
    countryController.dispose();
    streetController.dispose();
    landmarkController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  void _loadCurrentData() {
    // If prefilled data is available (from map picker), use it
    if (widget.prefilledLatitude != null && widget.prefilledLongitude != null) {
      houseController.text = widget.prefilledHouseNo ?? '';
      streetController.text = widget.prefilledStreet ?? '';
      landmarkController.text = widget.prefilledLandmark ?? '';
      stateController.text = widget.prefilledState ?? '';
      cityController.text = widget.prefilledCity ?? '';
      countryController.text = widget.prefilledCountry ?? '';
      pincodeController.text = widget.prefilledPincode ?? '';
      latitude = widget.prefilledLatitude;
      longitude = widget.prefilledLongitude;
    } else {
      // Otherwise fallback to existing kitchen details
      final controller = Provider.of<KitchenProfileController>(
        context,
        listen: false,
      );
      final address = controller.kitchenDetails?.address;

      if (address != null) {
        houseController.text = address.houseNo ?? '';
        streetController.text = address.street ?? '';
        landmarkController.text = address.landmark ?? '';
        stateController.text = address.state ?? '';
        cityController.text = address.city ?? '';
        countryController.text = address.country ?? '';
        pincodeController.text = address.pincode ?? '';
        latitude = address.latitude;
        longitude = address.longitude;
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<KitchenProfileController>(
      context,
      listen: false,
    );

    final success = await controller.updateKitchen(
      houseNo: houseController.text.trim().isNotEmpty
          ? houseController.text.trim()
          : null,
      street: streetController.text.trim().isNotEmpty
          ? streetController.text.trim()
          : null,
      city: cityController.text.trim().isNotEmpty
          ? cityController.text.trim()
          : null,
      state: stateController.text.trim().isNotEmpty
          ? stateController.text.trim()
          : null,
      country: countryController.text.trim().isNotEmpty
          ? countryController.text.trim()
          : null,
      landmark: landmarkController.text.trim().isNotEmpty
          ? landmarkController.text.trim()
          : null,
      pincode: pincodeController.text.trim().isNotEmpty
          ? pincodeController.text.trim()
          : null,
      latitude: latitude,
      longitude: longitude,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      NavigateTo().backPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Edit Address',
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text("Unit", style: AppTextStyles.size16SemiBold),
                // SizedBox(height: 10),
                // CustomTextFormField(
                //   isfilled: true,
                //   controller: houseController,
                //   hintText: "Enter Unit",
                //   inputFormatters: [
                //     FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s]")),
                //   ],
                // ),
                // SizedBox(height: 20),
                Text("Street", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: streetController,
                  hintText: "Enter street",
                  isRequired: true,
                ),
                SizedBox(height: 20),
                Text("City", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: cityController,
                  hintText: "Enter city",
                  isRequired: true,
                ),
                SizedBox(height: 20),
                Text("State", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: stateController,
                  hintText: "Enter state",
                  isRequired: true,
                ),
                SizedBox(height: 20),
                Text("Country", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: countryController,
                  hintText: "Enter country",
                  isRequired: true,
                ),
                SizedBox(height: 20),
                // Text("Land mark", style: AppTextStyles.size16SemiBold),
                // SizedBox(height: 10),
                // CustomTextFormField(
                //   isfilled: true,
                //   controller: landmarkController,
                //   hintText: "Enter landmark",
                // ),
                // SizedBox(height: 20),
                Text("Pincode", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: pincodeController,
                  hintText: "Enter pincode",
                  isPincode: true,
                  isRequired: true,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: CustomRectBtn(
                width: MediaQuery.of(context).size.width * 0.45,
                onTap: () => NavigateTo().backPage(),
                height: 49,
                borderRadius: 25,
                leading: Center(
                  child: Text(
                    "Cancel",
                    style: AppTextStyles.size16SemiBold.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
                color: Colors.white,
                borderColor: const Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CustomRectBtn(
                onTap: _isLoading
                    ? () {}
                    : () {
                        _saveChanges();
                      },
                height: 49,
                width: MediaQuery.of(context).size.width * 0.45,
                borderRadius: 25,
                leading: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          "Save Changes",
                          style: AppTextStyles.size16SemiBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                color: const Color(0xffF1913D),
                borderColor: const Color(0xffF1913D),
                textColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
