import 'package:flutter/material.dart';

final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
bool get isDarkMode => themeMode.value == ThemeMode.dark;
void toggleTheme() {
  themeMode.value =
      themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
