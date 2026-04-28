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
    state = SettingsState(
      isDarkMode: isDark,
      language: AppLanguage.values[langIndex],
    );
  }

  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newValue);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    ref.read(localeProvider.notifier).state = language == AppLanguage.arabic 
        ? const Locale('ar') 
        : const Locale('en');
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
    final settings = ref.watch(settingsNotifierProvider);
    return settings.language == AppLanguage.arabic ? 
      const Locale('ar') : 
      const Locale('en');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});