import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../audio/earcons.dart';
import '../settings/settings_repository.dart';
import '../turn/turn_controller.dart';

/// "Learn the sounds" (Section 13): each earcon with its spoken meaning.
class LearnSoundsScreen extends ConsumerWidget {
  const LearnSoundsScreen({super.key});

  static List<(Earcon, String)> meanings(AppLocalizations l10n) => [
    (Earcon.listen, l10n.earconListenMeaning),
    (Earcon.read, l10n.earconReadMeaning),
    (Earcon.think, l10n.earconThinkMeaning),
    (Earcon.cantSee, l10n.earconCantSeeMeaning),
    (Earcon.clarify, l10n.earconClarifyMeaning),
    (Earcon.watchPulse, l10n.earconWatchMeaning),
    (Earcon.error, l10n.earconErrorMeaning),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> play(Earcon e, String meaning) async {
      final s = await ref.read(settingsProvider.future);
      final tts = ref.read(ttsServiceProvider);
      await tts.configure(s.language, s.speechRate);
      await tts.speak(meaning);
      // Played even when earcons are off, so they can be learned first.
      await ref.read(earconPlayerProvider).play(e, enabled: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnSoundsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (e, meaning) in meanings(l10n))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: () => play(e, meaning),
                child: Text(meaning),
              ),
            ),
        ],
      ),
    );
  }
}
