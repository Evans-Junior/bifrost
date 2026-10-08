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
  String get confidenceRead => 'I read this directly.';

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
  String get itemNoun => 'item';

  @override
  String get settingsStudy => 'Study';

  @override
  String get settingsParticipant => 'Participant code';

  @override
  String get settingsLogServer => 'Log server URL';

  @override
  String get serverBusy => 'The server is busy. Try again in a moment.';

  @override
  String get statusNoItems =>
      'No items labelled yet. Ask me what\'s in front of you.';

  @override
  String get referentScene => 'Overall view.';

  @override
  String get correction => 'Correction:';

  @override
  String get aimNothingInView => 'Nothing in view. Sweep slowly.';

  @override
  String get glare => 'Glare. Tilt it away from the light.';

  @override
  String get blur => 'Hold it still.';

  @override
  String get watchOffer => 'Want me to tell you when I can read it?';

  @override
  String get watchStarted => 'Watching. Turn it slowly.';

  @override
  String get watchTimeout =>
      'I still can\'t read it. Try turning it slowly the other way.';

  @override
  String get watchDeclined => 'Okay.';

  @override
  String get dirLeft => 'left';

  @override
  String get dirRight => 'right';

  @override
  String get dirUp => 'up';

  @override
  String get dirDown => 'down';

  @override
  String get dirFullView => 'there';

  @override
  String get learnVibrationsTitle => 'Learn the vibrations';

  @override
  String get vibLeftMeaning => 'One long pulse: go left. Long means left.';

  @override
  String get vibRightMeaning => 'Two short pulses: go right. Right is rapid.';

  @override
  String get vibUpMeaning => 'Three short taps: go up. Up has more taps.';

  @override
  String get vibDownMeaning => 'Two long pulses: go down. Down is heavy.';

  @override
  String get vibFullViewMeaning => 'One strong buzz: stop, you\'re there.';

  @override
  String get vibPlayAll => 'Play each pattern';

  @override
  String get vibStartPractice => 'Start practice';

  @override
  String get vibWhichDirection => 'Which direction was that?';

  @override
  String get vibCorrect => 'Correct.';

  @override
  String vibWrong(String direction) {
    return 'Not quite. That was $direction.';
  }

  @override
  String get vibReady => 'Four in a row. You\'re ready.';

  @override
  String vibScore(int correct) {
    return '$correct correct in a row';
  }

  @override
  String get vibPlayAgain => 'Play again';

  @override
  String get vibUnsupported => 'This phone can\'t vibrate.';

  @override
  String get learnSoundsTitle => 'Learn the sounds';

  @override
  String get earconListenMeaning => 'Listening started';

  @override
  String get earconReadMeaning => 'I read it';

  @override
  String get earconThinkMeaning => 'I think so';

  @override
  String get earconCantSeeMeaning => 'I can\'t see it';

  @override
  String get earconClarifyMeaning => 'I\'m asking which one you mean';

  @override
  String get earconWatchMeaning => 'Still watching';

  @override
  String get earconErrorMeaning => 'Error or no connection';

  @override
  String get settingsFeedback => 'Sounds and vibration';

  @override
  String get settingsEarcons => 'Earcons';

  @override
  String get settingsVibration => 'Vibration guidance';

  @override
  String get settingsIntensity => 'Vibration intensity';

  @override
  String get intensityLow => 'Low';

  @override
  String get intensityMedium => 'Medium';

  @override
  String get intensityHigh => 'High';

  @override
  String get settingsVibrateSearch => 'Vibrate in search tasks';

  @override
  String get settingsSlowPatterns => 'Slow patterns';

  @override
  String get settingsSpeakDirection => 'Also speak direction';

  @override
  String get settingsRedoOnboarding => 'Redo the setup';

  @override
  String get settingsDeveloper => 'Developer: thresholds';

  @override
  String get onbWelcome =>
      'Welcome to BIFROST. This setup takes about a minute.';

  @override
  String get onbLanguage => 'Choose a language. Choisis une langue.';

  @override
  String get onbVision => 'Are you blind, or do you have low vision?';

  @override
  String get onbPosition =>
      'How should I give positions? Clock face, like at your 2 o\'clock, or left and right?';

  @override
  String get onbRate =>
      'This is my speaking speed. Choose faster, slower, or keep it.';

  @override
  String get onbFaster => 'Faster';

  @override
  String get onbSlower => 'Slower';

  @override
  String get onbKeep => 'Keep this speed';

  @override
  String get onbEarcons =>
      'Do you want short sounds that tell you how sure I am?';

  @override
  String get onbVibration =>
      'Do you want vibrations that guide you toward objects?';

  @override
  String get onbLearnNow => 'Learn the vibrations now?';

  @override
  String get onbPracticeHold =>
      'Practice. Hold the big button, say anything, then let go.';

  @override
  String onbPracticeHeard(String words) {
    return 'I heard: $words.';
  }

  @override
  String get onbPracticeEarcon => 'This sound means: I read it.';

  @override
  String get onbPracticeAsk =>
      'Now point the camera at any object, hold the button and ask: what is this?';

  @override
  String get onbDone => 'You\'re all set.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get holdToPractice => 'Hold to practise';

  @override
  String get watchQuestion => 'What does the label say?';

  @override
  String get modelUnavailable =>
      'The server doesn\'t offer this model. The model name in Settings needs changing.';
}
