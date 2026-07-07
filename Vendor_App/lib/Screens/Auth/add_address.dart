import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:resqboxvendor/Controller/KitchenRegistrationController.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';

class AddAddressScreen extends StatefulWidget {
  final String locationName;
  final String area;
  final double latitude;
  final double longitude;
  final String? pincode;
  final String? landmark;
  final String? street;
  final String? locality;
  final String? subLocality;
  final String? administrativeArea;
  final String? country;

  const AddAddressScreen({
    required this.locationName,
    required this.area,
    required this.latitude,
    required this.longitude,
    this.pincode,
    this.landmark,
    this.street,
    this.locality,
    this.subLocality,
    this.administrativeArea,
    this.country,
  });

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Added Form Key
  // final TextEditingController houseController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  // final TextEditingController landmarkController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fill fields from location data
    if (widget.street != null && widget.street!.isNotEmpty) {
      streetController.text = widget.street!;
    }
    if (widget.locality != null && widget.locality!.isNotEmpty) {
      cityController.text = widget.locality!;
    }
    if (widget.administrativeArea != null &&
        widget.administrativeArea!.isNotEmpty) {
      stateController.text = widget.administrativeArea!;
    }
    if (widget.country != null && widget.country!.isNotEmpty) {
      countryController.text = widget.country!;
    } else {
      countryController.text = "Australia"; // Default country
    }
    if (widget.pincode != null && widget.pincode!.isNotEmpty) {
      pincodeController.text = widget.pincode!;
    }
  }

  void _addAddress() {
    if (_formKey.currentState!.validate()) {
      // Check form validation
      final controller = Provider.of<KitchenRegistrationController>(
        context,
        listen: false,
      );

      // Set address details in controller
      controller.setAddressDetails(
        houseNo: '',
        street: streetController.text.trim(),
        // landmark: landmarkController.text.trim(),
        pincode: pincodeController.text.trim(),
        state: stateController.text.trim(),
        city: cityController.text.trim(),
        country: countryController.text.trim(),
        latitude: widget.latitude,
        longitude: widget.longitude,
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Add Address',
        isLeading: true,
        backTap: () {
          NavigateTo().backPage();
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Form(
            // Wrapped in Form
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text("Unit", style: AppTextStyles.size16SemiBold),
                // SizedBox(height: 10),
                // CustomTextFormField(
                //   isfilled: true,
                //   controller:  ,
                //   hintText: "Enter Unit",
                //   isRequired: true, // Made Mandatory
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
                  isRequired: true, // Made Mandatory
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
                  isRequired: true, // Made Mandatory
                ),
                SizedBox(height: 20),
                Text("Country", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: countryController,
                  hintText: "Enter country",
                  isRequired: true, // Made Mandatory
                ),
                SizedBox(height: 20),
                Text("Postal Code", style: AppTextStyles.size16SemiBold),
                SizedBox(height: 10),
                CustomTextFormField(
                  isfilled: true,
                  controller: pincodeController,
                  hintText: "Enter postal code",
                  isPincode: true,
                  isRequired: true,
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomRectBtn(
          width: double.infinity,
          onTap: _addAddress,
          height: 49,
          borderRadius: 8,
          text: "Add Address",
          color: Color(0xffF1913D),
          borderColor: Color(0xffF1913D),
          textColor: Colors.white,
        ),
      ),
    );
  }
}
