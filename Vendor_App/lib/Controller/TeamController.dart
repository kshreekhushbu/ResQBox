import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resqboxvendor/Models/team_member_model.dart';
import 'package:resqboxvendor/Services/AppUrls.dart';
import 'package:resqboxvendor/Services/api.dart';
import 'package:resqboxvendor/Services/dynamic_response.dart';
import 'package:resqboxvendor/Utils/toast.dart';

class TeamController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Profile Photo
  File? profilePhoto;
  String? uploadedProfilePhotoFileName;
  String? displayedProfilePhotoUrl;

  // Team Members List
  List<TeamMember> teamMembers = [];
  bool isLoadingTeamMembers = false;

  // Selected Team Member for Edit
  TeamMember? selectedTeamMember;
  bool isEditMode = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Email validation state
  String? emailValidationMessage;
  bool isCheckingEmail = false;

  // Pick Profile Photo
  Future<void> pickProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        profilePhoto = File(picked.path);
        displayedProfilePhotoUrl =
            null; // Clear displayed URL when new image is selected
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error picking profile photo: $e");
      customToast(message: "Failed to pick image");
    }
  }

  // Upload Profile Photo
  Future<String?> uploadProfilePhoto() async {
    // If no new image selected, return existing image filename (for edit mode)
    if (profilePhoto == null) {
      if (uploadedProfilePhotoFileName != null &&
          uploadedProfilePhotoFileName!.isNotEmpty) {
        debugPrint("✅ Using existing image: $uploadedProfilePhotoFileName");
        return uploadedProfilePhotoFileName;
      }
      // Profile photo is optional, so return empty string if not provided
      return "";
    }

    try {
      EasyLoading.show();
      final url = '${Api.baseUrl}vendor/upload';

      final result = await ApiService().uploadImage(
        url: url,
        file: profilePhoto!,
        folder: "team",
        fieldName: "file",
      );

      if (result != null && result['fileName'] != null) {
        uploadedProfilePhotoFileName = result['fileName'];
        // Also store the full URL if provided
        if (result['fileUrl'] != null) {
          displayedProfilePhotoUrl = result['fileUrl'];
        } else {
          displayedProfilePhotoUrl = result['fileName'];
        }
        debugPrint("✅ Profile photo uploaded: ${result['fileName']}");
        return result['fileName'];
      } else {
        customToast(message: "Failed to upload profile photo");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error uploading profile photo: $e");
      customToast(message: "Failed to upload profile photo");
      return null;
    } finally {
      EasyLoading.dismiss();
    }
  }

  // Validate Form (for add)
  bool validateForm() {
    if (firstNameController.text.trim().isEmpty) {
      customToast(message: "Please enter first name");
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      customToast(message: "Please enter last name");
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      customToast(message: "Please enter email address");
      return false;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      customToast(message: "Please enter a valid email address");
      return false;
    }

    if (userNameController.text.trim().isEmpty) {
      customToast(message: "Please enter username");
      return false;
    }
    if (!isEditMode && passwordController.text.trim().isEmpty) {
      customToast(message: "Please enter password");
      return false;
    }
    if (!isEditMode &&
        passwordController.text.trim().length < 6 &&
        passwordController.text.trim().isNotEmpty) {
      customToast(message: "Password must be at least 6 characters");
      return false;
    }
    return true;
  }

  // Validate Form for Update (password optional)
  bool validateUpdateForm() {
    if (firstNameController.text.trim().isEmpty) {
      customToast(message: "Please enter first name");
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      customToast(message: "Please enter last name");
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      customToast(message: "Please enter email address");
      return false;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      customToast(message: "Please enter a valid email address");
      return false;
    }

    if (userNameController.text.trim().isEmpty) {
      customToast(message: "Please enter username");
      return false;
    }
    return true;
  }

  // Add Team Member
  Future<bool> addTeamMember() async {
    try {
      if (!validateForm()) {
        return false;
      }

      _isLoading = true;
      notifyListeners();
      EasyLoading.show();

      // Upload profile photo if selected
      String? profilePhotoFileName = "";
      if (profilePhoto != null) {
        final uploaded = await uploadProfilePhoto();
        if (uploaded == null) {
          EasyLoading.dismiss();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        profilePhotoFileName = uploaded;
      }

      // Prepare request body
      final body = {
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "username": userNameController.text.trim(),
        "password": passwordController.text.trim(),
        "profilePhoto": profilePhotoFileName,
      };

      debugPrint("📤 Add Team Member Request: $body");

      final url = '${Api.baseUrl}${AppUrls.addTeamMember}';
      final response = await ApiService().postRequest(url, body);

      debugPrint("📥 Add Team Member Response: $response");

      if (response != null &&
          (response['status'] == 1 || response['Status'] == 1)) {
        customToast(
          message: response['message'] ?? "Team member added successfully",
        );
        resetForm();
        await getTeamMembers(); // Refresh list
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        customToast(
          message: response?['message'] ?? "Failed to add team member",
        );
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error adding team member: $e");
      customToast(message: "Failed to add team member");
      EasyLoading.dismiss();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get All Team Members
  Future<void> getTeamMembers() async {
    try {
      isLoadingTeamMembers = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.getTeamMembers}';
      debugPrint("📤 Get Team Members URL: $url");

      final response = await ApiService().getRequest(url);

      debugPrint("📥 Get Team Members Response: $response");

      if (response != null &&
          (response['status'] == 1 || response['Status'] == 1)) {
        final teamMemberResponse = TeamMemberResponse.fromJson(response);
        teamMembers = teamMemberResponse.members ?? [];
        debugPrint("✅ Loaded ${teamMembers.length} team members");
      } else {
        teamMembers = [];
        customToast(
          message: response?['message'] ?? "Failed to load team members",
        );
      }
    } catch (e) {
      debugPrint("❌ Error getting team members: $e");
      teamMembers = [];
      customToast(message: "Failed to load team members");
    } finally {
      isLoadingTeamMembers = false;
      notifyListeners();
    }
  }

  // Get Team Member by ID
  Future<TeamMember?> getTeamMemberById(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      EasyLoading.show();

      final url = '${Api.baseUrl}${AppUrls.getTeamMemberById}/$id';
      debugPrint("📤 Get Team Member by ID URL: $url");

      final response = await ApiService().getRequest(url);

      debugPrint("📥 Get Team Member by ID Response: $response");

      if (response != null &&
          (response['status'] == 1 || response['Status'] == 1)) {
        final teamMemberDetailResponse = TeamMemberDetailResponse.fromJson(
          response,
        );
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return teamMemberDetailResponse.member;
      } else {
        customToast(
          message: response?['message'] ?? "Failed to load team member",
        );
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error getting team member by ID: $e");
      customToast(message: "Failed to load team member");
      EasyLoading.dismiss();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load Team Member for Editing
  Future<void> loadTeamMemberForEditing(TeamMember member) async {
    selectedTeamMember = member;
    isEditMode = true;

    firstNameController.text = member.firstName ?? "";
    lastNameController.text = member.lastName ?? "";
    emailController.text = member.email ?? "";
    phoneController.text = member.phoneNumber ?? "";
    userNameController.text = member.username ?? "";
    passwordController.clear(); // Don't pre-fill password

    // Set profile photo URL if exists
    if (member.profilePhoto != null && member.profilePhoto!.isNotEmpty) {
      uploadedProfilePhotoFileName = member.profilePhoto;
      // Construct full URL if needed
      displayedProfilePhotoUrl = member.profilePhoto;
    } else {
      uploadedProfilePhotoFileName = null;
      displayedProfilePhotoUrl = null;
    }

    profilePhoto = null; // Reset local image
    notifyListeners();
  }

  // Update Team Member
  Future<bool> updateTeamMember(int id) async {
    try {
      if (!validateUpdateForm()) {
        return false;
      }

      _isLoading = true;
      notifyListeners();
      EasyLoading.show();

      // Upload profile photo if a new one is selected
      String? profilePhotoFileName = uploadedProfilePhotoFileName;
      if (profilePhoto != null) {
        final uploaded = await uploadProfilePhoto();
        if (uploaded == null) {
          EasyLoading.dismiss();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        profilePhotoFileName = uploaded;
      }

      // Prepare request body (password not included in update)
      final body = {
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "username": userNameController.text.trim(),
        "profilePhoto": profilePhotoFileName ?? "",
      };

      debugPrint("📤 Update Team Member Request: $body");

      final url = '${Api.baseUrl}${AppUrls.updateTeamMember}/$id';
      final response = await ApiService().putRequest(url, body);

      debugPrint("📥 Update Team Member Response: $response");

      if (response != null &&
          (response['status'] == 1 || response['Status'] == 1)) {
        customToast(
          message: response['message'] ?? "Team member updated successfully",
        );
        resetForm();
        await getTeamMembers(); // Refresh list
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        customToast(
          message: response?['message'] ?? "Failed to update team member",
        );
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error updating team member: $e");
      customToast(message: "Failed to update team member");
      EasyLoading.dismiss();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete Team Member
  Future<bool> deleteTeamMember(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      EasyLoading.show();

      final url = '${Api.baseUrl}${AppUrls.deleteTeamMember}/$id';
      debugPrint("📤 Delete Team Member URL: $url");

      final response = await ApiService().deleteRequest(url);

      debugPrint("📥 Delete Team Member Response: $response");

      if (response != null &&
          (response['status'] == 1 || response['Status'] == 1)) {
        customToast(
          message: response['message'] ?? "Team member deleted successfully",
        );
        await getTeamMembers(); // Refresh list
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        customToast(
          message: response?['message'] ?? "Failed to delete team member",
        );
        EasyLoading.dismiss();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error deleting team member: $e");
      customToast(message: "Failed to delete team member");
      EasyLoading.dismiss();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset Form
  void resetForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    userNameController.clear();
    passwordController.clear();
    profilePhoto = null;
    uploadedProfilePhotoFileName = null;
    displayedProfilePhotoUrl = null;
    selectedTeamMember = null;
    isEditMode = false;
    notifyListeners();
  }

  // Check if email already exists
  Future<void> checkEmailExists(String email) async {
    if (email.trim().isEmpty) {
      emailValidationMessage = null;
      notifyListeners();
      return;
    }

    // Basic email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emailValidationMessage = null;
      notifyListeners();
      return;
    }

    try {
      isCheckingEmail = true;
      notifyListeners();

      final url = '${Api.baseUrl}${AppUrls.checkEmailExists}';
      debugPrint("📤 Check Email Exists URL: $url");

      final payload = {"email": email.trim()};
      debugPrint("📤 Payload: $payload");

      final res = await ApiService().postRequest(url, payload);
      debugPrint("📥 Check Email Response: $res");

      if (res != null) {
        if (res['exists'] == true || res['status'] == 0) {
          emailValidationMessage = "❌ Email already exists";
        } else {
          // emailValidationMessage = "✅ Email available";
        }
      }
    } catch (e) {
      debugPrint("❌ Error checking email: $e");
      emailValidationMessage = null;
    } finally {
      isCheckingEmail = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
