import 'package:web/web.dart' as web;

const String _key = 'diane_language';

/// The language code saved on a previous visit ('ar' or 'en'), if any.
String? readSavedLanguage() {
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    // Storage can be blocked (private mode, some in-app browsers).
    return null;
  }
}

void saveLanguage(String code) {
  try {
    web.window.localStorage.setItem(_key, code);
  } catch (_) {
    // Not saving is fine: the site still works, it just won't remember.
  }
}
