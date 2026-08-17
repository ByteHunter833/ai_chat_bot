import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nova_ai/core/theme/domain/theme_preference.dart';

class ThemeState extends Equatable {
  final ThemePreference preference;

  const ThemeState({required this.preference});

  ThemeMode get themeMode => switch (preference) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      };

  @override
  List<Object?> get props => [preference];
}