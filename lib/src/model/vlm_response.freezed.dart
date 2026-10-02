// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vlm_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Referent {

 String get id; String get label; String get shortDescription; String get location;/// [x, y, width, height], each 0–1 from the top-left corner.
 List<double>? get bbox;
/// Create a copy of Referent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferentCopyWith<Referent> get copyWith => _$ReferentCopyWithImpl<Referent>(this as Referent, _$identity);

  /// Serializes this Referent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Referent&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.bbox, bbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,shortDescription,location,const DeepCollectionEquality().hash(bbox));

@override
String toString() {
  return 'Referent(id: $id, label: $label, shortDescription: $shortDescription, location: $location, bbox: $bbox)';
}


}

/// @nodoc
abstract mixin class $ReferentCopyWith<$Res>  {
  factory $ReferentCopyWith(Referent value, $Res Function(Referent) _then) = _$ReferentCopyWithImpl;
@useResult
$Res call({
 String id, String label, String shortDescription, String location, List<double>? bbox
});




}
/// @nodoc
class _$ReferentCopyWithImpl<$Res>
    implements $ReferentCopyWith<$Res> {
  _$ReferentCopyWithImpl(this._self, this._then);

  final Referent _self;
  final $Res Function(Referent) _then;

/// Create a copy of Referent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? shortDescription = null,Object? location = null,Object? bbox = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,bbox: freezed == bbox ? _self.bbox : bbox // ignore: cast_nullable_to_non_nullable
as List<double>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Referent].
extension ReferentPatterns on Referent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Referent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Referent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Referent value)  $default,){
final _that = this;
switch (_that) {
case _Referent():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Referent value)?  $default,){
final _that = this;
switch (_that) {
case _Referent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String shortDescription,  String location,  List<double>? bbox)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Referent() when $default != null:
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.bbox);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String shortDescription,  String location,  List<double>? bbox)  $default,) {final _that = this;
switch (_that) {
case _Referent():
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.bbox);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String shortDescription,  String location,  List<double>? bbox)?  $default,) {final _that = this;
switch (_that) {
case _Referent() when $default != null:
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.bbox);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Referent implements Referent {
  const _Referent({required this.id, required this.label, this.shortDescription = '', this.location = '', final  List<double>? bbox}): _bbox = bbox;
  factory _Referent.fromJson(Map<String, dynamic> json) => _$ReferentFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  String shortDescription;
@override@JsonKey() final  String location;
/// [x, y, width, height], each 0–1 from the top-left corner.
 final  List<double>? _bbox;
/// [x, y, width, height], each 0–1 from the top-left corner.
@override List<double>? get bbox {
  final value = _bbox;
  if (value == null) return null;
  if (_bbox is EqualUnmodifiableListView) return _bbox;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Referent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferentCopyWith<_Referent> get copyWith => __$ReferentCopyWithImpl<_Referent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Referent&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._bbox, _bbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,shortDescription,location,const DeepCollectionEquality().hash(_bbox));

@override
String toString() {
  return 'Referent(id: $id, label: $label, shortDescription: $shortDescription, location: $location, bbox: $bbox)';
}


}

/// @nodoc
abstract mixin class _$ReferentCopyWith<$Res> implements $ReferentCopyWith<$Res> {
  factory _$ReferentCopyWith(_Referent value, $Res Function(_Referent) _then) = __$ReferentCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String shortDescription, String location, List<double>? bbox
});




}
/// @nodoc
class __$ReferentCopyWithImpl<$Res>
    implements _$ReferentCopyWith<$Res> {
  __$ReferentCopyWithImpl(this._self, this._then);

  final _Referent _self;
  final $Res Function(_Referent) _then;

/// Create a copy of Referent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? shortDescription = null,Object? location = null,Object? bbox = freezed,}) {
  return _then(_Referent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,bbox: freezed == bbox ? _self._bbox : bbox // ignore: cast_nullable_to_non_nullable
as List<double>?,
  ));
}


}


/// @nodoc
mixin _$RegistryUpdate {

 String get id; String get label; String get shortDescription; String get location; String get identifiedAs;
/// Create a copy of RegistryUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegistryUpdateCopyWith<RegistryUpdate> get copyWith => _$RegistryUpdateCopyWithImpl<RegistryUpdate>(this as RegistryUpdate, _$identity);

  /// Serializes this RegistryUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegistryUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.location, location) || other.location == location)&&(identical(other.identifiedAs, identifiedAs) || other.identifiedAs == identifiedAs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,shortDescription,location,identifiedAs);

@override
String toString() {
  return 'RegistryUpdate(id: $id, label: $label, shortDescription: $shortDescription, location: $location, identifiedAs: $identifiedAs)';
}


}

/// @nodoc
abstract mixin class $RegistryUpdateCopyWith<$Res>  {
  factory $RegistryUpdateCopyWith(RegistryUpdate value, $Res Function(RegistryUpdate) _then) = _$RegistryUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String label, String shortDescription, String location, String identifiedAs
});




}
/// @nodoc
class _$RegistryUpdateCopyWithImpl<$Res>
    implements $RegistryUpdateCopyWith<$Res> {
  _$RegistryUpdateCopyWithImpl(this._self, this._then);

  final RegistryUpdate _self;
  final $Res Function(RegistryUpdate) _then;

/// Create a copy of RegistryUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? shortDescription = null,Object? location = null,Object? identifiedAs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,identifiedAs: null == identifiedAs ? _self.identifiedAs : identifiedAs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegistryUpdate].
extension RegistryUpdatePatterns on RegistryUpdate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegistryUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegistryUpdate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegistryUpdate value)  $default,){
final _that = this;
switch (_that) {
case _RegistryUpdate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegistryUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _RegistryUpdate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String shortDescription,  String location,  String identifiedAs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegistryUpdate() when $default != null:
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.identifiedAs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String shortDescription,  String location,  String identifiedAs)  $default,) {final _that = this;
switch (_that) {
case _RegistryUpdate():
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.identifiedAs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String shortDescription,  String location,  String identifiedAs)?  $default,) {final _that = this;
switch (_that) {
case _RegistryUpdate() when $default != null:
return $default(_that.id,_that.label,_that.shortDescription,_that.location,_that.identifiedAs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegistryUpdate implements RegistryUpdate {
  const _RegistryUpdate({required this.id, required this.label, this.shortDescription = '', this.location = '', this.identifiedAs = ''});
  factory _RegistryUpdate.fromJson(Map<String, dynamic> json) => _$RegistryUpdateFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  String shortDescription;
@override@JsonKey() final  String location;
@override@JsonKey() final  String identifiedAs;

/// Create a copy of RegistryUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegistryUpdateCopyWith<_RegistryUpdate> get copyWith => __$RegistryUpdateCopyWithImpl<_RegistryUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegistryUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegistryUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.location, location) || other.location == location)&&(identical(other.identifiedAs, identifiedAs) || other.identifiedAs == identifiedAs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,shortDescription,location,identifiedAs);

@override
String toString() {
  return 'RegistryUpdate(id: $id, label: $label, shortDescription: $shortDescription, location: $location, identifiedAs: $identifiedAs)';
}


}

/// @nodoc
abstract mixin class _$RegistryUpdateCopyWith<$Res> implements $RegistryUpdateCopyWith<$Res> {
  factory _$RegistryUpdateCopyWith(_RegistryUpdate value, $Res Function(_RegistryUpdate) _then) = __$RegistryUpdateCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String shortDescription, String location, String identifiedAs
});




}
/// @nodoc
class __$RegistryUpdateCopyWithImpl<$Res>
    implements _$RegistryUpdateCopyWith<$Res> {
  __$RegistryUpdateCopyWithImpl(this._self, this._then);

  final _RegistryUpdate _self;
  final $Res Function(_RegistryUpdate) _then;

/// Create a copy of RegistryUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? shortDescription = null,Object? location = null,Object? identifiedAs = null,}) {
  return _then(_RegistryUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,shortDescription: null == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,identifiedAs: null == identifiedAs ? _self.identifiedAs : identifiedAs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VlmResponse {

 bool get needsClarification; List<String> get clarificationOptions; Referent? get referent; Evidence get evidence; String get readText; Confidence get confidence; String get confidenceReason; String get observation; String get nextStep; String get detail; bool get answerChanged; List<RegistryUpdate> get registryUpdates;
/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VlmResponseCopyWith<VlmResponse> get copyWith => _$VlmResponseCopyWithImpl<VlmResponse>(this as VlmResponse, _$identity);

  /// Serializes this VlmResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VlmResponse&&(identical(other.needsClarification, needsClarification) || other.needsClarification == needsClarification)&&const DeepCollectionEquality().equals(other.clarificationOptions, clarificationOptions)&&(identical(other.referent, referent) || other.referent == referent)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&(identical(other.readText, readText) || other.readText == readText)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.confidenceReason, confidenceReason) || other.confidenceReason == confidenceReason)&&(identical(other.observation, observation) || other.observation == observation)&&(identical(other.nextStep, nextStep) || other.nextStep == nextStep)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.answerChanged, answerChanged) || other.answerChanged == answerChanged)&&const DeepCollectionEquality().equals(other.registryUpdates, registryUpdates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,needsClarification,const DeepCollectionEquality().hash(clarificationOptions),referent,evidence,readText,confidence,confidenceReason,observation,nextStep,detail,answerChanged,const DeepCollectionEquality().hash(registryUpdates));

@override
String toString() {
  return 'VlmResponse(needsClarification: $needsClarification, clarificationOptions: $clarificationOptions, referent: $referent, evidence: $evidence, readText: $readText, confidence: $confidence, confidenceReason: $confidenceReason, observation: $observation, nextStep: $nextStep, detail: $detail, answerChanged: $answerChanged, registryUpdates: $registryUpdates)';
}


}

/// @nodoc
abstract mixin class $VlmResponseCopyWith<$Res>  {
  factory $VlmResponseCopyWith(VlmResponse value, $Res Function(VlmResponse) _then) = _$VlmResponseCopyWithImpl;
@useResult
$Res call({
 bool needsClarification, List<String> clarificationOptions, Referent? referent, Evidence evidence, String readText, Confidence confidence, String confidenceReason, String observation, String nextStep, String detail, bool answerChanged, List<RegistryUpdate> registryUpdates
});


$ReferentCopyWith<$Res>? get referent;

}
/// @nodoc
class _$VlmResponseCopyWithImpl<$Res>
    implements $VlmResponseCopyWith<$Res> {
  _$VlmResponseCopyWithImpl(this._self, this._then);

  final VlmResponse _self;
  final $Res Function(VlmResponse) _then;

/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? needsClarification = null,Object? clarificationOptions = null,Object? referent = freezed,Object? evidence = null,Object? readText = null,Object? confidence = null,Object? confidenceReason = null,Object? observation = null,Object? nextStep = null,Object? detail = null,Object? answerChanged = null,Object? registryUpdates = null,}) {
  return _then(_self.copyWith(
needsClarification: null == needsClarification ? _self.needsClarification : needsClarification // ignore: cast_nullable_to_non_nullable
as bool,clarificationOptions: null == clarificationOptions ? _self.clarificationOptions : clarificationOptions // ignore: cast_nullable_to_non_nullable
as List<String>,referent: freezed == referent ? _self.referent : referent // ignore: cast_nullable_to_non_nullable
as Referent?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as Evidence,readText: null == readText ? _self.readText : readText // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as Confidence,confidenceReason: null == confidenceReason ? _self.confidenceReason : confidenceReason // ignore: cast_nullable_to_non_nullable
as String,observation: null == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as String,nextStep: null == nextStep ? _self.nextStep : nextStep // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,answerChanged: null == answerChanged ? _self.answerChanged : answerChanged // ignore: cast_nullable_to_non_nullable
as bool,registryUpdates: null == registryUpdates ? _self.registryUpdates : registryUpdates // ignore: cast_nullable_to_non_nullable
as List<RegistryUpdate>,
  ));
}
/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferentCopyWith<$Res>? get referent {
    if (_self.referent == null) {
    return null;
  }

  return $ReferentCopyWith<$Res>(_self.referent!, (value) {
    return _then(_self.copyWith(referent: value));
  });
}
}


/// Adds pattern-matching-related methods to [VlmResponse].
extension VlmResponsePatterns on VlmResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VlmResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VlmResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VlmResponse value)  $default,){
final _that = this;
switch (_that) {
case _VlmResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VlmResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VlmResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool needsClarification,  List<String> clarificationOptions,  Referent? referent,  Evidence evidence,  String readText,  Confidence confidence,  String confidenceReason,  String observation,  String nextStep,  String detail,  bool answerChanged,  List<RegistryUpdate> registryUpdates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VlmResponse() when $default != null:
return $default(_that.needsClarification,_that.clarificationOptions,_that.referent,_that.evidence,_that.readText,_that.confidence,_that.confidenceReason,_that.observation,_that.nextStep,_that.detail,_that.answerChanged,_that.registryUpdates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool needsClarification,  List<String> clarificationOptions,  Referent? referent,  Evidence evidence,  String readText,  Confidence confidence,  String confidenceReason,  String observation,  String nextStep,  String detail,  bool answerChanged,  List<RegistryUpdate> registryUpdates)  $default,) {final _that = this;
switch (_that) {
case _VlmResponse():
return $default(_that.needsClarification,_that.clarificationOptions,_that.referent,_that.evidence,_that.readText,_that.confidence,_that.confidenceReason,_that.observation,_that.nextStep,_that.detail,_that.answerChanged,_that.registryUpdates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool needsClarification,  List<String> clarificationOptions,  Referent? referent,  Evidence evidence,  String readText,  Confidence confidence,  String confidenceReason,  String observation,  String nextStep,  String detail,  bool answerChanged,  List<RegistryUpdate> registryUpdates)?  $default,) {final _that = this;
switch (_that) {
case _VlmResponse() when $default != null:
return $default(_that.needsClarification,_that.clarificationOptions,_that.referent,_that.evidence,_that.readText,_that.confidence,_that.confidenceReason,_that.observation,_that.nextStep,_that.detail,_that.answerChanged,_that.registryUpdates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VlmResponse implements VlmResponse {
  const _VlmResponse({required this.needsClarification, final  List<String> clarificationOptions = const <String>[], this.referent, required this.evidence, this.readText = '', required this.confidence, this.confidenceReason = '', this.observation = '', this.nextStep = '', this.detail = '', this.answerChanged = false, final  List<RegistryUpdate> registryUpdates = const <RegistryUpdate>[]}): _clarificationOptions = clarificationOptions,_registryUpdates = registryUpdates;
  factory _VlmResponse.fromJson(Map<String, dynamic> json) => _$VlmResponseFromJson(json);

@override final  bool needsClarification;
 final  List<String> _clarificationOptions;
@override@JsonKey() List<String> get clarificationOptions {
  if (_clarificationOptions is EqualUnmodifiableListView) return _clarificationOptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clarificationOptions);
}

@override final  Referent? referent;
@override final  Evidence evidence;
@override@JsonKey() final  String readText;
@override final  Confidence confidence;
@override@JsonKey() final  String confidenceReason;
@override@JsonKey() final  String observation;
@override@JsonKey() final  String nextStep;
@override@JsonKey() final  String detail;
@override@JsonKey() final  bool answerChanged;
 final  List<RegistryUpdate> _registryUpdates;
@override@JsonKey() List<RegistryUpdate> get registryUpdates {
  if (_registryUpdates is EqualUnmodifiableListView) return _registryUpdates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_registryUpdates);
}


/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VlmResponseCopyWith<_VlmResponse> get copyWith => __$VlmResponseCopyWithImpl<_VlmResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VlmResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VlmResponse&&(identical(other.needsClarification, needsClarification) || other.needsClarification == needsClarification)&&const DeepCollectionEquality().equals(other._clarificationOptions, _clarificationOptions)&&(identical(other.referent, referent) || other.referent == referent)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&(identical(other.readText, readText) || other.readText == readText)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.confidenceReason, confidenceReason) || other.confidenceReason == confidenceReason)&&(identical(other.observation, observation) || other.observation == observation)&&(identical(other.nextStep, nextStep) || other.nextStep == nextStep)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.answerChanged, answerChanged) || other.answerChanged == answerChanged)&&const DeepCollectionEquality().equals(other._registryUpdates, _registryUpdates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,needsClarification,const DeepCollectionEquality().hash(_clarificationOptions),referent,evidence,readText,confidence,confidenceReason,observation,nextStep,detail,answerChanged,const DeepCollectionEquality().hash(_registryUpdates));

@override
String toString() {
  return 'VlmResponse(needsClarification: $needsClarification, clarificationOptions: $clarificationOptions, referent: $referent, evidence: $evidence, readText: $readText, confidence: $confidence, confidenceReason: $confidenceReason, observation: $observation, nextStep: $nextStep, detail: $detail, answerChanged: $answerChanged, registryUpdates: $registryUpdates)';
}


}

/// @nodoc
abstract mixin class _$VlmResponseCopyWith<$Res> implements $VlmResponseCopyWith<$Res> {
  factory _$VlmResponseCopyWith(_VlmResponse value, $Res Function(_VlmResponse) _then) = __$VlmResponseCopyWithImpl;
@override @useResult
$Res call({
 bool needsClarification, List<String> clarificationOptions, Referent? referent, Evidence evidence, String readText, Confidence confidence, String confidenceReason, String observation, String nextStep, String detail, bool answerChanged, List<RegistryUpdate> registryUpdates
});


@override $ReferentCopyWith<$Res>? get referent;

}
/// @nodoc
class __$VlmResponseCopyWithImpl<$Res>
    implements _$VlmResponseCopyWith<$Res> {
  __$VlmResponseCopyWithImpl(this._self, this._then);

  final _VlmResponse _self;
  final $Res Function(_VlmResponse) _then;

/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? needsClarification = null,Object? clarificationOptions = null,Object? referent = freezed,Object? evidence = null,Object? readText = null,Object? confidence = null,Object? confidenceReason = null,Object? observation = null,Object? nextStep = null,Object? detail = null,Object? answerChanged = null,Object? registryUpdates = null,}) {
  return _then(_VlmResponse(
needsClarification: null == needsClarification ? _self.needsClarification : needsClarification // ignore: cast_nullable_to_non_nullable
as bool,clarificationOptions: null == clarificationOptions ? _self._clarificationOptions : clarificationOptions // ignore: cast_nullable_to_non_nullable
as List<String>,referent: freezed == referent ? _self.referent : referent // ignore: cast_nullable_to_non_nullable
as Referent?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as Evidence,readText: null == readText ? _self.readText : readText // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as Confidence,confidenceReason: null == confidenceReason ? _self.confidenceReason : confidenceReason // ignore: cast_nullable_to_non_nullable
as String,observation: null == observation ? _self.observation : observation // ignore: cast_nullable_to_non_nullable
as String,nextStep: null == nextStep ? _self.nextStep : nextStep // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,answerChanged: null == answerChanged ? _self.answerChanged : answerChanged // ignore: cast_nullable_to_non_nullable
as bool,registryUpdates: null == registryUpdates ? _self._registryUpdates : registryUpdates // ignore: cast_nullable_to_non_nullable
as List<RegistryUpdate>,
  ));
}

/// Create a copy of VlmResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReferentCopyWith<$Res>? get referent {
    if (_self.referent == null) {
    return null;
  }

  return $ReferentCopyWith<$Res>(_self.referent!, (value) {
    return _then(_self.copyWith(referent: value));
  });
}
}

// dart format on
