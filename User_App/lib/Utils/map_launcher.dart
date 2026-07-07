import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  /// Opens Google Maps with the given latitude and longitude coordinates
  ///
  /// [latitude] - The latitude coordinate
  /// [longitude] - The longitude coordinate
  ///
  /// Returns true if the map was opened successfully, false otherwise
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Create Google Maps URL with coordinates
      final String googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      // Alternative: Use Google Maps app directly (if installed)
      // final String googleMapsAppUrl = 'https://maps.google.com/?q=$latitude,$longitude';

      final Uri url = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // Opens in external app if available
        );
      } else {
        return false;
      }
    } catch (e) {
      print('Error opening Google Maps: $e');
      return false;
    }
  }
}
