import 'package:nova_ai/core/theme/data/theme_local_data_source.dart';
import 'package:nova_ai/core/theme/domain/theme_preference.dart';
import 'package:nova_ai/core/theme/domain/theme_repository.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl(this.localDataSource);

  @override
  Future<ThemePreference> getThemePreference() async {
    final stored = await localDataSource.readPreference();
    return ThemePreferenceX.fromName(stored);
  }

  @override
  Future<void> setThemePreference(ThemePreference preference) {
    return localDataSource.writePreference(preference.name);
  }
}