# BIFROST

BIFROST is a voice-first assistant (iOS and Android) for blind and low-vision users. It follows the team's project specification.

**Status:** Phases 1–4 are built and tested on fixtures; Phases 1–2 have also been tested on a real iPhone. See [ARCHITECTURE.md](ARCHITECTURE.md) for the full design.

## Run

```sh
flutter pub get
flutter run            # needs a real phone: camera, microphone and speech
```

### Quick start with the free hosted model (development only)

```sh
cp .env.example assets/env/.env     # already done if the file exists
# put your OpenRouter key after API_KEY= in assets/env/.env
flutter run
```

Any server value set in `assets/env/.env` overrides Settings, and the field is shown locked there. The file is git-ignored but is **bundled into the app at build time**, so rebuild after editing it, and never share a build that contains a key. Hosted servers receive the camera images, so use only test objects. Participant sessions must use the self-hosted server, built without this file.

### Configure in the app instead

Otherwise, open **Settings** (gear icon, top right) and fill in:

| Field | Example |
|---|---|
| Model base URL | `http://<lab-gpu>:8000/v1` (vLLM) or `https://openrouter.ai/api/v1` |
| Model name | `Qwen/Qwen3.8-27B` (or the hosted provider's model ID) |
| API key | Leave empty for a vLLM server without auth |
| Reasoning effort | `off` (recommended) |
| Timeout | 15 s |

Settings are kept in `flutter_secure_storage`. The source code contains no secrets.

**Using the app.** Hold anywhere on the camera view, ask "What is this?", then release. With VoiceOver or TalkBack on, double tap to start listening, then double tap again to send.

## Turn logs

Each turn is written to a JSON Lines file on the phone and sent to the log server in `../bifrost_logs`, which also holds the React viewer. To use it, set `LOG_SERVER_URL` (in `.env` or Settings). Logs contain text and timings only; images are never logged.

## Run on a real iPhone

iOS 26 blocks Flutter's debug mode on real devices, so use profile or release mode:

```sh
flutter run -d <device-id> --profile
```

The first launch starts the spoken onboarding (it can be redone from Settings).

## Run on the iOS simulator

The simulator has no camera or microphone. In debug builds the app works around this in two ways:
- It uses a generated photo of a jar labelled CUMIN, so OCR and the model still have an image to work with.
- It shows a **Type a question (debug)** box under the hold-to-talk area.

To play a short scripted conversation automatically, run:

```sh
flutter run -d <simulator> --dart-define=BIFROST_DEMO=true
```

ML Kit has no arm64 simulator build, so simulator builds are x86_64 and run under Rosetta (this is set in the Podfile). Builds for real phones are not affected.

## Edit wording without touching code

| What | Where |
|---|---|
| System prompt, profile blocks, position styles, JSON schema, retry instruction | `assets/prompts/` |
| Spoken templates, status lines, UI text (en + fr) | `lib/l10n/app_{en,fr}.arb`, then run `flutter gen-l10n` |
| Intent phrases (en + fr) | `assets/intents/{en,fr}.json` |
| Sight-assuming phrases and chatter removed by guard 7 | `assets/guards/banned_phrases.json` |
| Earcons | `tool/make_earcons.py` (regenerates `assets/sounds/*.wav`) |

## Develop

```sh
dart run build_runner build --delete-conflicting-outputs   # after editing freezed models
flutter gen-l10n                                            # after editing .arb files
flutter analyze
flutter test
```

## Layout

```
lib/src/
  settings/   AppSettings and the secure-storage repository
  model/      response schema (freezed), parser, prompt builder, OpenAI-compatible streaming client
  guards/     app-side guards (Phase 1: guards 1, 4 and 8)
  speech/     speech-to-text, text-to-speech, template-based speech composer
  camera/     rear camera only, stills are never stored
  vision/     resize to 1024 px / JPEG 80 in an isolate
  turn/       TurnPipeline (pure, tested with fixtures) and TurnController (device loop)
  ui/         home screen (hold-to-talk) and Settings
test/fixtures/model/   recorded model outputs used by the tests
```
