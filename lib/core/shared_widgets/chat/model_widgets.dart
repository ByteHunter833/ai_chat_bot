import 'package:flutter/material.dart';

Widget buildModelChip(String model, ColorScheme colorScheme) {
  return FilterChip(
    label: Text(model),
    onSelected: (_) {},
    backgroundColor: colorScheme.secondaryContainer,
    labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
  );
}

Widget buildMediaButton(
  IconData icon,
  String label,
  ColorScheme colorScheme,
  VoidCallback onPressed,
) {
  return Expanded(
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
  );
}
