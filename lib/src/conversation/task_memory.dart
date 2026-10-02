import '../model/vlm_response.dart';
import 'object_registry.dart';

/// The current task (rule 8). Done and left are derived from the registry:
/// an object is done once it has been identified from text BIFROST read
/// (`READ`); everything else is left.
class TaskMemory {
  TaskMemory({this.type, this.goal});

  /// sort, find or match; null before any START_TASK.
  final String? type;

  /// What the user is looking for in a find task, e.g. "keys".
  final String? goal;

  bool get isActive => type != null;

  List<RegisteredObject> done(ObjectRegistry r) => [
    for (final o in r.objects)
      if (o.isIdentified && o.confidence == Confidence.read) o,
  ];

  List<RegisteredObject> left(ObjectRegistry r) => [
    for (final o in r.objects)
      if (!(o.isIdentified && o.confidence == Confidence.read)) o,
  ];

  /// The `TASK_STATE` block sent to the model.
  Map<String, dynamic> toPrompt(ObjectRegistry r) => {
    'type': type,
    if (goal != null) 'goal': goal,
    'done': [for (final o in done(r)) o.id],
    'left': [for (final o in left(r)) o.id],
  };
}
