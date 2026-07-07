import 'package:resqboxvendor/Utils/shared_preference_helper.dart';

class AccessHelper {
  // Check if current user is a team member
  static Future<bool> isTeamMember() async {
    final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
    final value = await sharedPrefHelper.getBool('isTeamMember');
    final isTeam = value == true;
    print("🔍 AccessHelper.isTeamMember: $isTeam (raw value: $value)");
    return isTeam;
  }

  // Get team member ID
  static Future<int?> getTeamMemberId() async {
    final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
    return sharedPrefHelper.getInt('teamMemberId');
  }

  // Check if user has access to a feature
  static Future<bool> hasAccess(String feature) async {
    final isTeam = await isTeamMember();

    if (!isTeam) {
      return true; // Kitchen owner has full access
    }

    // Team members only have access to Orders and Menu
    final allowedFeatures = ['orders', 'menu'];
    return allowedFeatures.contains(feature.toLowerCase());
  }

  // Clear team member status (on logout)
  static Future<void> clearTeamMemberStatus() async {
    final sharedPrefHelper = await SharedPreferencesHelper.getInstance();
    await sharedPrefHelper.remove('isTeamMember');
    await sharedPrefHelper.remove('teamMemberId');
  }
}
