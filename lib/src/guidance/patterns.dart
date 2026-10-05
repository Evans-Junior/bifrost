/// The vibration "beats" of Section 11. A phone has one vibration motor,
/// so direction is encoded as rhythm.
enum GuidancePattern {
  /// One long pulse: "Long = left".
  left([300]),

  /// Two short pulses: "Right = rapid".
  right([80, 80, 80]),

  /// Three short taps: "Up = more taps".
  up([60, 60, 60, 60, 60]),

  /// Two long pulses: "Down = heavy".
  down([200, 120, 200]),

  /// One strong continuous buzz: "Stop, you're there".
  fullView([500]);

  const GuidancePattern(this.segments);

  /// Alternating on/off durations in ms, starting with "on".
  final List<int> segments;

  /// How long one beat lasts at the given speed.
  int durationMs({bool slow = false}) =>
      [for (final s in timed(slow: slow)) s].fold(0, (a, b) => a + b);

  /// Segments with slow-mode gaps (off segments 1.5× longer).
  List<int> timed({bool slow = false}) => [
    for (var i = 0; i < segments.length; i++)
      i.isOdd && slow ? (segments[i] * 1.5).round() : segments[i],
  ];

  /// The `vibration` package format: a leading wait, then on/off pairs.
  List<int> vibrationPattern({bool slow = false}) => [0, ...timed(slow: slow)];

  /// Per-segment amplitudes for [vibrationPattern] (0 for gaps).
  List<int> intensities(int amplitude, {bool slow = false}) => [
    0,
    for (var i = 0; i < segments.length; i++) i.isEven ? amplitude : 0,
  ];

  bool get isDirection => this != fullView;
}
