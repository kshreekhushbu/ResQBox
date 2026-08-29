import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:resqbox_user/Screens/Authentication/guest_login_screen.dart';
import 'package:resqbox_user/Screens/Authentication/login_screen.dart';
import 'package:resqbox_user/Utils/navigations.dart';
import 'package:resqbox_user/Utils/shared_preference_helper.dart';
import 'package:resqbox_user/Utils/toast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('ApiToken');
    String? tempToken = prefs.getString('Token2');
    if (tempToken != null && tempToken.isNotEmpty) {
      token = tempToken;
    } else {
      token = prefs.getString('ApiToken');
    }
    debugPrint('TOKEN present: ${token != null && token.isNotEmpty}');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> getRequest(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      debugPrint("responsecode..........${response.statusCode}");
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
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
      token = pref.getString('ApiToken');
      String? tempToken = pref.getString('Token2');
      if (tempToken != null && tempToken.isNotEmpty) {
        token = tempToken;
      } else {
        token = pref.getString('ApiToken');
      }
      debugPrint('Retrieved Token: $token');
      var headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      http.Response response;
      if (requestType.toUpperCase() == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      } else if (requestType.toUpperCase() == 'GET') {
        response = await http.get(
          Uri.parse(url),
          headers: headers,
        );
      } else {
        throw Exception('Unsupported request type: $requestType');
      }

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 201) {
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

  Future<dynamic> postRequest(String url, Map<String, dynamic> body,
      {String? from}) async {
    try {
      debugPrint(".body.... $body");
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response, from: from);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    }
  }

  Future<dynamic> putRequest(String url, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      debugPrint("Response Status Code: ${response.statusCode}");
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    }
  }

  Future<dynamic> deleteRequest(String url,
      [Map<String, dynamic>? body]) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } on SocketException {
      _showToast("No Internet Connection");
      throw Exception("No Internet Connection");
    }
  }

  dynamic _handleResponse(http.Response response, {String? from}) async {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 413) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      if (SharedPreferencesHelper().getString("loginType") == "skip") {
        // customToast(message: "Please login with your credentials to continue");
        SharedPreferencesHelper().remove("ApiToken");
        SharedPreferencesHelper().remove("Token2");
        SharedPreferencesHelper().remove("role");
        SharedPreferencesHelper().clearAlldata();
        NavigateTo().pushRemove(child: GuestLoginScreen());
      } else {
        SharedPreferencesHelper().remove("ApiToken");
        SharedPreferencesHelper().remove("Token2");
        SharedPreferencesHelper().remove("role");
        SharedPreferencesHelper().clearAlldata();
        customToast(message: "Session Expired... Please login again");
        NavigateTo().pushRemove(child: LoginScreen());
      }
    } else if (response.statusCode == 500) {
      customToast(message: "Server Not Responding... Please try again");
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  }

  Future<dynamic> uploadFile({
    required String url,
    required File file,
    required String folderName,
  }) async {
    try {
      debugPrint("upload files..... $url, $file, $folderName");
      final SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('ApiToken');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add Authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Detect MIME type
      final mimeType = lookupMimeType(file.path);
      final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

      // Add file with correct field name 'file'
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // <-- MUST match the backend field
          file.path,
          contentType: mediaType,
        ),
      );

      // Add folder name - backend expects 'folderName' (camelCase)
      request.fields['folder'] = folderName;

      debugPrint("Folder name being sent: $folderName");
      debugPrint("Request fields: ${request.fields}");

      // Send the request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${responseData.body}");

      if (response.statusCode == 200) {
        return jsonDecode(responseData.body);
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error uploading file: $e");
      return {'error': 'Failed to upload file'};
    }
  }

  // Future<dynamic> uploadFile({
  //   required String url,
  //   required File file,
  //   required String folderName,
  // }) async {
  //   try {
  //     debugPrint("upload files..... $url, $file, $folderName");
  //     final SharedPreferences pref = await SharedPreferences.getInstance();
  //     String? token = pref.getString('ApiToken');
  //     String? tempToken = pref.getString('Token2');
  //     if (tempToken != null && tempToken.isNotEmpty) {
  //       token = tempToken;
  //     } else {
  //       token = pref.getString('ApiToken');
  //     }
  //     debugPrint('TOKEN present: ${token != null && token.isNotEmpty}');
  //     var request = http.MultipartRequest('POST', Uri.parse(url));

  //     // Add Authorization header
  //     if (token != null) {
  //       request.headers['Authorization'] = 'Bearer $token';
  //     }

  //     // Detect MIME type
  //     final mimeType = lookupMimeType(file.path);
  //     final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

  //     // Add file with correct field name 'image'
  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         'image', // <-- MUST match the backend field
  //         file.path,
  //         contentType: mediaType,
  //       ),
  //     );

  //     // Add folder
  //     request.fields['foldername'] = folderName;

  //     // Send the request
  //     var response = await request.send();
  //     var responseData = await http.Response.fromStream(response);

  //     debugPrint("Response Status Code: ${response.statusCode}");
  //     debugPrint("Response Body: ${responseData.body}");

  //     if (response.statusCode == 200) {
  //       return jsonDecode(responseData.body);
  //     } else {
  //       throw Exception('Upload failed with status: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     debugPrint("Error uploading file: $e");
  //     return {'error': 'Failed to upload file'};
  //   }
  // }

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

  // Helper method to get token
  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tempToken = prefs.getString('Token2');
    if (tempToken != null && tempToken.isNotEmpty) {
      return tempToken;
    } else {
      return prefs.getString('ApiToken');
    }
  }

  // // Helper method to get main MIME type
  // String _getMainType(String extension) {
  //   switch (extension.toLowerCase()) {
  //     case 'jpg':
  //     case 'jpeg':
  //     case 'png':
  //     case 'gif':
  //     case 'webp':
  //       return 'image';
  //     case 'mp4':
  //     case 'mov':
  //     case 'avi':
  //     case 'mkv':
  //       return 'video';
  //     default:
  //       return 'application';
  //   }
  // }

  // // Helper method to get sub MIME type
  // String _getSubType(String extension) {
  //   switch (extension.toLowerCase()) {
  //     case 'jpg':
  //     case 'jpeg':
  //       return 'jpeg';
  //     case 'png':
  //       return 'png';
  //     case 'gif':
  //       return 'gif';
  //     case 'webp':
  //       return 'webp';
  //     case 'mp4':
  //       return 'mp4';
  //     case 'mov':
  //       return 'quicktime';
  //     case 'avi':
  //       return 'x-msvideo';
  //     case 'mkv':
  //       return 'x-matroska';
  //     default:
  //       return 'octet-stream';
  //   }
  // }

  // // Multipart API response for S3 uploads
  // Future multipartApiResponse({
  //   required String url,
  //   required String requestType,
  //   required Map fields,
  //   bool ignoreToken = false,
  //   bool removeBaseUrl = false,
  //   Map<String, String>? customHeaders,
  // }) async {
  //   try {
  //     final apiUrl = removeBaseUrl ? url : Apis.baseUrl + url;

  //     final headers = customHeaders ?? {};

  //     if (ignoreToken == false) {
  //       final pref = await SharedPreferencesHelper.getInstance();
  //       String? temporaryToken = pref.getString('Token2');
  //       String? apiToken = pref.getString('ApiToken');

  //       if (temporaryToken != null || temporaryToken!.isNotEmpty) {
  //         apiToken = temporaryToken;
  //       } else {
  //         apiToken = pref.getString('ApiToken');
  //       }

  //       if (apiToken!.isNotEmpty) {
  //         headers.addAll({'Authorization': 'Bearer $apiToken'});
  //       }
  //     }
  //     debugPrint('request type........... $requestType');

  //     final request = http.MultipartRequest(
  //       requestType.toUpperCase(),
  //       Uri.parse(apiUrl),
  //     );

  //     request.headers.addAll(headers);

  //     // Separate file from fields for proper ordering (file must be last for S3)
  //     File? fileToUpload;
  //     String? fileKey;

  //     // First, add all non-file fields
  //     for (final entry in fields.entries) {
  //       final key = entry.key;
  //       final value = entry.value;

  //       if (key == 'avatar' || key == 'file') {
  //         // Store file for later (must be added last for S3)
  //         final filePath = value is File ? value.path : value.toString();
  //         fileToUpload = File(filePath);
  //         fileKey = key;
  //       } else {
  //         // Add as regular field
  //         request.fields[key] = value.toString();
  //       }
  //     }

  //     // Add file LAST (required by S3 presigned POST)
  //     if (fileToUpload != null && fileKey != null) {
  //       final mimeType = lookupMimeType(fileToUpload.path);
  //       final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

  //       request.files.add(
  //         await http.MultipartFile.fromPath(
  //           fileKey,
  //           fileToUpload.path,
  //           contentType: mediaType,
  //         ),
  //       );
  //     }

  //     if (kDebugMode) {
  //       debugPrint('🚀 Sending MULTIPART request to: $apiUrl');
  //       debugPrint(
  //           '📝 Fields (${request.fields.length}): ${request.fields.keys.toList()}');
  //       debugPrint(
  //           '📎 Files (${request.files.length}): ${request.files.map((f) => '${f.field}:${f.filename}').toList()}');
  //       debugPrint('🔑 Headers: ${request.headers}');
  //     }

  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();

  //     final contentType = response.headers['content-type'];
  //     if (contentType != null && contentType.contains('application/json')) {
  //       final decoded = json.decode(responseBody);

  //       if (kDebugMode) {
  //         debugPrint('Multipart JSON Response: $decoded');
  //       }

  //       if (response.statusCode == 200) {
  //         return decoded;
  //       } else {
  //         return handleErrors(response, decoded);
  //       }
  //     } else {
  //       // For S3, 204 No Content or XML success/fail
  //       if (kDebugMode) {
  //         debugPrint('📥 S3 Response Status: ${response.statusCode}');
  //         debugPrint(
  //             '📄 S3 Response Body: ${responseBody.isEmpty ? "(empty)" : responseBody}');
  //       }

  //       if (response.statusCode == 204 ||
  //           response.statusCode == 201 ||
  //           response.statusCode == 200) {
  //         debugPrint('✅ S3 Upload successful!');
  //         return {"success": true};
  //       } else {
  //         debugPrint('❌ S3 Upload failed with status: ${response.statusCode}');
  //         throw Exception(
  //           "Upload failed: ${response.statusCode}\n$responseBody",
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Multipart Upload Error: $e');
  //     customToast(message: 'File upload failed. Try again later.');
  //     rethrow;
  //   }
  // }
}

void handleErrors(http.StreamedResponse response, var error) {
  if (response.statusCode == 400) {
    // Handle bad request error

    customToast(message: error);
  } else if (response.statusCode == 403) {
    // Handle forbidden error

    customToast(message: error);
  } else if (response.statusCode == 401) {
    // Handle unauthorized error

    customToast(message: error);
  } else if (response.statusCode == 404) {
    // Handle not found error

    customToast(message: error);
  } else if (response.statusCode >= 500) {
    // Handle server errors

    customToast(message: error);
  } else {
    // Handle other errors

    customToast(message: 'Error: $error');
  }
  // throw errorMessage ?? '';
  return;
}
