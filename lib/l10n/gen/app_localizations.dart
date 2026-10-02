import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BIFROST'**
  String get appTitle;

  /// No description provided for @holdToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to talk'**
  String get holdToTalk;

  /// No description provided for @holdToTalkHint.
  ///
  /// In en, this message translates to:
  /// **'Hold to ask, release to send. With a screen reader, double tap to start and double tap again to send.'**
  String get holdToTalkHint;

  /// No description provided for @cameraPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera view, pointed at the objects in front of the phone.'**
  String get cameraPreviewLabel;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get statusListening;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// No description provided for @statusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get statusSpeaking;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t connect'**
  String get statusOffline;

  /// No description provided for @statusNoCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get statusNoCamera;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t get an answer. Try again.'**
  String get timeout;

  /// No description provided for @lostTrack.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I lost track. Ask again.'**
  String get lostTrack;

  /// No description provided for @cannotConnect.
  ///
  /// In en, this message translates to:
  /// **'I can\'t connect to the server. Try again.'**
  String get cannotConnect;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'The server is not set up yet. Open Settings to add it.'**
  String get notConfigured;

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'I can\'t use the camera right now.'**
  String get noCamera;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t take a picture. Try again.'**
  String get noImage;

  /// No description provided for @didNotHear.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t hear a question. Hold the button and speak.'**
  String get didNotHear;

  /// No description provided for @noMicrophone.
  ///
  /// In en, this message translates to:
  /// **'I can\'t use the microphone right now.'**
  String get noMicrophone;

  /// No description provided for @referentFallback.
  ///
  /// In en, this message translates to:
  /// **'The item in front of the camera'**
  String get referentFallback;

  /// No description provided for @referentWithLocation.
  ///
  /// In en, this message translates to:
  /// **'{label}, {location}.'**
  String referentWithLocation(String label, String location);

  /// No description provided for @referentOnly.
  ///
  /// In en, this message translates to:
  /// **'{label}.'**
  String referentOnly(String label);

  /// No description provided for @confidenceRead.
  ///
  /// In en, this message translates to:
  /// **'I read it on the label.'**
  String get confidenceRead;

  /// No description provided for @confidenceThink.
  ///
  /// In en, this message translates to:
  /// **'I think so, because {reason}.'**
  String confidenceThink(String reason);

  /// No description provided for @confidenceThinkNoReason.
  ///
  /// In en, this message translates to:
  /// **'I\'m not fully sure.'**
  String get confidenceThinkNoReason;

  /// No description provided for @cantSee.
  ///
  /// In en, this message translates to:
  /// **'I can\'t see enough to tell.'**
  String get cantSee;

  /// No description provided for @cantSeeDefaultAction.
  ///
  /// In en, this message translates to:
  /// **'Turn it slowly in your hand.'**
  String get cantSeeDefaultAction;

  /// No description provided for @clarification.
  ///
  /// In en, this message translates to:
  /// **'{optionA} or {optionB}?'**
  String clarification(String optionA, String optionB);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// No description provided for @settingsBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Model base URL'**
  String get settingsBaseUrl;

  /// No description provided for @settingsModelName.
  ///
  /// In en, this message translates to:
  /// **'Model name'**
  String get settingsModelName;

  /// No description provided for @settingsApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsApiKey;

  /// No description provided for @settingsReasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort'**
  String get settingsReasoning;

  /// No description provided for @settingsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout in seconds'**
  String get settingsTimeout;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice and language'**
  String get settingsVoice;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSpeechRate.
  ///
  /// In en, this message translates to:
  /// **'Speech rate'**
  String get settingsSpeechRate;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Vision profile'**
  String get settingsProfile;

  /// No description provided for @settingsProfileBlind.
  ///
  /// In en, this message translates to:
  /// **'Blind'**
  String get settingsProfileBlind;

  /// No description provided for @settingsProfileLowVision.
  ///
  /// In en, this message translates to:
  /// **'Low vision'**
  String get settingsProfileLowVision;

  /// No description provided for @settingsPositionStyle.
  ///
  /// In en, this message translates to:
  /// **'Position style'**
  String get settingsPositionStyle;

  /// No description provided for @settingsPositionClock.
  ///
  /// In en, this message translates to:
  /// **'Clock face'**
  String get settingsPositionClock;

  /// No description provided for @settingsPositionLeftRight.
  ///
  /// In en, this message translates to:
  /// **'Left and right'**
  String get settingsPositionLeftRight;

  /// No description provided for @settingsFromEnv.
  ///
  /// In en, this message translates to:
  /// **'Set in the .env file'**
  String get settingsFromEnv;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @reasonLabelHardToRead.
  ///
  /// In en, this message translates to:
  /// **'the label is hard to read'**
  String get reasonLabelHardToRead;

  /// No description provided for @challengeStillRead.
  ///
  /// In en, this message translates to:
  /// **'I still read {text} on this one.'**
  String challengeStillRead(String text);

  /// No description provided for @challengeStillThink.
  ///
  /// In en, this message translates to:
  /// **'I still think it\'s {identity}.'**
  String challengeStillThink(String identity);

  /// No description provided for @challengeChanged.
  ///
  /// In en, this message translates to:
  /// **'Now I read {text}. I was wrong before.'**
  String challengeChanged(String text);

  /// No description provided for @taskRegistered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{I don\'t see any items yet.} =1{1 item.} other{{count} items, numbered from left to right.}}'**
  String taskRegistered(int count);

  /// No description provided for @statusNoTask.
  ///
  /// In en, this message translates to:
  /// **'No task yet. You can say: help me sort these.'**
  String get statusNoTask;

  /// No description provided for @statusFinding.
  ///
  /// In en, this message translates to:
  /// **'Looking for {goal}.'**
  String statusFinding(String goal);

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {items}.'**
  String statusDone(String items);

  /// No description provided for @statusLeft.
  ///
  /// In en, this message translates to:
  /// **'Left: {items}.'**
  String statusLeft(String items);

  /// No description provided for @statusNothingDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing done yet.'**
  String get statusNothingDone;

  /// No description provided for @statusNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left. All done.'**
  String get statusNothingLeft;

  /// No description provided for @statusItem.
  ///
  /// In en, this message translates to:
  /// **'{label} is {identity}'**
  String statusItem(String label, String identity);

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get listAnd;

  /// No description provided for @moreNone.
  ///
  /// In en, this message translates to:
  /// **'I have no more detail.'**
  String get moreNone;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'I haven\'t said anything yet.'**
  String get repeatNone;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped.'**
  String get stopped;

  /// No description provided for @watchNotReady.
  ///
  /// In en, this message translates to:
  /// **'Watch mode isn\'t available yet.'**
  String get watchNotReady;

  /// No description provided for @itemNoun.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get itemNoun;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
