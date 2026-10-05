import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../guidance/haptic_player.dart';
import '../guidance/patterns.dart';
import '../settings/settings_repository.dart';
import '../text/text_normalize.dart';
import '../turn/turn_controller.dart';

/// Scores the "Learn the vibrations" practice (Section 11): a random
/// pattern plays, the user names its direction, and four correct answers in
/// a row means they are ready. Pure Dart, unit-tested.
class VibrationPractice {
  VibrationPractice([Random? random]) : _random = random ?? Random();

  final Random _random;
  static const needed = 4;
  static const directions = [
    GuidancePattern.left,
    GuidancePattern.right,
    GuidancePattern.up,
    GuidancePattern.down,
  ];

  GuidancePattern? current;
  int streak = 0;
  int attempts = 0;
  int correct = 0;

  bool get ready => streak >= needed;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  GuidancePattern next() => current = directions[_random.nextInt(4)];

  /// Records an answer; returns true if it was right.
  bool answer(GuidancePattern guess) {
    attempts++;
    final ok = guess == current;
    if (ok) {
      correct++;
      streak++;
    } else {
      streak = 0;
    }
    return ok;
  }

  /// Maps a spoken answer ("left", "à gauche") to a direction.
  static GuidancePattern? parse(String spoken) {
    final t = ' ${TextNormalize.forMatching(spoken)} ';
    bool has(List<String> ws) => ws.any((w) => t.contains(' $w '));
    if (has(['left', 'gauche'])) return GuidancePattern.left;
    if (has(['right', 'droite'])) return GuidancePattern.right;
    if (has(['up', 'haut', 'top'])) return GuidancePattern.up;
    if (has(['down', 'bas', 'bottom'])) return GuidancePattern.down;
    return null;
  }
}

/// "Learn the vibrations": plays each pattern with its spoken meaning, then
/// a short practice. Reachable from onboarding and Settings.
class LearnVibrationsScreen extends ConsumerStatefulWidget {
  const LearnVibrationsScreen({super.key, this.onDone});

  /// Called when the user finishes (used by onboarding).
  final VoidCallback? onDone;

  @override
  ConsumerState<LearnVibrationsScreen> createState() =>
      _LearnVibrationsScreenState();
}

class _LearnVibrationsScreenState extends ConsumerState<LearnVibrationsScreen> {
  final _haptics = HapticPlayer();
  final _practice = VibrationPractice();
  bool _practising = false;
  bool _listening = false;
  String _status = '';

  Future<void> _say(String text) async {
    setState(() => _status = text);
    final s = await ref.read(settingsProvider.future);
    final tts = ref.read(ttsServiceProvider);
    await tts.configure(s.language, s.speechRate);
    await tts.speak(text);
  }

  Future<void> _play(GuidancePattern p) async {
    final s = await ref.read(settingsProvider.future);
    await _haptics.play(
      p,
      s.feedback.intensity.amplitude,
      slow: s.feedback.slowPatterns,
    );
    await Future<void>.delayed(
      Duration(milliseconds: p.durationMs(slow: s.feedback.slowPatterns) + 300),
    );
  }

  Future<void> _demo(AppLocalizations l10n) async {
    if (await _haptics.init() == HapticMode.none) {
      return _say(l10n.vibUnsupported);
    }
    for (final (p, meaning) in _meanings(l10n)) {
      if (!mounted) return;
      await _say(meaning);
      await _play(p);
    }
  }

  Future<void> _nextPractice(AppLocalizations l10n) async {
    setState(() => _practising = true);
    await _play(_practice.next());
    await _say(l10n.vibWhichDirection);
  }

  Future<void> _answer(GuidancePattern guess, AppLocalizations l10n) async {
    if (_practice.current == null) return;
    final ok = _practice.answer(guess);
    if (ok) {
      await _say(l10n.vibCorrect);
    } else {
      await _say(l10n.vibWrong(_directionWord(_practice.current!, l10n)));
    }
    if (_practice.ready) {
      await _say(l10n.vibReady);
      await _logResult();
      if (mounted) setState(() => _practising = false);
      widget.onDone?.call();
      return;
    }
    await _nextPractice(l10n);
  }

  /// Practice accuracy is study data (Section 11).
  Future<void> _logResult() async {
    final s = await ref.read(settingsProvider.future);
    final logger = ref.read(turnLoggerProvider);
    await logger.write({
      'schema': 1,
      'type': 'vibration_practice',
      'session_id': logger.sessionId,
      'participant': s.participant,
      'attempts': _practice.attempts,
      'correct': _practice.correct,
      'accuracy': _practice.accuracy,
      'haptic_mode': _haptics.mode.name,
    }, s);
  }

  Future<void> _voiceAnswerStart() async {
    final s = await ref.read(settingsProvider.future);
    setState(() => _listening = true);
    await ref.read(sttServiceProvider).start(s.language.sttLocaleId);
  }

  Future<void> _voiceAnswerEnd(AppLocalizations l10n) async {
    if (!_listening) return;
    setState(() => _listening = false);
    final words = await ref.read(sttServiceProvider).stop();
    final guess = VibrationPractice.parse(words);
    if (guess != null) await _answer(guess, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final big = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(72),
      textStyle: const TextStyle(fontSize: 22),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnVibrationsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            liveRegion: true,
            child: Text(_status, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 16),
          if (!_practising) ...[
            FilledButton(
              style: big,
              onPressed: () => _demo(l10n),
              child: Text(l10n.vibPlayAll),
            ),
            const SizedBox(height: 12),
            for (final (p, meaning) in _meanings(l10n))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () async {
                    await _say(meaning);
                    await _play(p);
                  },
                  child: Text(meaning, textAlign: TextAlign.center),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: big,
              onPressed: () => _nextPractice(l10n),
              child: Text(l10n.vibStartPractice),
            ),
          ] else ...[
            Text(
              l10n.vibScore(_practice.streak),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: l10n.holdToTalk,
              onTap: () =>
                  _listening ? _voiceAnswerEnd(l10n) : _voiceAnswerStart(),
              excludeSemantics: true,
              child: Listener(
                onPointerDown: (_) => _voiceAnswerStart(),
                onPointerUp: (_) => _voiceAnswerEnd(l10n),
                child: Container(
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _listening ? Colors.amber : Colors.white54,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.holdToTalk,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                for (final p in VibrationPractice.directions)
                  FilledButton.tonal(
                    onPressed: () => _answer(p, l10n),
                    child: Text(
                      _directionWord(p, l10n),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _play(_practice.current!),
              child: Text(l10n.vibPlayAgain),
            ),
          ],
        ],
      ),
    );
  }

  static List<(GuidancePattern, String)> _meanings(AppLocalizations l10n) => [
    (GuidancePattern.left, l10n.vibLeftMeaning),
    (GuidancePattern.right, l10n.vibRightMeaning),
    (GuidancePattern.up, l10n.vibUpMeaning),
    (GuidancePattern.down, l10n.vibDownMeaning),
    (GuidancePattern.fullView, l10n.vibFullViewMeaning),
  ];

  static String _directionWord(GuidancePattern p, AppLocalizations l10n) =>
      switch (p) {
        GuidancePattern.left => l10n.dirLeft,
        GuidancePattern.right => l10n.dirRight,
        GuidancePattern.up => l10n.dirUp,
        GuidancePattern.down => l10n.dirDown,
        GuidancePattern.fullView => l10n.dirFullView,
      };
}
