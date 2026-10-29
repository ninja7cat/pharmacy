// Saves the visitor's chosen language in the browser, so the site opens in
// the same language next time. On non-web builds nothing is stored.
export 'language_storage_stub.dart'
    if (dart.library.js_interop) 'language_storage_web.dart';
