import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../turn/turn_controller.dart';
import 'settings_screen.dart';

/// The main screen: rear camera preview behind one full-screen
/// hold-to-talk button, plus a status line announced to screen readers.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _cameraReady = false;

  TurnController get _turns => ref.read(turnControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.inactive) {
      setState(() => _cameraReady = false);
      ref.read(cameraServiceProvider).stop();
    } else if (lifecycle == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    final ok = await _turns.startCamera();
    if (mounted) setState(() => _cameraReady = ok);
  }

  /// Screen-reader double tap toggles listening.
  void _toggle() {
    final status = ref.read(turnControllerProvider).status;
    status == TurnStatus.listening ? _turns.pressEnd() : _turns.pressStart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final turn = ref.watch(turnControllerProvider);
    ref.listen(turnControllerProvider.select((s) => s.status), (_, status) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        _statusText(l10n, status),
        Directionality.of(context),
      );
    });
    final controller = ref.read(cameraServiceProvider).controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              status: _statusText(l10n, turn.status),
              onSettings: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_cameraReady && controller != null)
                    ExcludeSemantics(child: CameraPreview(controller)),
                  _HoldToTalkButton(
                    listening: turn.status == TurnStatus.listening,
                    label: l10n.holdToTalk,
                    hint: l10n.holdToTalkHint,
                    onDown: _turns.pressStart,
                    onUp: _turns.pressEnd,
                    onTap: _toggle,
                  ),
                ],
              ),
            ),
            _LastReply(text: turn.lastSpoken),
          ],
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n, TurnStatus s) => switch (s) {
        TurnStatus.ready => l10n.statusReady,
        TurnStatus.listening => l10n.statusListening,
        TurnStatus.checking => l10n.statusChecking,
        TurnStatus.speaking => l10n.statusSpeaking,
        TurnStatus.offline => l10n.statusOffline,
        TurnStatus.noCamera => l10n.statusNoCamera,
      };
}

/// Title, live status and the Settings button.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.status, required this.onSettings});

  final String status;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(status, style: const TextStyle(fontSize: 22)),
            ),
          ),
          IconButton(
            iconSize: 40,
            tooltip: l10n.openSettings,
            icon: const Icon(Icons.settings),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// The large hold-to-talk area covering the camera preview. Raw pointer
/// events give hold-to-talk; the semantic tap action lets VoiceOver and
/// TalkBack users toggle it.
class _HoldToTalkButton extends StatelessWidget {
  const _HoldToTalkButton({
    required this.listening,
    required this.label,
    required this.hint,
    required this.onDown,
    required this.onUp,
    required this.onTap,
  });

  final bool listening;
  final String label;
  final String hint;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onDown(),
        onPointerUp: (_) => onUp(),
        onPointerCancel: (_) => onUp(),
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: listening ? Colors.amber : Colors.white54,
              width: listening ? 10 : 4,
            ),
            color: listening ? Colors.amber.withValues(alpha: 0.25) : null,
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(24),
          child: Text(
            label,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Large text of the last spoken reply, for low-vision users and
/// researchers. Already spoken aloud, so screen readers skip announcing it.
class _LastReply extends StatelessWidget {
  const _LastReply({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(text, style: const TextStyle(fontSize: 22)),
    );
  }
}
