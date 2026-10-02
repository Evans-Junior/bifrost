import '../model/vlm_response.dart';
import '../text/text_normalize.dart';

/// One object labelled during a task. Its [id] and [label] never change
/// for the rest of the task (rule 2).
class RegisteredObject {
  RegisteredObject({
    required this.id,
    required this.label,
    required this.number,
    this.shortDescription = '',
    this.location = '',
    this.identifiedAs = '',
    this.readText = '',
    this.confidence,
    this.confidenceReason = '',
  });

  final String id;
  final String label;
  final int number;
  String shortDescription;
  String location;

  /// What the object was identified as, e.g. "CUMIN". Empty if unknown.
  String identifiedAs;

  /// The decisive text read on it, when identified with READ.
  String readText;

  /// Confidence of [identifiedAs].
  Confidence? confidence;
  String confidenceReason;

  bool get isIdentified => identifiedAs.isNotEmpty;

  RegisteredObject copy() => RegisteredObject(
    id: id,
    label: label,
    number: number,
    shortDescription: shortDescription,
    location: location,
    identifiedAs: identifiedAs,
    readText: readText,
    confidence: confidence,
    confidenceReason: confidenceReason,
  );

  Map<String, dynamic> toPrompt() => {
    'id': id,
    'label': label,
    if (shortDescription.isNotEmpty) 'short_description': shortDescription,
    if (location.isNotEmpty) 'location': location,
    if (identifiedAs.isNotEmpty) 'identified_as': identifiedAs,
  };
}

/// The app-owned object registry (guard 6). The model proposes ids; the
/// registry decides labels. Unknown ids get the next sequential number, and
/// a number is never reused within a task.
class ObjectRegistry {
  ObjectRegistry({this.fallbackNoun = 'item'});

  /// Noun used when the model's label has no usable word ("item"/"objet").
  final String fallbackNoun;

  final List<RegisteredObject> _objects = [];
  final Map<String, String> _aliases = {};
  int _next = 1;

  List<RegisteredObject> get objects => List.unmodifiable(_objects);
  int get length => _objects.length;

  /// Finds an object by app id or by a model id seen before.
  RegisteredObject? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    final appId = _aliases[id] ?? id;
    for (final o in _objects) {
      if (o.id == appId) return o;
    }
    return null;
  }

  /// Finds an object by its number ("item 3", "jar 3").
  RegisteredObject? byNumber(int n) {
    for (final o in _objects) {
      if (o.number == n) return o;
    }
    return null;
  }

  /// Returns the registered object for a model [modelId], registering a new
  /// one with the next sequential label if the id is unknown (guard 6).
  RegisteredObject resolve({
    required String modelId,
    String modelLabel = '',
    String shortDescription = '',
    String location = '',
  }) {
    final known = byId(modelId);
    if (known != null) {
      if (shortDescription.isNotEmpty) {
        known.shortDescription = shortDescription;
      }
      if (location.isNotEmpty) known.location = location;
      return known;
    }
    final n = _next++;
    final noun = _noun(modelLabel);
    final obj = RegisteredObject(
      id: '${TextNormalize.forMatching(noun).replaceAll(' ', '_')}_$n',
      label: '$noun $n',
      number: n,
      shortDescription: shortDescription,
      location: location,
    );
    _objects.add(obj);
    if (modelId.isNotEmpty) _aliases[modelId] = obj.id;
    return obj;
  }

  /// Copies the registry so a turn can be applied and discarded if cancelled.
  ObjectRegistry copy() {
    final c = ObjectRegistry(fallbackNoun: fallbackNoun);
    c._objects.addAll(_objects.map((o) => o.copy()));
    c._aliases.addAll(_aliases);
    c._next = _next;
    return c;
  }

  List<Map<String, dynamic>> toPrompt() => [
    for (final o in _objects) o.toPrompt(),
  ];

  /// The label's words without digits: "jar 7" -> "jar", "pot 2" -> "pot".
  String _noun(String label) {
    final words = label
        .toLowerCase()
        .split(RegExp(r'[\s_]+'))
        .where((w) => w.isNotEmpty && !RegExp(r'\d').hasMatch(w))
        .toList();
    return words.isEmpty ? fallbackNoun : words.join(' ');
  }
}
