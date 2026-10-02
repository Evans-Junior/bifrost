import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import 'settings/app_settings.dart';
import 'settings/settings_repository.dart';
import 'ui/home_screen.dart';

/// Root widget. The UI language follows the language in Settings.
class BifrostApp extends ConsumerWidget {
  const BifrostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(settingsProvider).value?.language ?? AppLanguage.en;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      supportedLocales: const [Locale('en', 'CA'), Locale('fr', 'CA')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
