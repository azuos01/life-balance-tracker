import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

const _kThemeKey = 'settings_theme';
const _kLocaleKey = 'settings_locale';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'pt';

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;

  /// Carrega preferências salvas. Chamar antes de runApp.
  Future<void> init() async {
    final stored = StorageService.instance.getString(_kThemeKey);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    _locale = StorageService.instance.getString(_kLocaleKey) ?? 'pt';
    AppTheme.setDark(_themeMode == ThemeMode.dark);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    AppTheme.setDark(mode == ThemeMode.dark);
    await StorageService.instance.setString(
        _kThemeKey, mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    await StorageService.instance.setString(_kLocaleKey, locale);
    notifyListeners();
  }
}
