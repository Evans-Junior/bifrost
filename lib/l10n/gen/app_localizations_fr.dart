// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'BIFROST';

  @override
  String get holdToTalk => 'Maintenir pour parler';

  @override
  String get holdToTalkHint =>
      'Maintiens pour poser une question, relâche pour l\'envoyer. Avec un lecteur d\'écran, touche deux fois pour commencer et deux fois pour envoyer.';

  @override
  String get cameraPreviewLabel =>
      'Vue de la caméra, pointée vers les objets devant le téléphone.';

  @override
  String get openSettings => 'Réglages';

  @override
  String get statusReady => 'En attente';

  @override
  String get statusListening => 'J\'écoute';

  @override
  String get statusChecking => 'Je vérifie';

  @override
  String get statusSpeaking => 'Je parle';

  @override
  String get statusOffline => 'Connexion impossible';

  @override
  String get statusNoCamera => 'Caméra indisponible';

  @override
  String get checking => 'Je vérifie…';

  @override
  String get timeout => 'Je n\'ai pas eu de réponse. Réessaie.';

  @override
  String get lostTrack =>
      'Pardon, j\'ai perdu le fil. Pose ta question à nouveau.';

  @override
  String get cannotConnect =>
      'Je n\'arrive pas à joindre le serveur. Réessaie.';

  @override
  String get notConfigured =>
      'Le serveur n\'est pas encore configuré. Ouvre les réglages pour l\'ajouter.';

  @override
  String get noCamera => 'Je ne peux pas utiliser la caméra pour l\'instant.';

  @override
  String get noImage => 'Je n\'ai pas pu prendre de photo. Réessaie.';

  @override
  String get didNotHear =>
      'Je n\'ai pas entendu de question. Maintiens le bouton et parle.';

  @override
  String get noMicrophone =>
      'Je ne peux pas utiliser le micro pour l\'instant.';

  @override
  String get referentFallback => 'L\'objet devant la caméra';

  @override
  String referentWithLocation(String label, String location) {
    return '$label, $location.';
  }

  @override
  String referentOnly(String label) {
    return '$label.';
  }

  @override
  String get confidenceRead => 'Je l\'ai lu sur l\'étiquette.';

  @override
  String confidenceThink(String reason) {
    return 'Je pense que oui, parce que $reason.';
  }

  @override
  String get confidenceThinkNoReason => 'Je n\'en ai pas la certitude.';

  @override
  String get cantSee => 'Je ne vois pas assez bien pour le dire.';

  @override
  String get cantSeeDefaultAction => 'Tourne-le lentement dans ta main.';

  @override
  String clarification(String optionA, String optionB) {
    return '$optionA ou $optionB ?';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsServer => 'Serveur';

  @override
  String get settingsBaseUrl => 'URL de base du modèle';

  @override
  String get settingsModelName => 'Nom du modèle';

  @override
  String get settingsApiKey => 'Clé API';

  @override
  String get settingsReasoning => 'Effort de raisonnement';

  @override
  String get settingsTimeout => 'Délai d\'attente (secondes)';

  @override
  String get settingsVoice => 'Voix et langue';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsSpeechRate => 'Débit de la voix';

  @override
  String get settingsProfile => 'Profil de vision';

  @override
  String get settingsProfileBlind => 'Aveugle';

  @override
  String get settingsProfileLowVision => 'Basse vision';

  @override
  String get settingsPositionStyle => 'Style de position';

  @override
  String get settingsPositionClock => 'Cadran d\'horloge';

  @override
  String get settingsPositionLeftRight => 'Gauche et droite';

  @override
  String get settingsFromEnv => 'Défini dans le fichier .env';

  @override
  String get settingsSave => 'Enregistrer';

  @override
  String get settingsSaved => 'Réglages enregistrés.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get reasonLabelHardToRead => 'l\'étiquette est difficile à lire';

  @override
  String challengeStillRead(String text) {
    return 'Je lis toujours $text sur celui-ci.';
  }

  @override
  String challengeStillThink(String identity) {
    return 'Je pense toujours que c\'est $identity.';
  }

  @override
  String challengeChanged(String text) {
    return 'Maintenant, je lis $text. Ma réponse d\'avant était fausse.';
  }

  @override
  String taskRegistered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objets, numérotés de gauche à droite.',
      one: '1 objet.',
      zero: 'Je ne vois encore aucun objet.',
    );
    return '$_temp0';
  }

  @override
  String get statusNoTask =>
      'Aucune tâche en cours. Tu peux dire : aide-moi à trier.';

  @override
  String statusFinding(String goal) {
    return 'Je cherche : $goal.';
  }

  @override
  String statusDone(String items) {
    return 'Fait : $items.';
  }

  @override
  String statusLeft(String items) {
    return 'Reste : $items.';
  }

  @override
  String get statusNothingDone => 'Rien de fait pour l\'instant.';

  @override
  String get statusNothingLeft => 'Il ne reste rien. Tout est fait.';

  @override
  String statusItem(String label, String identity) {
    return '$label : $identity';
  }

  @override
  String get listAnd => 'et';

  @override
  String get moreNone => 'Je n\'ai pas d\'autres détails.';

  @override
  String get repeatNone => 'Je n\'ai encore rien dit.';

  @override
  String get stopped => 'D\'accord, j\'arrête.';

  @override
  String get watchNotReady =>
      'Le mode surveillance n\'est pas encore disponible.';

  @override
  String get itemNoun => 'objet';

  @override
  String get settingsStudy => 'Étude';

  @override
  String get settingsParticipant => 'Code du participant';

  @override
  String get settingsLogServer => 'URL du serveur de journaux';

  @override
  String get serverBusy => 'Le serveur est occupé. Réessaie dans un instant.';

  @override
  String get statusNoItems =>
      'Aucun objet étiqueté pour l\'instant. Demande-moi ce qu\'il y a devant toi.';
}
