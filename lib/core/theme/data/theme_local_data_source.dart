import 'package:shared_preferences/shared_preferences.dart';

class ThemeLocalDataSource {
  static const String _preferenceKey = 'theme_preference';

  Future<String?> readPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferenceKey);
  }

  Future<void> writePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, value);
  }
}