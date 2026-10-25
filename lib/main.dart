import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'l10n/language_controller.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BusinessWebsiteApp());
}

class BusinessWebsiteApp extends StatelessWidget {
  const BusinessWebsiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageController.instance,
      builder: (context, _) {
        final bool isArabic = LanguageController.instance.isArabic;
        final AppStrings strings = AppStrings(isArabic);

        return MaterialApp(
          title: strings.businessName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,

          // Keeps the layout stable (fixed text scale) and switches the
          // whole website between left-to-right and right-to-left.
          builder: (context, child) {
            return Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),

                // FIX for Instagram / Facebook / other in-app browsers on
                // Android. In some Flutter 3.4x versions the web engine reads
                // a wrong "line height" from those browsers, which makes every
                // line of text enormously tall: text disappears, the page
                // stretches and everything is pushed off-screen. Clearing the
                // browser-provided text overrides avoids it.
                // (Flutter issue #190350.)
                child: MediaQuery.applyTextStyleOverrides(
                  lineHeightScaleFactorOverride: null,
                  letterSpacingOverride: null,
                  wordSpacingOverride: null,
                  paragraphSpacingOverride: null,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },

          home: const HomePage(),
        );
      },
    );
  }
}
