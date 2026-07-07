// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:http/http.dart' as HttpMethod;
// import 'package:image_picker/image_picker.dart';
// import 'package:mime/mime.dart';
// import 'package:zoviyo/Utils/toast.dart';

// import '../Services/dynamic_response.dart';

// class ImageUploadController extends ChangeNotifier {
//   Future<String?> getPresignedKeys({
//     required Map<dynamic, dynamic> body,
//   }) async {
//     try {
//       final file = body['file'];
//       final fileDetails = await getFileDetails(file);

//       print('object');

//       if (fileDetails.isEmpty) return null;

//       body['mimetype'] = fileDetails['mimetype'];
//       body['fileSize'] = fileDetails['fileSize'].toString();
//       // body.addAll(fileDetails);
//       body.addAll(
//         fileDetails.map<String, String>((key, value) {
//           return MapEntry(key.toString(), value.toString());
//         }),
//       );

//       // Get upload success and file name
//       final uploadedFileName = await makeRequest(body: body);
//       if (uploadedFileName == null) {
//         throw Exception('Upload failed');
//       }
//       return uploadedFileName;
//     } catch (e) {
//       // CustomLoader().hide();
//       EasyLoading.dismiss();
//       debugPrint('getPresignedKeys error: $e');
//       // CustomToast().showToast(message: 'Something went wrong during upload.');
//       // return null;
//       rethrow;
//     }
//   }

//   Future<Map<String, dynamic>> getFileDetails(dynamic file) async {
//     try {
//       late String mimeType;
//       late int fileSize;

//       if (file is File) {
//         mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
//         fileSize = await file.length();
//       } else if (file is XFile) {
//         mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
//         fileSize = await file.length();
//       } else if (file is String) {
//         final fileObj = File(file);
//         mimeType = lookupMimeType(file) ?? 'application/octet-stream';
//         fileSize = await fileObj.length();
//       } else {
//         customToast(message: 'Unsupported file type');
//         return {};
//       }

//       return {'mimetype': mimeType, 'fileSize': fileSize.toDouble()};
//     } catch (e) {
//       debugPrint('getFileDetails error: $e');
//       customToast(message: 'File analysis failed.');
//       return {};
//     }
//   }

//   Future<bool> s3Upload({required Map<dynamic, dynamic> body}) async {
//     try {
//       return await multipartApiResponse(body: body);
//     } catch (e) {
//       debugPrint('s3Upload error: $e');
//       customToast(message: 'S3 upload failed.');
//       return false;
//     }
//   }

//   Future<String?> makeRequest({
//     required Map<dynamic, dynamic> body,
//     bool isS3Upload = false,
//   }) async {
//     try {
//       final url = isS3Upload ? Apis.s3Url : Apis.generatePresignedUrl;
//       const requestType = HttpMethod.post;

//       print(url);
//       print('url');

//       final value = await DynamicResponse().apiResponse(
//         requestType: requestType,
//         url: url,
//         body: body,
//       );

//       if (value != null) {
//         final responseModel = PresignedKeysModel.fromJson(value);
//         if (responseModel.status == 1) {
//           final s3Body = {
//             "Content-Type": body['mimetype'],
//             "bucket": responseModel.url?.fields?.bucket,
//             "X-Amz-Signature": responseModel.url?.fields?.xAmzSignature,
//             "Policy": responseModel.url?.fields?.policy,
//             "key": responseModel.url?.fields?.key,
//             if (responseModel.url?.fields?.xAmzSecurityToken != null)
//               "X-Amz-Security-Token":
//                   responseModel.url?.fields?.xAmzSecurityToken,
//             "X-Amz-Date": responseModel.url?.fields?.xAmzDate,
//             "X-Amz-Credential": responseModel.url?.fields?.xAmzCredential,
//             "X-Amz-Algorithm": responseModel.url?.fields?.xAmzAlgorithm,
//             "file": body['file'],
//           };

//           final success = await s3Upload(body: s3Body);

//           return success ? responseModel.url?.fields?.key : null;
//         } else {
//           final res = ResponseModel.fromJson(value);
//           CustomToast().showToast(message: res.message ?? 'Upload failed');
//         }
//       }
//     } catch (e) {
//       debugPrint('makeRequest error: $e');
//       CustomToast().showToast(message: 'Failed to get upload keys.');
//     }

//     return null;
//   }

//   Future<bool> multipartApiResponse({
//     required Map<dynamic, dynamic> body,
//   }) async {
//     try {
//       const requestType = HttpMethod.post;
//       const url = Apis.s3Url;

//       final value = await DynamicResponse().multipartApiResponse(
//         requestType: requestType,
//         url: url,
//         removeBaseUrl: true,
//         ignoreToken: true,
//         fields: body,
//       );

//       if (value != null) {
//         debugPrint('S3 Upload Response: $value');
//         return true;
//       }
//     } catch (e) {
//       debugPrint('multipartApiResponse error: $e');
//     }

//     return false;
//   }
// }
