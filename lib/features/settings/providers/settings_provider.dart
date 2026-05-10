import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, arabic }

class SettingsState {
  final bool isDarkMode;
  final AppLanguage language;

  const SettingsState({
    this.isDarkMode = true,
    this.language = AppLanguage.english,
  });

  SettingsState copyWith({bool? isDarkMode, AppLanguage? language}) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    final langIndex = prefs.getInt('language') ?? 0;
    final language = AppLanguage.values[langIndex];
    state = SettingsState(
      isDarkMode: isDark,
      language: language,
    );
    // Update locale when loading settings
    final newLocale = language == AppLanguage.arabic
        ? const Locale('ar')
        : const Locale('en');
    ref.read(localeProvider.notifier).setLocale(newLocale);
  }

  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newValue);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    final newLocale = language == AppLanguage.arabic
        ? const Locale('ar')
        : const Locale('en');
    ref.read(localeProvider.notifier).setLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language', language.index);
  }
}

final settingsNotifierProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});