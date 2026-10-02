// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BIFROST';

  @override
  String get holdToTalk => 'Hold to talk';

  @override
  String get holdToTalkHint =>
      'Hold to ask, release to send. With a screen reader, double tap to start and double tap again to send.';

  @override
  String get cameraPreviewLabel =>
      'Camera view, pointed at the objects in front of the phone.';

  @override
  String get openSettings => 'Settings';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusListening => 'Listening';

  @override
  String get statusChecking => 'Checking';

  @override
  String get statusSpeaking => 'Speaking';

  @override
  String get statusOffline => 'Can\'t connect';

  @override
  String get statusNoCamera => 'Camera unavailable';

  @override
  String get checking => 'Checking…';

  @override
  String get timeout => 'I couldn\'t get an answer. Try again.';

  @override
  String get lostTrack => 'Sorry, I lost track. Ask again.';

  @override
  String get cannotConnect => 'I can\'t connect to the server. Try again.';

  @override
  String get notConfigured =>
      'The server is not set up yet. Open Settings to add it.';

  @override
  String get noCamera => 'I can\'t use the camera right now.';

  @override
  String get noImage => 'I couldn\'t take a picture. Try again.';

  @override
  String get didNotHear =>
      'I didn\'t hear a question. Hold the button and speak.';

  @override
  String get noMicrophone => 'I can\'t use the microphone right now.';

  @override
  String get referentFallback => 'The item in front of the camera';

  @override
  String referentWithLocation(String label, String location) {
    return '$label, $location.';
  }

  @override
  String referentOnly(String label) {
    return '$label.';
  }

  @override
  String get confidenceRead => 'I read it on the label.';

  @override
  String confidenceThink(String reason) {
    return 'I think so, because $reason.';
  }

  @override
  String get confidenceThinkNoReason => 'I\'m not fully sure.';

  @override
  String get cantSee => 'I can\'t see enough to tell.';

  @override
  String get cantSeeDefaultAction => 'Turn it slowly in your hand.';

  @override
  String clarification(String optionA, String optionB) {
    return '$optionA or $optionB?';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsBaseUrl => 'Model base URL';

  @override
  String get settingsModelName => 'Model name';

  @override
  String get settingsApiKey => 'API key';

  @override
  String get settingsReasoning => 'Reasoning effort';

  @override
  String get settingsTimeout => 'Timeout in seconds';

  @override
  String get settingsVoice => 'Voice and language';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSpeechRate => 'Speech rate';

  @override
  String get settingsProfile => 'Vision profile';

  @override
  String get settingsProfileBlind => 'Blind';

  @override
  String get settingsProfileLowVision => 'Low vision';

  @override
  String get settingsPositionStyle => 'Position style';

  @override
  String get settingsPositionClock => 'Clock face';

  @override
  String get settingsPositionLeftRight => 'Left and right';

  @override
  String get settingsFromEnv => 'Set in the .env file';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get reasonLabelHardToRead => 'the label is hard to read';

  @override
  String challengeStillRead(String text) {
    return 'I still read $text on this one.';
  }

  @override
  String challengeStillThink(String identity) {
    return 'I still think it\'s $identity.';
  }

  @override
  String challengeChanged(String text) {
    return 'Now I read $text. I was wrong before.';
  }

  @override
  String taskRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items, numbered from left to right.',
      one: '1 item.',
      zero: 'I don\'t see any items yet.',
    );
    return '$_temp0';
  }

  @override
  String get statusNoTask => 'No task yet. You can say: help me sort these.';

  @override
  String statusFinding(String goal) {
    return 'Looking for $goal.';
  }

  @override
  String statusDone(String items) {
    return 'Done: $items.';
  }

  @override
  String statusLeft(String items) {
    return 'Left: $items.';
  }

  @override
  String get statusNothingDone => 'Nothing done yet.';

  @override
  String get statusNothingLeft => 'Nothing left. All done.';

  @override
  String statusItem(String label, String identity) {
    return '$label is $identity';
  }

  @override
  String get listAnd => 'and';

  @override
  String get moreNone => 'I have no more detail.';

  @override
  String get repeatNone => 'I haven\'t said anything yet.';

  @override
  String get stopped => 'Stopped.';

  @override
  String get watchNotReady => 'Watch mode isn\'t available yet.';

  @override
  String get itemNoun => 'item';
}
