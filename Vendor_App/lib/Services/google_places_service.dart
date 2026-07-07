import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  final String apiKey;

  GooglePlacesService(this.apiKey);

  Future<List<PlacePrediction>> getPlacePredictions(
    String input, {
    double? lat,
    double? lng,
  }) async {
    if (input.isEmpty) return [];

    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey';

    if (lat != null && lng != null) {
      // Bias results to 50km radius of current location
      url += '&location=$lat,$lng&radius=50000';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlacePrediction.fromJson(p))
              .toList();
        } else {
          print(
            'Places API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}',
          );
        }
      }
    } catch (e) {
      print('Failed to fetch predictions: $e');
    }
    return [];
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
    } catch (e) {
      print('Failed to fetch place details: $e');
    }
    return null;
  }
}

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;
  final String name;

  PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    return PlaceDetails(
      lat: location['lat'],
      lng: location['lng'],
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
