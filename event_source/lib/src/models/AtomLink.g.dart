// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AtomLink.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AtomLink _$AtomLinkFromJson(Map json) {
  return AtomLink(
    uri: json['uri'] as String,
    relation: json['relation'] as String,
  );
}

Map<String, dynamic> _$AtomLinkToJson(AtomLink instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('uri', instance.uri);
  writeNotNull('relation', instance.relation);
  return val;
}
