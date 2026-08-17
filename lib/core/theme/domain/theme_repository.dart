import 'package:nova_ai/core/theme/domain/theme_preference.dart';

abstract class ThemeRepository {
  Future<ThemePreference> getThemePreference();

  Future<void> setThemePreference(ThemePreference preference);
}