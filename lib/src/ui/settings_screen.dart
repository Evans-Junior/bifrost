import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../settings/app_settings.dart';
import '../settings/settings_repository.dart';
import 'learn_sounds_screen.dart';
import 'learn_vibrations_screen.dart';

/// Server, language and voice settings. Every field is a standard
/// labelled control so VoiceOver and TalkBack can operate it.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrl = TextEditingController();
  final _modelName = TextEditingController();
  final _apiKey = TextEditingController();
  final _timeout = TextEditingController();
  final _logServer = TextEditingController();
  final _participant = TextEditingController();
  AppSettings? _draft;
  final Map<String, TextEditingController> _thresholdFields = {};

  /// Feedback switches take effect immediately (Section 11 rule 5).
  Future<void> _saveNow(AppSettings s) async {
    setState(() => _draft = s);
    await ref.read(settingsProvider.notifier).save(s);
  }

  VisionThresholds _thresholdsFromFields(VisionThresholds current) {
    final json = current.toJson();
    for (final e in _thresholdFields.entries) {
      final v = num.tryParse(e.value.text.trim());
      if (v != null) json[e.key] = v;
    }
    return VisionThresholds.fromJson(json);
  }

  @override
  void dispose() {
    for (final c in [
      _baseUrl,
      _modelName,
      _apiKey,
      _timeout,
      _logServer,
      _participant,
      ..._thresholdFields.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFrom(AppSettings s) {
    _draft = s;
    _baseUrl.text = s.modelBaseUrl;
    _modelName.text = s.modelName;
    _apiKey.text = s.apiKey;
    _timeout.text = '${s.timeoutS}';
    _logServer.text = s.logServerUrl;
    _participant.text = s.participant;
    for (final e in s.thresholds.toJson().entries) {
      _thresholdFields[e.key] = TextEditingController(text: '${e.value}');
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    final draft = _draft!.copyWith(
      modelBaseUrl: _baseUrl.text,
      modelName: _modelName.text,
      apiKey: _apiKey.text,
      timeoutS: int.tryParse(_timeout.text)?.clamp(3, 120) ?? 15,
      logServerUrl: _logServer.text,
      participant: _participant.text,
      thresholds: _thresholdsFromFields(_draft!.thresholds),
    );
    await ref.read(settingsProvider.notifier).save(draft);
    if (!mounted) return;
    final saved = lookupAppLocalizations(draft.language.locale).settingsSaved;
    SemanticsService.sendAnnouncement(
      View.of(context),
      saved,
      Directionality.of(context),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_draft == null) _initFrom(settings);
    final d = _draft!;
    final env = ref.watch(envDefaultsProvider).value ?? const {};
    String? envNote(String key) =>
        env.containsKey(key) ? l10n.settingsFromEnv : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(l10n.settingsVoice),
          _Choice<AppLanguage>(
            label: l10n.settingsLanguage,
            value: d.language,
            options: {
              AppLanguage.en: l10n.languageEnglish,
              AppLanguage.fr: l10n.languageFrench,
            },
            onChanged: (v) => setState(() => _draft = d.copyWith(language: v)),
          ),
          _Choice<VisionProfile>(
            label: l10n.settingsProfile,
            value: d.profile,
            options: {
              VisionProfile.blind: l10n.settingsProfileBlind,
              VisionProfile.lowVision: l10n.settingsProfileLowVision,
            },
            onChanged: (v) => setState(() => _draft = d.copyWith(profile: v)),
          ),
          _Choice<PositionStyle>(
            label: l10n.settingsPositionStyle,
            value: d.positionStyle,
            options: {
              PositionStyle.clock: l10n.settingsPositionClock,
              PositionStyle.leftRight: l10n.settingsPositionLeftRight,
            },
            onChanged: (v) =>
                setState(() => _draft = d.copyWith(positionStyle: v)),
          ),
          Text(l10n.settingsSpeechRate, style: const TextStyle(fontSize: 18)),
          Slider(
            value: d.speechRate,
            min: 0.2,
            max: 1.0,
            divisions: 8,
            label: d.speechRate.toStringAsFixed(1),
            semanticFormatterCallback: (v) =>
                '${l10n.settingsSpeechRate} ${v.toStringAsFixed(1)}',
            onChanged: (v) =>
                setState(() => _draft = d.copyWith(speechRate: v)),
          ),
          _Header(l10n.settingsServer),
          _Field(
            controller: _baseUrl,
            label: l10n.settingsBaseUrl,
            keyboard: TextInputType.url,
            lockedNote: envNote('MODEL_BASE_URL'),
          ),
          _Field(
            controller: _modelName,
            label: l10n.settingsModelName,
            lockedNote: envNote('MODEL_NAME'),
          ),
          _Field(
            controller: _apiKey,
            label: l10n.settingsApiKey,
            obscure: true,
            lockedNote: envNote('API_KEY'),
          ),
          _Field(
            controller: _timeout,
            label: l10n.settingsTimeout,
            keyboard: TextInputType.number,
            lockedNote: envNote('TIMEOUT_S'),
          ),
          _Choice<ReasoningEffort>(
            label: l10n.settingsReasoning,
            value: d.reasoningEffort,
            options: {for (final r in ReasoningEffort.values) r: r.name},
            lockedNote: envNote('REASONING_EFFORT'),
            onChanged: (v) =>
                setState(() => _draft = d.copyWith(reasoningEffort: v)),
          ),
          _Header(l10n.settingsFeedback),
          _Switch(
            label: l10n.settingsEarcons,
            value: d.feedback.earcons,
            onChanged: (v) =>
                _saveNow(d.copyWith(feedback: d.feedback.copyWith(earcons: v))),
          ),
          _Switch(
            label: l10n.settingsVibration,
            value: d.feedback.vibrationGuidance,
            onChanged: (v) => _saveNow(
              d.copyWith(feedback: d.feedback.copyWith(vibrationGuidance: v)),
            ),
          ),
          _Choice<VibrationIntensity>(
            label: l10n.settingsIntensity,
            value: d.feedback.intensity,
            options: {
              VibrationIntensity.low: l10n.intensityLow,
              VibrationIntensity.medium: l10n.intensityMedium,
              VibrationIntensity.high: l10n.intensityHigh,
            },
            onChanged: (v) => _saveNow(
              d.copyWith(feedback: d.feedback.copyWith(intensity: v)),
            ),
          ),
          _Switch(
            label: l10n.settingsVibrateSearch,
            value: d.feedback.vibrateInSearch,
            onChanged: (v) => _saveNow(
              d.copyWith(feedback: d.feedback.copyWith(vibrateInSearch: v)),
            ),
          ),
          _Switch(
            label: l10n.settingsSlowPatterns,
            value: d.feedback.slowPatterns,
            onChanged: (v) => _saveNow(
              d.copyWith(feedback: d.feedback.copyWith(slowPatterns: v)),
            ),
          ),
          _Switch(
            label: l10n.settingsSpeakDirection,
            value: d.feedback.speakDirection,
            onChanged: (v) => _saveNow(
              d.copyWith(feedback: d.feedback.copyWith(speakDirection: v)),
            ),
          ),
          _NavButton(
            label: l10n.learnVibrationsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LearnVibrationsScreen()),
            ),
          ),
          _NavButton(
            label: l10n.learnSoundsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LearnSoundsScreen()),
            ),
          ),
          _NavButton(
            label: l10n.settingsRedoOnboarding,
            onTap: () async {
              await _saveNow(d.copyWith(onboardingDone: false));
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          _Header(l10n.settingsStudy),
          _Field(
            controller: _participant,
            label: l10n.settingsParticipant,
            lockedNote: envNote('PARTICIPANT'),
          ),
          _Field(
            controller: _logServer,
            label: l10n.settingsLogServer,
            keyboard: TextInputType.url,
            lockedNote: envNote('LOG_SERVER_URL'),
          ),
          ExpansionTile(
            title: Text(l10n.settingsDeveloper),
            children: [
              for (final e in _thresholdFields.entries)
                _Field(
                  controller: e.value,
                  label: e.key,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 64)),
            onPressed: () => _save(l10n),
            child: Text(
              l10n.settingsSave,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading, marked as a header for screen-reader navigation.
class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

/// A labelled text field. When [lockedNote] is set the value comes from
/// `.env`, so the field is read-only and says why.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboard,
    this.lockedNote,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboard;
  final String? lockedNote;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      enabled: lockedNote == null,
      obscureText: obscure,
      autocorrect: false,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        helperText: lockedNote,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

/// A labelled drop-down choice.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.lockedNote,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// When set, the value comes from `.env` and cannot be changed here.
  final String? lockedNote;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        helperText: lockedNote,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: lockedNote != null
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    ),
  );
}

/// A labelled on/off switch.
class _Switch extends StatelessWidget {
  const _Switch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label, style: const TextStyle(fontSize: 18)),
    value: value,
    onChanged: onChanged,
  );
}

/// A full-width button that opens another screen.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 18)),
    ),
  );
}
