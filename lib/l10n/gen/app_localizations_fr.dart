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
  String get confidenceRead => 'Je l\'ai lu directement.';

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

  @override
  String get referentScene => 'Vue d\'ensemble.';

  @override
  String get correction => 'Correction :';

  @override
  String get aimNothingInView => 'Rien en vue. Balaie lentement.';

  @override
  String get glare => 'Reflet. Incline-le loin de la lumière.';

  @override
  String get blur => 'Tiens-le immobile.';

  @override
  String get watchOffer => 'Veux-tu que je te dise quand je peux le lire ?';

  @override
  String get watchStarted => 'Je regarde. Tourne-le lentement.';

  @override
  String get watchTimeout =>
      'Je n\'arrive toujours pas à le lire. Essaie de le tourner lentement dans l\'autre sens.';

  @override
  String get watchDeclined => 'D\'accord.';

  @override
  String get dirLeft => 'gauche';

  @override
  String get dirRight => 'droite';

  @override
  String get dirUp => 'haut';

  @override
  String get dirDown => 'bas';

  @override
  String get dirFullView => 'ça y est';

  @override
  String get learnVibrationsTitle => 'Apprendre les vibrations';

  @override
  String get vibLeftMeaning =>
      'Une longue impulsion : va à gauche. Long, c\'est gauche.';

  @override
  String get vibRightMeaning =>
      'Deux impulsions courtes : va à droite. Droite, c\'est rapide.';

  @override
  String get vibUpMeaning =>
      'Trois petits tapotements : va vers le haut. Haut, c\'est plus de tapotements.';

  @override
  String get vibDownMeaning =>
      'Deux longues impulsions : va vers le bas. Bas, c\'est lourd.';

  @override
  String get vibFullViewMeaning => 'Une forte vibration : arrête, tu y es.';

  @override
  String get vibPlayAll => 'Jouer chaque motif';

  @override
  String get vibStartPractice => 'Commencer l\'exercice';

  @override
  String get vibWhichDirection => 'C\'était quelle direction ?';

  @override
  String get vibCorrect => 'Exact.';

  @override
  String vibWrong(String direction) {
    return 'Pas tout à fait. C\'était $direction.';
  }

  @override
  String get vibReady =>
      'Quatre de suite. C\'est bon, tu maîtrises les vibrations.';

  @override
  String vibScore(int correct) {
    return '$correct bonnes réponses de suite';
  }

  @override
  String get vibPlayAgain => 'Rejouer';

  @override
  String get vibUnsupported => 'Ce téléphone ne peut pas vibrer.';

  @override
  String get learnSoundsTitle => 'Apprendre les sons';

  @override
  String get earconListenMeaning => 'J\'écoute';

  @override
  String get earconReadMeaning => 'Je l\'ai lu';

  @override
  String get earconThinkMeaning => 'Je pense que oui';

  @override
  String get earconCantSeeMeaning => 'Je ne le vois pas';

  @override
  String get earconClarifyMeaning => 'Je te demande lequel';

  @override
  String get earconWatchMeaning => 'Je regarde encore';

  @override
  String get earconErrorMeaning => 'Erreur ou pas de connexion';

  @override
  String get settingsFeedback => 'Sons et vibrations';

  @override
  String get settingsEarcons => 'Sons indicateurs';

  @override
  String get settingsVibration => 'Guidage par vibration';

  @override
  String get settingsIntensity => 'Intensité des vibrations';

  @override
  String get intensityLow => 'Faible';

  @override
  String get intensityMedium => 'Moyenne';

  @override
  String get intensityHigh => 'Forte';

  @override
  String get settingsVibrateSearch => 'Vibrer pendant les recherches';

  @override
  String get settingsSlowPatterns => 'Motifs lents';

  @override
  String get settingsSpeakDirection => 'Dire aussi la direction';

  @override
  String get settingsRedoOnboarding => 'Refaire la configuration';

  @override
  String get settingsDeveloper => 'Développeur : seuils';

  @override
  String get onbWelcome =>
      'Bienvenue dans BIFROST. Cette configuration prend environ une minute.';

  @override
  String get onbLanguage => 'Choose a language. Choisis une langue.';

  @override
  String get onbVision => 'Es-tu aveugle, ou as-tu une basse vision ?';

  @override
  String get onbPosition =>
      'Comment veux-tu les positions ? En cadran d\'horloge, comme à 2 heures, ou à gauche et à droite ?';

  @override
  String get onbRate =>
      'Voici ma vitesse de parole. Choisis plus vite, plus lent, ou garde-la.';

  @override
  String get onbFaster => 'Plus vite';

  @override
  String get onbSlower => 'Plus lent';

  @override
  String get onbKeep => 'Garder cette vitesse';

  @override
  String get onbEarcons =>
      'Veux-tu de courts sons qui indiquent à quel point ma réponse est sûre ?';

  @override
  String get onbVibration =>
      'Veux-tu des vibrations qui te guident vers les objets ?';

  @override
  String get onbLearnNow => 'Apprendre les vibrations maintenant ?';

  @override
  String get onbPracticeHold =>
      'Exercice. Maintiens le grand bouton, dis n\'importe quoi, puis relâche.';

  @override
  String onbPracticeHeard(String words) {
    return 'J\'ai entendu : $words.';
  }

  @override
  String get onbPracticeEarcon => 'Ce son veut dire : je l\'ai lu.';

  @override
  String get onbPracticeAsk =>
      'Maintenant, pointe la caméra vers un objet, maintiens le bouton et demande : c\'est quoi ça ?';

  @override
  String get onbDone => 'Tout est prêt.';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get holdToPractice => 'Maintenir pour s\'exercer';

  @override
  String get watchQuestion => 'Que dit l\'étiquette ?';
}
