import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:resqbox_user/Controllers/home_controller.dart';
import 'package:resqbox_user/Utils/active_btn.dart';
import 'package:resqbox_user/Utils/colors.dart';
import 'package:resqbox_user/Utils/custom_border_btn.dart';
import 'package:resqbox_user/Utils/custom_padding.dart';
import 'package:resqbox_user/Utils/custom_sizedbox.dart';
import 'package:resqbox_user/Utils/customtext.dart';
import 'package:resqbox_user/Utils/images.dart';
import 'package:resqbox_user/Utils/mediaquery.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/textformfield.dart';
import 'package:http/http.dart' as http;

class SearchLocation extends StatefulWidget {
  const SearchLocation({super.key});

  @override
  State<SearchLocation> createState() => _SearchLocationState();
}

class _SearchLocationState extends State<SearchLocation> {
  TextEditingController searchController = TextEditingController();
  final GlobalKey _fieldKey = GlobalKey();
  List<Map<String, dynamic>> _suggestions = [];
  OverlayEntry? _overlayEntry;

  Future<void> fetchLocations(String input) async {
    if (input.isEmpty) {
      removeOverlay();
      return;
    }

    final String apiKey = 'AIzaSyBZpiSwjq1dm3Xn2-eHS13d_8qDS2ey9WU';
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      debugPrint("data......... $data");
      final predictions = data['predictions'] as List;

      setState(() {
        _suggestions = predictions
            .map((item) => {
                  'description': item['description'],
                  'place_id': item['place_id'],
                })
            .toList();
      });

      showOverlay();
    } catch (e) {
      print('Error: $e');
    }
  }

  void showOverlay() {
    removeOverlay();

    final RenderBox renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy + size.height,
        left: position.dx,
        width: size.width,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_suggestions[index]['description']),
              onTap: () async {
                final placeId = _suggestions[index]['place_id'];
                searchController.text = _suggestions[index]['description'];
                removeOverlay();
                await fetchPlaceDetailsAndUpdateMap(placeId);
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> fetchPlaceDetailsAndUpdateMap(String placeId) async {
    const apiKey = 'AIzaSyBZpiSwjq1dm3Xn2-eHS13d_8qDS2ey9WU';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      final result = data['result'];
      final location = result['geometry']['location'];
      final lat = location['lat'];
      final lng = location['lng'];

      final LatLng newLatLng = LatLng(lat, lng);

      final homeController =
          Provider.of<HomeController>(context, listen: false);

      // Update camera
      await homeController.mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLatLng, 15),
      );

      // Update marker
      homeController.markers.clear();
      homeController.markers.add(
        Marker(
          markerId: const MarkerId("selected-location"),
          position: newLatLng,
        ),
      );

      // Now update HomeController fields
      homeController.updateUserSelectedLocation(newLatLng);

      // You can extract address parts as needed
      // Reverse geocode to get full address
    } catch (e) {
      debugPrint('Failed to fetch place details: $e');
    }
  }

  void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    searchController.dispose();
    removeOverlay();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeController =
          Provider.of<HomeController>(context, listen: false);
      homeController.getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(builder: (context, homeController, child) {
      return Scaffold(
        backgroundColor: const Color(0XFFF6F6F6),
        appBar: AppBar(
          backgroundColor: AppColors.tWhiteColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              NavigateTo().backPage();
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.tBlackColor,
            ),
          ),
          title: const CustomText(
            text: "Choose Location",
            fontSize: 0.022,
            fontWeight: FontWeight.w600,
          ),
          bottom: PreferredSize(
              preferredSize: Size.fromHeight(Sizes.height * .065),
              child: CustomPadding(
                left: .04,
                right: .04,
                bottom: .01,
                child: CustomTextFormField(
                    key: _fieldKey,
                    controller: searchController,
                    hintText: "Search Location",
                    hintFontSize: .016,
                    fillColor: AppColors.tWhiteColor,
                    hintColor: AppColors.tBlackColor,
                    prefixIconHeight: .024,
                    prefixIcon: AppImages.locSearch,
                    onChanged: (value) {
                      debugPrint("valueeeeeeeeeee $value");
                      fetchLocations(searchController.text);
                    },
                    customBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.tPrimaryColor))),
              )),
        ),
        body: Stack(
          children: [
            Center(
              child: homeController.currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: homeController.currentPosition!,
                        zoom: 15.0,
                      ),
                      markers: homeController.markers,
                      onMapCreated: (GoogleMapController controller) {
                        homeController.setMapController(controller);
                      },
                      onTap: (LatLng tappedLocation) {
                        searchController.clear();
                        homeController
                            .updateUserSelectedLocation(tappedLocation);
                      },
                    ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                width: Sizes.width,
                decoration: const BoxDecoration(
                  color: AppColors.tWhiteColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomText(
                        text: "Current Location",
                        fontSize: .02,
                        fontWeight: FontWeight.w600),
                    const CustomPadding(
                      vertical: .009,
                      child: Divider(
                        color: Color(0XFFE1E1E1),
                        thickness: 1,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          AppImages.location,
                          height: 24,
                          color: AppColors.tBlackColor,
                        ),
                        const CustomSizedBox(width: 0.01),
                        Expanded(
                          child: CustomText(
                            text: homeController.locHouse ?? 'loading...',
                            fontWeight: FontWeight.w700,
                            fontSize: 0.022,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        CustomBorderBtn(
                          height: Sizes.height * 0.043,
                          width: Sizes.width * .38,
                          text: "Current Location",
                          fontSize: .016,
                          onTap: () async {
                            searchController.clear();
                            await homeController.getCurrentLocation(
                                forceRefresh: true);
                          },
                          borderColor: const Color(0XFFE1E1E1),
                          textColor: AppColors.tBlackColor,
                        ),
                      ],
                    ),
                    const CustomSizedBox(height: 0.01),
                    Align(
                      alignment: Alignment.topLeft,
                      child: CustomPadding(
                        left: .06,
                        child: CustomText(
                          text: homeController.locLandmark ?? 'loading...',
                          fontWeight: FontWeight.w500,
                          fontSize: 0.016,
                          color: Color(0XFF707070),
                        ),
                      ),
                    ),
                    const CustomSizedBox(height: 0.02),
                    ActiveButton(
                        height: Sizes.height * 0.056,
                        width: Sizes.width * .9,
                        borderRadius: 25,
                        text: "Continue",
                        color: AppColors.tPrimaryColor,
                        onPressed: () async {
                          // Ensure home page API is called with updated lat/lng
                          if (homeController.locLatitude != null &&
                              homeController.locLongitude != null) {
                            debugPrint(
                                "📍 Calling home page API with updated location: ${homeController.locLatitude}, ${homeController.locLongitude}");
                            // Force refresh to get new data with updated location
                            await homeController.fetchHomePageData(
                              latitude: homeController.locLatitude!,
                              longitude: homeController.locLongitude!,
                              forceRefresh: true,
                            );
                          }
                          NavigateTo().backPage();
                        }),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
