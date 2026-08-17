enum ThemePreference { system, light, dark }

extension ThemePreferenceX on ThemePreference {
  static ThemePreference fromName(String? name) {
    return ThemePreference.values.firstWhere(
      (preference) => preference.name == name,
      orElse: () => ThemePreference.system,
    );
  }
}