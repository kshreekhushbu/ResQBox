import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static SharedPreferencesHelper? _instance;
  static SharedPreferences? _preferences;

  static Future<SharedPreferencesHelper> getInstance() async {
    _instance ??= SharedPreferencesHelper();

    _preferences ??= await SharedPreferences.getInstance();

    return _instance!;
  }

  Future<void> saveString(String key, String value) async {
    await _preferences!.setString(key, value);
  }

  Future<void> saveInt(String key, int value) async {
    await _preferences!.setInt(key, value);
  }

  int? getInt(String key) {
    return _preferences!.getInt(key);
  }

  String? getString(String key) {
    return _preferences!.getString(key);
    // return _preferences!.getString(
    //   "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Miwicm9sZSI6IktJVENIRU4iLCJpYXQiOjE3NjM5ODg5MjMsImV4cCI6MTc2NDg1MjkyM30.EYTJ0C6O3ZpIF9GGRIJh1a-niJFzPN7ysfwwxqcgUfc",
    // );
  }

  Future<void> remove(String key) async {
    await _preferences!.remove(key);
  }

  Future<void> clearAlldata() async {
    await _preferences?.clear();
  }

  // Initialize if not already initialized
  Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // Boolean methods
  Future<bool> saveBool(String key, bool value) async {
    await init();
    return await _preferences!.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _preferences!.getBool(key);
  }

  // Double methods
  Future<bool> saveDouble(String key, double value) async {
    await init();
    return await _preferences!.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    await init();
    return _preferences!.getDouble(key);
  }

  // List<String> methods
  Future<bool> saveStringList(String key, List<String> value) async {
    await init();
    return await _preferences!.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    await init();
    return _preferences!.getStringList(key);
  }

  // Clear all preferences
  Future<bool> clear() async {
    await init();
    return await _preferences!.clear();
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    await init();
    return _preferences!.containsKey(key);
  }

  // Get all keys
  Future<Set<String>> getKeys() async {
    await init();
    return _preferences!.getKeys();
  }
}
