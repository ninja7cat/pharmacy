import 'package:flutter/foundation.dart';

import 'language_storage.dart';

/// Holds the current website language.
///
/// The first language is the one the visitor picked on an earlier visit.
/// On a first visit it comes from the browser/device: Arabic browsers open
/// the Arabic site, everyone else gets English.
class LanguageController extends ChangeNotifier {
  LanguageController._()
    : _isArabic = switch (readSavedLanguage()) {
        'ar' => true,
        'en' => false,
        _ => PlatformDispatcher.instance.locale.languageCode == 'ar',
      };

  static final LanguageController instance = LanguageController._();

  bool _isArabic;

  bool get isArabic => _isArabic;

  void toggle() {
    _isArabic = !_isArabic;
    saveLanguage(_isArabic ? 'ar' : 'en');
    notifyListeners();
  }

  void setArabic(bool value) {
    if (_isArabic == value) {
      return;
    }

    _isArabic = value;
    saveLanguage(_isArabic ? 'ar' : 'en');
    notifyListeners();
  }
}
