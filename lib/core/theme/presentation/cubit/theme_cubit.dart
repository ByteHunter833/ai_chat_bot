import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:nova_ai/core/theme/domain/theme_preference.dart';
import 'package:nova_ai/core/theme/domain/theme_repository.dart';
import 'package:nova_ai/core/theme/presentation/cubit/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository themeRepository;

  ThemeCubit(this.themeRepository)
    : super(const ThemeState(preference: ThemePreference.system)) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final preference = await themeRepository.getThemePreference();
    if (isClosed) return;
    emit(ThemeState(preference: preference));
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    emit(ThemeState(preference: preference));
    await themeRepository.setThemePreference(preference);
  }

  Future<void> toggle(Brightness currentBrightness) {
    return setThemePreference(
      currentBrightness == Brightness.dark
          ? ThemePreference.light
          : ThemePreference.dark,
    );
  }
}