import 'package:freezed_annotation/freezed_annotation.dart';

part 'vlm_response.freezed.dart';
part 'vlm_response.g.dart';

/// What kind of evidence the model used (Section 8 schema).
enum Evidence {
  @JsonValue('READ')
  read,
  @JsonValue('SEEN')
  seen,
  @JsonValue('NOT_VISIBLE')
  notVisible,
}

/// The three confidence levels BIFROST always states (rule 4).
enum Confidence {
  @JsonValue('READ')
  read,
  @JsonValue('THINK')
  think,
  @JsonValue('CANT_SEE')
  cantSee,
}

/// The object an answer is about. Every answer names it first (rule 1).
@freezed
abstract class Referent with _$Referent {
  const factory Referent({
    required String id,
    required String label,
    @Default('') String shortDescription,
    @Default('') String location,

    /// [x, y, width, height], each 0–1 from the top-left corner.
    List<double>? bbox,
  }) = _Referent;

  factory Referent.fromJson(Map<String, dynamic> json) =>
      _$ReferentFromJson(json);
}

/// One change to the object registry proposed by the model.
@freezed
abstract class RegistryUpdate with _$RegistryUpdate {
  const factory RegistryUpdate({
    required String id,
    required String label,
    @Default('') String shortDescription,
    @Default('') String location,
    @Default('') String identifiedAs,
  }) = _RegistryUpdate;

  factory RegistryUpdate.fromJson(Map<String, dynamic> json) =>
      _$RegistryUpdateFromJson(json);
}

/// The structured reply from the vision-language model. Field order matches
/// the schema in Section 8, which matters for streaming.
@freezed
abstract class VlmResponse with _$VlmResponse {
  const factory VlmResponse({
    required bool needsClarification,
    @Default(<String>[]) List<String> clarificationOptions,
    Referent? referent,
    required Evidence evidence,
    @Default('') String readText,
    required Confidence confidence,
    @Default('') String confidenceReason,
    @Default('') String observation,
    @Default('') String nextStep,
    @Default('') String detail,
    @Default(false) bool answerChanged,
    @Default(<RegistryUpdate>[]) List<RegistryUpdate> registryUpdates,
  }) = _VlmResponse;

  factory VlmResponse.fromJson(Map<String, dynamic> json) =>
      _$VlmResponseFromJson(json);
}
