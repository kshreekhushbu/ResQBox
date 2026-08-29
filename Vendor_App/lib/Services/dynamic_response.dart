import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:resqboxvendor/Screens/Auth/login_screen.dart';
import 'package:resqboxvendor/Utils/navigations.dart';
import 'package:resqboxvendor/Utils/shared_preference_helper.dart';
import 'package:resqboxvendor/Utils/toast.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Add timeout constant
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('ApiToken');
    debugPrint('TOKEN present: ${token != null && token.isNotEmpty}');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> getRedirectLocation(String url) async {
    try {
      final headers = await _getHeaders();
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);
      request.followRedirects = false; // Capture the redirect

      final streamedResponse = await request.send().timeout(_timeout);

      debugPrint("Status Code: ${streamedResponse.statusCode}");

      if (streamedResponse.isRedirect) {
        String? location = streamedResponse.headers['location'];
        debugPrint("Redirect Location: $location");
        return location;
      }

      // Fallback: If it returns 200, maybe it's JSON with url?
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey('url')) {
            return body['url'];
          }
          if (body is Map && body.containsKey('error')) {
            _showToast(body['error']['message'] ?? "Error");
            return null;
          }
        } catch (_) {}
      }

      return null;
    } catch (e) {
      debugPrint("❌ Get Redirect Error: $e");
      return null;
    }
  }

  Future<dynamic> getRequest(String url) async {
    try {
      final headers = await _getHeaders();
      // Add timeout here
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    } catch (e) {
      debugPrint("❌ GET request error: $e");
      _showToast("Request failed. Please try again.");
      throw e;
    }
  }

  Future<Map<String, dynamic>> authResponse({
    Map<String, dynamic>? body,
    required String requestType,
    required String url,
  }) async {
    try {
      debugPrint("API URL: $url");
      String? token;
      final SharedPreferences pref = await SharedPreferences.getInstance();
      token = pref.getString('APItoken');
      debugPrint('Retrieved Token: $token');
      var headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      http.Response response;
      if (requestType.toUpperCase() == 'POST') {
        response = await http
            .post(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(body ?? {}),
            )
            .timeout(_timeout); // Add timeout
      } else if (requestType.toUpperCase() == 'GET') {
        response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(_timeout); // Add timeout
      } else {
        throw Exception('Unsupported request type: $requestType');
      }

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        _showToast('Request failed with status: ${response.statusCode}');
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } on SocketException {
      _showToast("No Internet Connection");
      return {'error': 'No Internet Connection'};
    } catch (e) {
      debugPrint("Error in API call: $e");
      _showToast("Failed to connect to the server");
      return {'error': 'Failed to connect to the server'};
    }
  }

  Future<dynamic> postRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(_timeout); // Add timeout
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    } catch (e) {
      debugPrint("❌ POST request error: $e");
      _showToast("Request failed. Please try again.");
      throw e;
    }
  }

  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      debugPrint("📤 PUT Request URL: $url");
      final response = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(_timeout); // Add timeout

      debugPrint("📥 PUT Response Code: ${response.statusCode}");
      debugPrint("📥 PUT Response Body: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    } catch (e) {
      debugPrint("❌ PUT request error: $e");
      _showToast("Request failed. Please try again.");
      throw e;
    }
  }

  Future<dynamic> deleteRequest(
    String url, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout); // Add timeout
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    } catch (e) {
      debugPrint("❌ DELETE request error: $e");
      _showToast("Request failed. Please try again.");
      throw e;
    }
  }

  Future<dynamic> patchRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(_timeout); // Add timeout
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    } catch (e) {
      debugPrint("❌ PATCH request error: $e");
      _showToast("Request failed. Please try again.");
      throw e;
    }
  }

  dynamic _handleResponse(http.Response response) async {
    debugPrint(
      "🔄 Handling Response: ${response.statusCode} - ${response.body}",
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      debugPrint("⚠️ Unauthorized (401) - Logging out");
      SharedPreferencesHelper().remove("ApiToken");
      NavigateTo().pushRemove(child: const LoginScreen());
      return null;
    } else if (response.statusCode == 500) {
      customToast(message: "Server Not Responding... Please try again");
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> downloadFile({
    required String url,
    required String fileName,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint("📄 File downloaded to: $filePath");

        // Open file
        await OpenFile.open(filePath);
      } else {
        debugPrint("❌ Failed to download file. Status: ${response.statusCode}");
        _showToast("Failed to download PDF. Try again.");
      }
    } on SocketException {
      _showToast("No Internet Connection");
    } catch (e) {
      debugPrint("❌ File download error: $e");
      _showToast("Something went wrong while downloading PDF.");
    }
  }

  Future<String?> downloadFileOnly({
    required String url,
    required String fileName,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint("📄 File downloaded to: $filePath");
        return filePath;
      } else {
        debugPrint("❌ Failed to download file. Status: ${response.statusCode}");
        _showToast("Failed to download PDF. Try again.");
        return null;
      }
    } on SocketException {
      _showToast("No Internet Connection");
      return null;
    } catch (e) {
      debugPrint("❌ File download error: $e");
      _showToast("Something went wrong while downloading PDF.");
      return null;
    }
  }

  Future<List<String>> uploadImages({
    required String url,
    required List<File> files,
    String folder = "stores",
    String fieldName = "images",
  }) async {
    if (files.isEmpty) return [];

    try {
      final headers = await _getHeaders();
      headers.remove('Content-Type');

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(headers);
      request.fields['folder'] = folder;

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        final parts = mimeType.split('/');
        final mediaType = MediaType(
          parts[0],
          parts.length > 1 ? parts[1] : 'jpeg',
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            contentType: mediaType,
            filename:
                'image_${DateTime.now().millisecondsSinceEpoch}_$i.${file.path.split('.').last}',
          ),
        );
      }

      debugPrint("📤 Upload Request to: $url folder=$folder");
      debugPrint("📤 Files count: ${files.length}");

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Upload Response Code: ${response.statusCode}");
      debugPrint("📥 Upload Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = jsonDecode(response.body);

        if (res['status'] == 1) {
          // Handle new response format with 'files' array
          if (res['files'] != null && res['files'] is List) {
            final files = res['files'] as List;
            final filenames = files
                .map((file) => file['fileName']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();
            debugPrint("✅ Returning filenames from files array: $filenames");
            return filenames;
          }
          // Handle old response format with 'fileName' array
          else if (res['fileName'] != null && res['fileName'] is List) {
            final filenames = List<String>.from(res['fileName']);
            debugPrint("✅ Returning filenames from fileName array: $filenames");
            return filenames;
          }
        }

        debugPrint("❌ Unexpected response structure: $res");
        _showToast('Upload completed but response format unexpected');
        return [];
      } else {
        final errorRes = jsonDecode(response.body);
        final errorMsg =
            errorRes['error'] ?? errorRes['message'] ?? 'Upload failed';
        _showToast('Upload failed: $errorMsg');
        return [];
      }
    } catch (e) {
      debugPrint("❌ Upload Error: $e");
      _showToast("Failed to upload images: ${e.toString()}");
      return [];
    }
  }

  Future<Map<String, String>?> uploadImage({
    required String url,
    required File file,
    required String folder,
    String fieldName = "image",
  }) async {
    try {
      final headers = {"Accept": "application/json"};
      headers.remove('Content-Type'); // let Multipart set automatically

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(headers);
      request.fields['folder'] = folder;

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      final parts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          contentType: MediaType(
            parts[0],
            parts.length > 1 ? parts[1] : 'jpeg',
          ),
          filename:
              'image_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = jsonDecode(response.body);
        final status = res['status'] ?? res['Status'];

        if (status.toString() == "1") {
          final fileName = res['fileName'] ?? res['data']?['fileName'];
          final fileUrl = res['fileUrl'] ?? res['data']?['fileUrl'];

          if (fileName != null && fileUrl != null) {
            debugPrint("✅ Upload success: $fileName");
            return {
              "fileName": fileName.toString(),
              "fileUrl": fileUrl.toString(),
            };
          }
        } else {
          debugPrint("❌ Upload failed: ${res['message'] ?? 'Unknown error'}");
        }
      } else {
        debugPrint("❌ Server error: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      return null;
    }
  }
}
