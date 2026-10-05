import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import 'settings/app_settings.dart';
import 'settings/settings_repository.dart';
import 'ui/home_screen.dart';
import 'ui/onboarding_screen.dart';

/// Root widget. The UI language follows Settings; the low-vision profile
/// switches to a high-contrast, large-text theme (Section 10). First run
/// shows the spoken onboarding.
class BifrostApp extends ConsumerWidget {
  const BifrostApp({super.key});

  /// Debug demo runs skip onboarding (see HomeScreen).
  static const _demo = bool.fromEnvironment('BIFROST_DEMO');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final language = settings?.language ?? AppLanguage.en;
    final lowVision = settings?.profile == VisionProfile.lowVision;
    final Widget home;
    if (settings == null) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (!settings.onboardingDone && !(kDebugMode && _demo)) {
      home = const OnboardingScreen();
    } else {
      home = const HomeScreen();
    }
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      supportedLocales: const [Locale('en', 'CA'), Locale('fr', 'CA')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: lowVision ? _highContrastTheme() : _standardTheme(),
      builder: (context, child) => lowVision
          ? MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            )
          : child!,
      home: home,
    );
  }

  static ThemeData _standardTheme() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.amber,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  /// Yellow on black, thick outlines: readable with low vision.
  static ThemeData _highContrastTheme() {
    const yellow = Color(0xFFFFE600);
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastDark(
        primary: yellow,
        onPrimary: Colors.black,
        secondary: yellow,
        surface: Colors.black,
        onSurface: yellow,
      ),
      scaffoldBackgroundColor: Colors.black,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: yellow,
        displayColor: yellow,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: yellow,
          side: const BorderSide(color: yellow, width: 3),
        ),
      ),
    );
  }
}
