import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app language (`en` / `ar`). Default English.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({SharedPreferences? prefs})
      : _prefs = prefs,
        super(AppLocales.english);

  static const _prefsKey = 'app_locale';

  SharedPreferences? _prefs;

  bool get isArabic => state.languageCode == 'ar';

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final code = _prefs!.getString(_prefsKey);
    if (code == 'ar') {
      emit(AppLocales.arabic);
    } else {
      emit(AppLocales.english);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'ar') return;
    if (state.languageCode == locale.languageCode) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_prefsKey, locale.languageCode);
    emit(Locale(locale.languageCode));
  }

  Future<void> toggle() async {
    await setLocale(isArabic ? AppLocales.english : AppLocales.arabic);
  }
}

abstract final class AppLocales {
  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const supported = <Locale>[english, arabic];
}
