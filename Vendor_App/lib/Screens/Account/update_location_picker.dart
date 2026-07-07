import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:resqboxvendor/Services/google_places_service.dart';
import 'package:resqboxvendor/Screens/Account/address_edit.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_divider.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class UpdateLocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialHouseNo;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialPincode;
  // final String? initialLandmark;

  const UpdateLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialHouseNo,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialPincode,
    // this.initialLandmark,
  });

  @override
  _UpdateLocationPickerScreenState createState() =>
      _UpdateLocationPickerScreenState();
}

class _UpdateLocationPickerScreenState
    extends State<UpdateLocationPickerScreen> {
  GoogleMapController? _mapController;
  // Initialize with null or a distinct placeholder, but we will set it in initState
  LatLng _currentPosition = const LatLng(0, 0);
  String selectedLocation = "Loading...";
  String selectedArea = "Fetching location...";
  double? selectedLatitude;
  double? selectedLongitude;
  bool _isLoadingLocation = true;
  bool _isInitialLoad = true;

  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  final GooglePlacesService _placesService = GooglePlacesService(
    'AIzaSyBZpiSwjq1dm3Xn2-eHS13d_8qDS2ey9WU',
  );

  // Address details from geocoding
  String? selectedPincode;
  String? selectedLandmark;
  String? selectedStreet;
  String? selectedSubLocality;
  String? selectedLocality;
  String? selectedSubAdministrativeArea;
  String? selectedAdministrativeArea;
  String? selectedCountry;
  String? selectedCity;
  String? selectedState;
  String? selectedHouseNo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        // STRICTLY use the passed coordinates
        _initializeWithLocation(
          widget.initialLatitude!,
          widget.initialLongitude!,
        );
      } else {
        // Only if absolutely NO data is passed, try to get current location
        _getCurrentLocation();
      }
    });

    // Initialize _currentPosition with passed data if available to avoid map jump
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentPosition = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      selectedLatitude = widget.initialLatitude;
      selectedLongitude = widget.initialLongitude;
    }
  }

  Future<void> _initializeWithLocation(double lat, double lng) async {
    setState(() {
      _currentPosition = LatLng(lat, lng);
      selectedLatitude = lat;
      selectedLongitude = lng;
      _isLoadingLocation = false;

      // Populate from initial props
      selectedHouseNo = widget.initialHouseNo;
      selectedStreet = widget.initialStreet;
      selectedCity = widget.initialCity;
      selectedState = widget.initialState;
      selectedCountry = widget.initialCountry;
      selectedPincode = widget.initialPincode;
      // selectedLandmark = widget.initialLandmark;

      // Fallback for locality vars that might be used by geocoding logic
      selectedLocality = widget.initialCity;
      selectedAdministrativeArea = widget.initialState;

      // Construct display strings
      List<String> locParts = [];
      if (selectedHouseNo != null && selectedHouseNo!.isNotEmpty) {
        locParts.add(selectedHouseNo!);
      }
      if (selectedStreet != null && selectedStreet!.isNotEmpty) {
        locParts.add(selectedStreet!);
      }
      if (locParts.isNotEmpty) {
        selectedLocation = locParts.join(", ");
      } else if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
        selectedLocation = widget.initialCity!;
      } else {
        selectedLocation = "Selected Location";
      }

      List<String> areaParts = [];
      if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
        areaParts.add(widget.initialCity!);
      }
      if (widget.initialState != null && widget.initialState!.isNotEmpty) {
        areaParts.add(widget.initialState!);
      }
      if (widget.initialCountry != null && widget.initialCountry!.isNotEmpty) {
        areaParts.add(widget.initialCountry!);
      }

      if (areaParts.isNotEmpty) {
        selectedArea = areaParts.join(", ");
      } else {
        selectedArea = "Unknown Area";
      }
    });

    // Move camera if map is already created
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
      );
    }

    // Do NOT reverse geocode if we have valid initial data
    // We only want to use the passed address data initially
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      selectedLocation = "Fetching location...";
      selectedArea = "Please wait...";
    });

    try {
      // Check location permissions first
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            selectedLocation = "Location permission denied";
            selectedArea = "Please grant location permission in settings";
          });
          // Still allow user to select location manually on map
          await _getAddressFromCoordinates(
            _currentPosition.latitude,
            _currentPosition.longitude,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          selectedLocation = "Location permission denied";
          selectedArea = "Please enable location in app settings";
        });
        // Still allow user to select location manually on map
        await _getAddressFromCoordinates(
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          selectedLocation = "Location services disabled";
          selectedArea = "Please enable location services in device settings";
        });
        // Still allow user to select location manually on map
        await _getAddressFromCoordinates(
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
        return;
      }

      // Try to get last known position first (faster)
      Position? position = await Geolocator.getLastKnownPosition();

      // If no last known position, get current position
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
      }

      final lat = position.latitude;
      final lng = position.longitude;

      setState(() {
        _currentPosition = LatLng(lat, lng);
        selectedLatitude = lat;
        selectedLongitude = lng;
        _isLoadingLocation = false;
      });

      // Get address from coordinates
      await _getAddressFromCoordinates(lat, lng);

      // Move camera to current position after map is created
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 15.0),
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
      setState(() {
        _isLoadingLocation = false;
        selectedLocation = "Error fetching location";
        selectedArea = "Please select location on map";
      });
      // Still get address for default location
      await _getAddressFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
    }
  }

  Future<void> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Extract all address details
          String name = place.name ?? "";
          String street = place.street ?? "";
          String subLocality = place.subLocality ?? "";
          String locality = place.locality ?? "";

          // Check if street/name looks like a house number or Plus Code
          bool isNumericStreet =
              RegExp(r'^\d').hasMatch(street) ||
              street.contains(RegExp(r'\d+'));
          bool isPlusCode = street.contains('+') && street.length < 15;
          bool isShortName =
              name.length < 5 ||
              RegExp(r'^\d').hasMatch(name) ||
              name.contains('+');

          if (subLocality.isNotEmpty && subLocality != name) {
            selectedLocation = subLocality;
          } else if (locality.isNotEmpty &&
              locality != name &&
              locality != subLocality) {
            selectedLocation = locality;
          } else if (street.isNotEmpty &&
              !isNumericStreet &&
              !isPlusCode &&
              street != name) {
            selectedLocation = street;
          } else if (!isShortName && name.isNotEmpty) {
            selectedLocation = name;
          } else {
            selectedLocation = subLocality.isNotEmpty
                ? subLocality
                : (locality.isNotEmpty ? locality : "Selected Location");
          }

          if (selectedLocation == locality && subLocality.isNotEmpty) {
            selectedLocation = "$locality, $subLocality";
          } else if (selectedLocation == subLocality && locality.isNotEmpty) {
            selectedLocation = "$subLocality, $locality";
          }

          if (selectedLocation.isEmpty ||
              selectedLocation == "Unknown Location") {
            selectedLocation = "Unknown Location";
          }

          bool isCode(String? s) {
            if (s == null || s.isEmpty) return false;
            if (s.contains('+') && s.length < 15) return true;
            if (RegExp(r'^\d').hasMatch(s)) return true;
            return false;
          }

          selectedStreet = isCode(place.street) ? "" : place.street;

          String? rawLandmark = place.subThoroughfare ?? place.thoroughfare;
          selectedLandmark = isCode(rawLandmark) ? "" : rawLandmark;

          selectedSubLocality = place.subLocality;
          selectedLocality = place.locality;
          selectedSubAdministrativeArea = place.subAdministrativeArea;
          selectedAdministrativeArea = place.administrativeArea;
          selectedPincode = place.postalCode;
          selectedCountry = place.country;
          selectedCity = place.locality;
          selectedState = place.administrativeArea;

          // Build area string
          selectedArea =
              "${place.locality ?? ""}, ${place.administrativeArea ?? ""}"
                  .trim();
          if (selectedArea.startsWith(",")) {
            selectedArea = selectedArea.substring(1).trim();
          }
        });
        debugPrint("📍 Address Details:");
        debugPrint("   Street: ${place.street}");
        debugPrint("   Locality: ${place.locality}");
        debugPrint("   Pincode: ${place.postalCode}");
        debugPrint(
          "   Landmark: ${place.subThoroughfare ?? place.thoroughfare}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting address: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (selectedLatitude != null && selectedLongitude != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(selectedLatitude!, selectedLongitude!),
            15.0,
          ),
        );
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
      selectedLatitude = position.target.latitude;
      selectedLongitude = position.target.longitude;
    });
  }

  Future<void> _onCameraIdle() async {
    if (_isInitialLoad) {
      _isInitialLoad = false;
      return;
    }
    if (selectedLatitude != null && selectedLongitude != null) {
      await _getAddressFromCoordinates(selectedLatitude!, selectedLongitude!);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        final predictions = await _placesService.getPlacePredictions(
          query,
          lat: _currentPosition.latitude,
          lng: _currentPosition.longitude,
        );
        if (mounted) {
          setState(() {
            _predictions = predictions;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _predictions = [];
          });
        }
      }
    });
  }

  void _onPredictionSelected(PlacePrediction prediction) async {
    setState(() {
      _searchController.text = prediction.description;
      _predictions = [];
    });

    FocusScope.of(context).unfocus();

    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (details != null) {
      setState(() {
        selectedLocation = details.name.isNotEmpty
            ? details.name
            : prediction.description;
        selectedLatitude = details.lat;
        selectedLongitude = details.lng;
        _currentPosition = LatLng(details.lat, details.lng);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(details.lat, details.lng), 15.0),
      );

      await _getAddressFromCoordinates(details.lat, details.lng);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAppBar(
              title: "Update Location",
              isLeading: true,
              backTap: () {
                NavigateTo().backPage();
              },
              isFromTabsScreen: false,
              leadingHeight: 24,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            markers: {
              Marker(
                markerId: MarkerId('selected_location'),
                position: _currentPosition,
                draggable: false,
              ),
            },
          ),
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xffEB7712)),
                  ),
                  child: CustomTextFormField(
                    image: AppImages.search,
                    isfilled: false,
                    controller: _searchController,
                    hintText: "Search location",
                    showClearButton: true,
                    onChanged: (value) {
                      _onSearchChanged(value);
                      setState(() {});
                    },
                    onClear: () {
                      setState(() {
                        _predictions = [];
                      });
                    },
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    margin: EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _predictions.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            prediction.description,
                            style: AppTextStyles.size14Medium,
                          ),
                          onTap: () => _onPredictionSelected(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(color: Colors.white),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Current Location", style: AppTextStyles.size18Medium),
                  CustomDivider(
                    width: double.infinity,
                    color: Color(0xffE1E1E1),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(AppImages.pickerLoc, height: 28, width: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedLocation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.size20SemiBold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                CustomRectBtn(
                                  height: 32,
                                  borderColor: Color(0xffE1E1E1),
                                  borderRadius: 4,
                                  width:
                                      MediaQuery.of(context).size.width * 0.36,
                                  onTap: _getCurrentLocation,
                                  leading: Text(
                                    "Current Location",
                                    style: AppTextStyles.size12Medium,
                                  ),
                                  color: Colors.white,
                                  textColor: Colors.black,
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            if (_isLoadingLocation)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Color(0xffF1913D),
                                  ),
                                ),
                              )
                            else
                              Text(
                                selectedArea,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.size14Medium.copyWith(
                                  color: Color(0xff707070),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  CustomRectBtn(
                    width: double.infinity,
                    onTap: () {
                      if (selectedLatitude != null &&
                          selectedLongitude != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddressEditScreen(
                              prefilledStreet: selectedStreet,
                              prefilledCity: selectedCity ?? selectedLocality,
                              prefilledState:
                                  selectedState ?? selectedAdministrativeArea,
                              prefilledCountry: selectedCountry,
                              prefilledPincode: selectedPincode,
                              prefilledLandmark: selectedLandmark,
                              prefilledLatitude: selectedLatitude,
                              prefilledLongitude: selectedLongitude,
                            ),
                          ),
                        );
                      } else {
                        customToast(
                          message: "Please select a location on the map",
                        );
                      }
                    },
                    height: 49,
                    borderRadius: 8,
                    text: "Confirm Location",
                    color: Color(0xffF1913D),
                    borderColor: Color(0xffF1913D),
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
