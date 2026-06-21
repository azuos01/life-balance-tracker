import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

const _kThemeKey = 'settings_theme';
const _kLocaleKey = 'settings_locale';
const _kOpenAIKeyKey = 'settings_openai_key';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'pt';
  String? _openAIKey;

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  String? get openAIKey => _openAIKey?.isEmpty ?? true ? null : _openAIKey;
  bool get hasOpenAIKey => openAIKey != null;

  /// Carrega preferências salvas. Chamar antes de runApp.
  Future<void> init() async {
    final stored = StorageService.instance.getString(_kThemeKey);
    _themeMode = switch (stored) {
      'light' => ThemeMode.light,
      _ => ThemeMode.dark,
    };
    _locale = StorageService.instance.getString(_kLocaleKey) ?? 'pt';
    _openAIKey = StorageService.instance.getString(_kOpenAIKeyKey);
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

  Future<void> setOpenAIKey(String? key) async {
    _openAIKey = key?.trim();
    if (_openAIKey != null && _openAIKey!.isNotEmpty) {
      await StorageService.instance.setString(_kOpenAIKeyKey, _openAIKey!);
    } else {
      await StorageService.instance.remove(_kOpenAIKeyKey);
      _openAIKey = null;
    }
    notifyListeners();
  }
}
