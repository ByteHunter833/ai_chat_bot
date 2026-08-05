import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:nova_ai/core/theme/cubit/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.light));

  void toggle() {
    emit(
      ThemeState(
        themeMode: state.themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light,
      ),
    );
  }
}
