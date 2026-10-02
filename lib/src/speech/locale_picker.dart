/// Chooses the best speech locale a device offers for the wanted language.
///
/// Phones often lack `fr-CA` for recognition or voices but have `fr-FR`, so
/// the order is: exact match, then the same language in any region (with
/// the preferred region list first), then nothing.
class LocalePicker {
  /// Regions tried, in order, when the exact locale is missing.
  static const fallbackRegions = {
    'fr': ['CA', 'FR', 'BE', 'CH'],
    'en': ['CA', 'US', 'GB', 'AU'],
  };

  /// Returns the entry of [available] to use for [wanted] (for example
  /// `fr-CA`), keeping the device's own spelling (`fr_CA`, `fr-ca`, ...),
  /// or null if the device has no locale for that language.
  static String? pick(String wanted, Iterable<String> available) {
    final byKey = {for (final a in available) _key(a): a};
    final exact = byKey[_key(wanted)];
    if (exact != null) return exact;

    final lang = _key(wanted).split('-').first;
    for (final region in fallbackRegions[lang] ?? const <String>[]) {
      final hit = byKey['$lang-${region.toLowerCase()}'];
      if (hit != null) return hit;
    }
    for (final entry in byKey.entries) {
      if (entry.key == lang || entry.key.startsWith('$lang-')) {
        return entry.value;
      }
    }
    return null;
  }

  static String _key(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();
}
