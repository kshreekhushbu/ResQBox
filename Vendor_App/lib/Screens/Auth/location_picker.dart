import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:resqboxvendor/Services/google_places_service.dart';
import 'package:resqboxvendor/Screens/Auth/add_address.dart';
import 'package:resqboxvendor/Utils/custom_appbar.dart';
import 'package:resqboxvendor/Utils/custom_border_btn.dart';
import 'package:resqboxvendor/Utils/custom_divider.dart';
import 'package:resqboxvendor/Utils/images.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/text_field.dart';
import 'package:resqboxvendor/Utils/textstyles.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final LatLng _defaultLocation = LatLng(
    17.4501,
    78.3912,
  ); // Default to Hyderabad
  String selectedLocation = "Loading...";
  String selectedArea = "Fetching location...";
  double? selectedLatitude;
  double? selectedLongitude;
  bool _isLoadingLocation = true;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
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
          if (!mounted) return;
          setState(() {
            _isLoadingLocation = false;
            selectedLocation = "Location permission denied";
            selectedArea = "Please grant location permission in settings";
          });
          // Still allow user to select location manually on map
          if (mounted) {
            setState(() {
              _currentPosition ??= _defaultLocation;
            });
            await _getAddressFromCoordinates(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          selectedLocation = "Location permission denied";
          selectedArea = "Please enable location in app settings";
        });
        // Still allow user to select location manually on map
        // Still allow user to select location manually on map
        if (mounted) {
          setState(() {
            _currentPosition ??= _defaultLocation;
          });
        }
        await _getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _isLoadingLocation = false;
          selectedLocation = "Location services disabled";
          selectedArea = "Please enable location services in device settings";
        });
        // Still allow user to select location manually on map
        // Still allow user to select location manually on map
        if (mounted) {
          setState(() {
            _currentPosition ??= _defaultLocation;
          });
        }
        await _getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        return;
      }

      // 1. Try to get Last Known Position first for speed (Instant feedback)
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          debugPrint(
            "📍 Found last known location: ${lastKnown.latitude}, ${lastKnown.longitude}",
          );
          setState(() {
            _currentPosition = LatLng(lastKnown.latitude, lastKnown.longitude);
            selectedLatitude = lastKnown.latitude;
            selectedLongitude = lastKnown.longitude;
            _isLoadingLocation = false; // Show map immediately
          });

          // Move camera immediately
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
            );
          }

          // Fetch address for last known location
          _getAddressFromCoordinates(lastKnown.latitude, lastKnown.longitude);
        }
      } catch (e) {
        debugPrint("⚠️ Error getting last known location: $e");
      }

      // 2. Always get fresh current position (Background update for accuracy)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(lat, lng);
          selectedLatitude = lat;
          selectedLongitude = lng;
          _isLoadingLocation = false;
        });
      }

      // Get address from coordinates
      if (mounted) {
        await _getAddressFromCoordinates(lat, lng);
      }

      // Move camera to current position after map is created
      if (_mapController != null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          selectedLocation = "Error fetching location";
          selectedArea = "Please select location on map";
        });
        // Still get address for default location
        // Still get address for default location
        if (mounted) {
          setState(() {
            _currentPosition ??= _defaultLocation;
          });
        }
        await _getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    }
  }

  //   Future<void> _getAddressFromCoordinates(
  //     double latitude,
  //     double longitude,
  //   ) async {
  //     try {
  //       List<Placemark> placemarks = await placemarkFromCoordinates(
  //         latitude,
  //         longitude,
  //       );
  //       if (placemarks.isNotEmpty) {
  //         Placemark place = placemarks[0];
  //         if (!mounted) return;
  //         setState(() {
  //           // Extract all address details
  //           // Prioritize: SubLocality (Area) > Locality (City) > Street (if text)
  //           String name = place.name ?? "";
  //           String street = place.street ?? "";
  //           String subLocality = place.subLocality ?? "";
  //           String locality = place.locality ?? "";

  //           // Check if street/name looks like a house number or Plus Code
  //           // e.g. "6-2-30/E" or "C9JP+Q8Q"
  //           bool isNumericStreet =
  //               RegExp(r'^\d').hasMatch(street) ||
  //               street.contains(RegExp(r'\d+'));
  //           // Check for Plus Code pattern (often has a + and is short/alphanumeric)
  //           bool isPlusCode = street.contains('+') && street.length < 15;
  //           bool isShortName =
  //               name.length < 5 ||
  //               RegExp(r'^\d').hasMatch(name) ||
  //               name.contains('+');

  //           // User explicitly asked to "show area" if street is weird
  //           if (subLocality.isNotEmpty && subLocality != name) {
  //             selectedLocation = subLocality;
  //           } else if (locality.isNotEmpty &&
  //               locality != name &&
  //               locality != subLocality) {
  //             selectedLocation = locality;
  //           } else if (street.isNotEmpty &&
  //               !isNumericStreet &&
  //               !isPlusCode &&
  //               street != name) {
  //             selectedLocation = street;
  //           } else if (!isShortName && name.isNotEmpty) {
  //             selectedLocation = name;
  //           } else {
  //             // Fallback
  //             selectedLocation = subLocality.isNotEmpty
  //                 ? subLocality
  //                 : (locality.isNotEmpty ? locality : "Selected Location");
  //           }

  //           // If the selected location is just the city (e.g. Hyderabad) and we have a sub-area, append it
  //           if (selectedLocation == locality && subLocality.isNotEmpty) {
  //             selectedLocation = "$locality, $subLocality";
  //           } else if (selectedLocation == subLocality && locality.isNotEmpty) {
  //             selectedLocation = "$subLocality, $locality";
  //           }

  //           // Final fallback
  //           if (selectedLocation.isEmpty ||
  //               selectedLocation == "Unknown Location") {
  //             selectedLocation = "Unknown Location";
  //           }

  //           // // Helper to check if a string is a "code" (Plus Code, house number, etc.)
  //           // bool isCode(String? s) {
  //           //   if (s == null || s.isEmpty) return false;
  //           //   // Plus Code (e.g. C9JP+Q8Q)
  //           //   if (s.contains('+') && s.length < 15) return true;
  //           //   // Numeric/Alphanumeric House Number patterns (e.g. 6-2-30/E, 12, 12B)
  //           //   // Starts with digit, length < 10, may contain / or -
  //           //   if (RegExp(r'^\d').hasMatch(s)) return true;
  //           //   return false;
  //           // }
  //           bool isCode(String? s) {
  //   if (s == null || s.isEmpty) return false;
  //   // Plus Code (e.g. C9JP+Q8Q)
  //   if (s.contains('+') && s.length < 15) return true;
  //   // House number only (short, mostly digits, e.g. "25", "6-2-30/E", "12B")
  //   // But NOT full streets like "25 Martin Pl"
  //   if (s.length < 10 && RegExp(r'^\d+[/-]?\d*[A-Z]?$').hasMatch(s)) return true;
  //   return false;
  // }

  //           selectedStreet = isCode(place.street) ? "" : place.street;

  //           String? rawLandmark = place.subThoroughfare ?? place.thoroughfare;
  //           selectedLandmark = isCode(rawLandmark) ? "" : rawLandmark;

  //           selectedSubLocality = place.subLocality;
  //           selectedLocality = place.locality;
  //           selectedSubAdministrativeArea = place.subAdministrativeArea;
  //           selectedAdministrativeArea = place.administrativeArea;
  //           selectedPincode = place.postalCode;
  //           selectedCountry = place.country ?? "Australia";

  //           // Build area string
  //           selectedArea =
  //               "${place.locality ?? ""}, ${place.administrativeArea ?? ""}"
  //                   .trim();
  //           if (selectedArea.startsWith(",")) {
  //             selectedArea = selectedArea.substring(1).trim();
  //           }

  //           // Re-evaluate selectedLocation based on cleared fields if needed,
  //           // or just rely on the previous logic which already tries to pick the best name.
  //           // Ensuring selectedLocation is not a code was done in previous steps,
  //           // but let's double check safe usage.

  //           // ... (Previous logic for selectedLocation name continues below or is preserved) ...
  //         });
  //         debugPrint("📍 Address Details:");
  //         debugPrint("   Street: ${place.street}");
  //         debugPrint("   Locality: ${place.locality}");
  //         debugPrint("   Pincode: ${place.postalCode}");
  //         debugPrint(
  //           "   Landmark: ${place.subThoroughfare ?? place.thoroughfare}",
  //         );
  //       }
  //     } catch (e) {
  //       debugPrint("❌ Error getting address: $e");
  //     }
  //   }

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
        if (!mounted) return;
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

          // Determine best location name
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

          // ✅ IMPROVED: Helper to check if a string is a "code"
          bool isCode(String? s) {
            if (s == null || s.isEmpty) return false;

            // Plus Code (e.g. C9JP+Q8Q)
            if (s.contains('+') && s.length < 15) return true;

            // House number only (short, mostly digits)
            // Will match: "25", "6-2-30/E", "12B"
            // Will NOT match: "25 Martin Pl", "123 Main Street"
            if (s.length < 10) {
              if (RegExp(r'^\d+$').hasMatch(s)) return true;
              if (RegExp(r'^\d+[/-]\d*[A-Z]?$').hasMatch(s)) return true;
            }

            return false;
          }

          // ✅ Now "25 Martin Pl" will NOT be filtered out
          selectedStreet = isCode(place.street) ? "" : place.street;

          String? rawLandmark = place.subThoroughfare ?? place.thoroughfare;
          selectedLandmark = isCode(rawLandmark) ? "" : rawLandmark;

          selectedSubLocality = place.subLocality;
          selectedLocality = place.locality;
          selectedSubAdministrativeArea = place.subAdministrativeArea;
          selectedAdministrativeArea = place.administrativeArea;
          selectedPincode = place.postalCode;
          selectedCountry = place.country ?? "Australia";

          selectedArea =
              "${place.locality ?? ""}, ${place.administrativeArea ?? ""}"
                  .trim();
          if (selectedArea.startsWith(",")) {
            selectedArea = selectedArea.substring(1).trim();
          }
        });

        debugPrint("📍 Address Details:");
        debugPrint("   Street: ${place.street}");
        debugPrint("   Selected Street: $selectedStreet");
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
    // If we already have a position, move camera to it
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
    if (selectedLatitude != null && selectedLongitude != null) {
      await _getAddressFromCoordinates(selectedLatitude!, selectedLongitude!);
    }
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
              title: "Choose Location",
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
      body: _currentPosition == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xffF1913D)),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
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
                      position: _currentPosition!,
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
                          },
                          onClear: () {
                            if (mounted) {
                              setState(() {
                                _predictions = [];
                              });
                            }
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
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
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
                        Text(
                          "Current Location",
                          style: AppTextStyles.size18Medium,
                        ),
                        CustomDivider(
                          width: double.infinity,
                          color: Color(0xffE1E1E1),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              AppImages.pickerLoc,
                              height: 28,
                              width: 28,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            MediaQuery.of(context).size.width *
                                            0.36,
                                        onTap: _getCurrentLocation,
                                        // text: "Change",
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
                                      style: AppTextStyles.size14Medium
                                          .copyWith(color: Color(0xff707070)),
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
                              // Always navigate to AddAddressScreen for registration flow
                              NavigateTo().nextPage(
                                child: AddAddressScreen(
                                  locationName: selectedLocation,
                                  area: selectedArea,
                                  latitude: selectedLatitude!,
                                  longitude: selectedLongitude!,
                                  pincode: selectedPincode,
                                  landmark: selectedLandmark,
                                  street: selectedStreet,
                                  locality: selectedLocality,
                                  subLocality: selectedSubLocality,
                                  administrativeArea:
                                      selectedAdministrativeArea,
                                  country: selectedCountry,
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        final predictions = await _placesService.getPlacePredictions(
          query,
          lat: _currentPosition?.latitude ?? _defaultLocation.latitude,
          lng: _currentPosition?.longitude ?? _defaultLocation.longitude,
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

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final details = await _placesService.getPlaceDetails(prediction.placeId);
    if (details != null) {
      if (mounted) {
        setState(() {
          selectedLocation = details.name.isNotEmpty
              ? details.name
              : prediction.description;
          selectedLatitude = details.lat;
          selectedLongitude = details.lng;
          _currentPosition = LatLng(details.lat, details.lng);
        });
      }

      // Move map
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(details.lat, details.lng), 15.0),
      );

      // Fetch full address details
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
}
