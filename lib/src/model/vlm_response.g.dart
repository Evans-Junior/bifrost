// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vlm_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Referent _$ReferentFromJson(Map<String, dynamic> json) => _Referent(
  id: json['id'] as String,
  label: json['label'] as String,
  shortDescription: json['short_description'] as String? ?? '',
  location: json['location'] as String? ?? '',
  bbox: (json['bbox'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
);

Map<String, dynamic> _$ReferentToJson(_Referent instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'short_description': instance.shortDescription,
  'location': instance.location,
  'bbox': instance.bbox,
};

_RegistryUpdate _$RegistryUpdateFromJson(Map<String, dynamic> json) =>
    _RegistryUpdate(
      id: json['id'] as String,
      label: json['label'] as String,
      shortDescription: json['short_description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      identifiedAs: json['identified_as'] as String? ?? '',
    );

Map<String, dynamic> _$RegistryUpdateToJson(_RegistryUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'short_description': instance.shortDescription,
      'location': instance.location,
      'identified_as': instance.identifiedAs,
    };

_VlmResponse _$VlmResponseFromJson(Map<String, dynamic> json) => _VlmResponse(
  needsClarification: json['needs_clarification'] as bool,
  clarificationOptions:
      (json['clarification_options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  referent: json['referent'] == null
      ? null
      : Referent.fromJson(json['referent'] as Map<String, dynamic>),
  evidence: $enumDecode(_$EvidenceEnumMap, json['evidence']),
  readText: json['read_text'] as String? ?? '',
  confidence: $enumDecode(_$ConfidenceEnumMap, json['confidence']),
  confidenceReason: json['confidence_reason'] as String? ?? '',
  observation: json['observation'] as String? ?? '',
  nextStep: json['next_step'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  answerChanged: json['answer_changed'] as bool? ?? false,
  registryUpdates:
      (json['registry_updates'] as List<dynamic>?)
          ?.map((e) => RegistryUpdate.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RegistryUpdate>[],
);

Map<String, dynamic> _$VlmResponseToJson(
  _VlmResponse instance,
) => <String, dynamic>{
  'needs_clarification': instance.needsClarification,
  'clarification_options': instance.clarificationOptions,
  'referent': instance.referent?.toJson(),
  'evidence': _$EvidenceEnumMap[instance.evidence]!,
  'read_text': instance.readText,
  'confidence': _$ConfidenceEnumMap[instance.confidence]!,
  'confidence_reason': instance.confidenceReason,
  'observation': instance.observation,
  'next_step': instance.nextStep,
  'detail': instance.detail,
  'answer_changed': instance.answerChanged,
  'registry_updates': instance.registryUpdates.map((e) => e.toJson()).toList(),
};

const _$EvidenceEnumMap = {
  Evidence.read: 'READ',
  Evidence.seen: 'SEEN',
  Evidence.notVisible: 'NOT_VISIBLE',
};

const _$ConfidenceEnumMap = {
  Confidence.read: 'READ',
  Confidence.think: 'THINK',
  Confidence.cantSee: 'CANT_SEE',
};
