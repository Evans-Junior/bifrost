import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../settings/app_settings.dart';
import '../settings/settings_repository.dart';

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
  AppSettings? _draft;

  @override
  void dispose() {
    for (final c in [_baseUrl, _modelName, _apiKey, _timeout]) {
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
  }

  Future<void> _save(AppLocalizations l10n) async {
    final draft = _draft!.copyWith(
      modelBaseUrl: _baseUrl.text,
      modelName: _modelName.text,
      apiKey: _apiKey.text,
      timeoutS: int.tryParse(_timeout.text)?.clamp(3, 120) ?? 15,
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
            onChanged: (v) => setState(() => _draft = d.copyWith(speechRate: v)),
          ),
          _Header(l10n.settingsServer),
          _Field(controller: _baseUrl, label: l10n.settingsBaseUrl,
              keyboard: TextInputType.url),
          _Field(controller: _modelName, label: l10n.settingsModelName),
          _Field(controller: _apiKey, label: l10n.settingsApiKey,
              obscure: true),
          _Field(controller: _timeout, label: l10n.settingsTimeout,
              keyboard: TextInputType.number),
          _Choice<ReasoningEffort>(
            label: l10n.settingsReasoning,
            value: d.reasoningEffort,
            options: {for (final r in ReasoningEffort.values) r: r.name},
            onChanged: (v) =>
                setState(() => _draft = d.copyWith(reasoningEffort: v)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 64)),
            onPressed: () => _save(l10n),
            child: Text(l10n.settingsSave, style: const TextStyle(fontSize: 22)),
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
          child: Text(text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      );
}

/// A labelled text field.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: label,
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
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final e in options.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
}
