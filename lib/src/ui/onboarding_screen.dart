import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../audio/earcons.dart';
import '../settings/app_settings.dart';
import '../settings/settings_repository.dart';
import '../turn/turn_controller.dart';
import 'learn_vibrations_screen.dart';

/// The steps of first-run setup (Section 10), about one minute in all.
enum OnboardingStep {
  language,
  vision,
  position,
  rate,
  earcons,
  vibration,
  learnVibrations,
  practiceHold,
  practiceEarcon,
  practiceAsk,
  done;

  /// The step after this one. "Learn the vibrations" is offered only when
  /// vibration guidance was turned on.
  OnboardingStep next({required bool vibrationOn}) {
    if (this == vibration && !vibrationOn) return practiceHold;
    if (this == done) return done;
    return values[index + 1];
  }
}

/// Spoken, screen-reader-friendly first-run setup. Every choice is saved
/// immediately, so the voice switches language and speed right away. After
/// this, the app never asks again whether the user is blind (O5).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  OnboardingStep _step = OnboardingStep.language;
  bool _holding = false;
  String _heard = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  Future<AppSettings> get _settings => ref.read(settingsProvider.future);

  Future<void> _save(AppSettings s) =>
      ref.read(settingsProvider.notifier).save(s);

  Future<void> _speak(String text) async {
    final s = await _settings;
    final tts = ref.read(ttsServiceProvider);
    await tts.stop();
    await tts.configure(s.language, s.speechRate);
    await tts.speak(text);
  }

  Future<void> _announce() async {
    final s = await _settings;
    final l10n = lookupAppLocalizations(s.language.locale);
    if (_step == OnboardingStep.language) await _speak(l10n.onbWelcome);
    if (_step == OnboardingStep.practiceAsk) {
      // The practice question needs a photo; only the home screen opens the
      // camera otherwise.
      await ref.read(turnControllerProvider.notifier).startCamera();
    }
    await _speak(_prompt(l10n));
    if (_step == OnboardingStep.practiceEarcon) {
      await ref.read(earconPlayerProvider).play(Earcon.read, enabled: true);
    }
  }

  String _prompt(AppLocalizations l10n) => switch (_step) {
    OnboardingStep.language => l10n.onbLanguage,
    OnboardingStep.vision => l10n.onbVision,
    OnboardingStep.position => l10n.onbPosition,
    OnboardingStep.rate => l10n.onbRate,
    OnboardingStep.earcons => l10n.onbEarcons,
    OnboardingStep.vibration => l10n.onbVibration,
    OnboardingStep.learnVibrations => l10n.onbLearnNow,
    OnboardingStep.practiceHold => l10n.onbPracticeHold,
    OnboardingStep.practiceEarcon => l10n.onbPracticeEarcon,
    OnboardingStep.practiceAsk => l10n.onbPracticeAsk,
    OnboardingStep.done => l10n.onbDone,
  };

  Future<void> _advance() async {
    final s = await _settings;
    if (_step == OnboardingStep.done) {
      await _save(s.copyWith(onboardingDone: true));
      return;
    }
    setState(() {
      _step = _step.next(vibrationOn: s.feedback.vibrationGuidance);
      _heard = '';
    });
    await _announce();
  }

  Future<void> _choose(AppSettings Function(AppSettings) change) async {
    await _save(change(await _settings));
    await _advance();
  }

  Future<void> _rate(double delta) async {
    final s = await _settings;
    final rate = (s.speechRate + delta).clamp(0.2, 1.0);
    await _save(s.copyWith(speechRate: rate));
    final l10n = lookupAppLocalizations(s.language.locale);
    await _speak(l10n.onbRate);
  }

  Future<void> _holdStart() async {
    final s = await _settings;
    setState(() => _holding = true);
    await ref.read(earconPlayerProvider).play(Earcon.listen, enabled: true);
    await ref.read(sttServiceProvider).start(s.language.sttLocaleId);
  }

  Future<void> _holdEnd() async {
    if (!_holding) return;
    setState(() => _holding = false);
    final words = await ref.read(sttServiceProvider).stop();
    final s = await _settings;
    final l10n = lookupAppLocalizations(s.language.locale);
    setState(() => _heard = words);
    await _speak(
      words.isEmpty ? l10n.didNotHear : l10n.onbPracticeHeard(words),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final turn = ref.watch(turnControllerProvider);
    Widget big(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(76),
          textStyle: const TextStyle(fontSize: 24),
        ),
        onPressed: onTap,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );

    final choices = <Widget>[
      ...switch (_step) {
        OnboardingStep.language => [
          big(
            l10n.languageEnglish,
            () => _choose((s) => s.copyWith(language: AppLanguage.en)),
          ),
          big(
            l10n.languageFrench,
            () => _choose((s) => s.copyWith(language: AppLanguage.fr)),
          ),
        ],
        OnboardingStep.vision => [
          big(
            l10n.settingsProfileBlind,
            () => _choose((s) => s.copyWith(profile: VisionProfile.blind)),
          ),
          big(
            l10n.settingsProfileLowVision,
            () => _choose((s) => s.copyWith(profile: VisionProfile.lowVision)),
          ),
        ],
        OnboardingStep.position => [
          big(
            l10n.settingsPositionClock,
            () =>
                _choose((s) => s.copyWith(positionStyle: PositionStyle.clock)),
          ),
          big(
            l10n.settingsPositionLeftRight,
            () => _choose(
              (s) => s.copyWith(positionStyle: PositionStyle.leftRight),
            ),
          ),
        ],
        OnboardingStep.rate => [
          big(l10n.onbFaster, () => _rate(0.1)),
          big(l10n.onbSlower, () => _rate(-0.1)),
          big(l10n.onbKeep, _advance),
        ],
        OnboardingStep.earcons => [
          big(
            l10n.yes,
            () => _choose(
              (s) => s.copyWith(feedback: s.feedback.copyWith(earcons: true)),
            ),
          ),
          big(
            l10n.no,
            () => _choose(
              (s) => s.copyWith(feedback: s.feedback.copyWith(earcons: false)),
            ),
          ),
        ],
        OnboardingStep.vibration => [
          big(
            l10n.yes,
            () => _choose(
              (s) => s.copyWith(
                feedback: s.feedback.copyWith(vibrationGuidance: true),
              ),
            ),
          ),
          big(
            l10n.no,
            () => _choose(
              (s) => s.copyWith(
                feedback: s.feedback.copyWith(vibrationGuidance: false),
              ),
            ),
          ),
        ],
        OnboardingStep.learnVibrations => [
          big(
            l10n.yes,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LearnVibrationsScreen(
                  onDone: () {
                    Navigator.of(context).pop();
                    _advance();
                  },
                ),
              ),
            ),
          ),
          big(l10n.skip, _advance),
        ],
        OnboardingStep.practiceHold => [
          _HoldButton(
            label: l10n.holdToPractice,
            holding: _holding,
            onDown: _holdStart,
            onUp: _holdEnd,
          ),
          if (_heard.isNotEmpty) big(l10n.next, _advance),
        ],
        OnboardingStep.practiceEarcon => [
          big(
            l10n.vibPlayAgain,
            () =>
                ref.read(earconPlayerProvider).play(Earcon.read, enabled: true),
          ),
          big(l10n.next, _advance),
        ],
        OnboardingStep.practiceAsk => [
          _HoldButton(
            label: l10n.holdToTalk,
            holding: turn.status == TurnStatus.listening,
            onDown: () =>
                ref.read(turnControllerProvider.notifier).pressStart(),
            onUp: () => ref.read(turnControllerProvider.notifier).pressEnd(),
          ),
          if (turn.lastSpoken.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                turn.lastSpoken,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          big(l10n.next, _advance),
        ],
        OnboardingStep.done => [big(l10n.next, _advance)],
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(_prompt(l10n), style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 24),
            ...choices,
          ],
        ),
      ),
    );
  }
}

/// A large hold-to-talk area that also works with a screen reader
/// (double tap to start, double tap again to stop).
class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.label,
    required this.holding,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final bool holding;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      button: true,
      label: label,
      onTap: holding ? onUp : onDown,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        child: Container(
          height: 160,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: holding ? Colors.amber : Colors.white54,
              width: holding ? 8 : 4,
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 26)),
        ),
      ),
    ),
  );
}
