// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AtomAuthor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AtomAuthor _$AtomAuthorFromJson(Map json) {
  return AtomAuthor(
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$AtomAuthorToJson(AtomAuthor instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  return val;
}
