import 'package:flutter/foundation.dart';

/// Holds the current website language.
///
/// The first language is taken from the visitor's browser/device:
/// Arabic browsers open the Arabic site, everyone else gets English.
class LanguageController extends ChangeNotifier {
  LanguageController._()
    : _isArabic = PlatformDispatcher.instance.locale.languageCode == 'ar';

  static final LanguageController instance = LanguageController._();

  bool _isArabic;

  bool get isArabic => _isArabic;

  void toggle() {
    _isArabic = !_isArabic;
    notifyListeners();
  }

  void setArabic(bool value) {
    if (_isArabic == value) {
      return;
    }

    _isArabic = value;
    notifyListeners();
  }
}
