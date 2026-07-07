import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static SharedPreferencesHelper? _instance;
  static SharedPreferences? _preferences;

  static Future<SharedPreferencesHelper> getInstance() async {
    _instance ??= SharedPreferencesHelper();

    _preferences ??= await SharedPreferences.getInstance();

    return _instance!;
  }

  // Example method: Saving a string value
  Future<void> saveString(String key, String value) async {
    await _preferences!.setString(key, value);
  }

  Future<void> saveInt(String key, int value) async {
    await _preferences!.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  // Example method: Retrieving a string value
  String? getString(String key) {
    return _preferences!.getString(key);
  }

  // Example method: Removing a value
  Future<void> remove(String key) async {
    await _preferences!.remove(key);
  } // Example method: Removing a value

  Future<void> clearAlldata() async {
    await _preferences?.clear();
  }
}
