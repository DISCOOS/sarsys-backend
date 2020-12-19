// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AtomItem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AtomItem _$AtomItemFromJson(Map json) {
  return AtomItem(
    id: json['id'] as String,
    title: json['title'] as String,
    updated: json['updated'] as String,
    author: json['author'] == null
        ? null
        : AtomAuthor.fromJson((json['author'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    summary: json['summary'] as String,
    links: (json['links'] as List)
        ?.map((e) => e == null
            ? null
            : AtomLink.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    streamId: json['streamId'] as String,
    eventId: json['eventId'] as String,
    eventType: json['eventType'] as String,
    eventNumber: json['eventNumber'] as int,
    isJson: json['isJson'] as bool,
    isMetaData: json['isMetaData'] as bool,
    isLinkMetaData: json['isLinkMetaData'] as bool,
    data: (json['data'] as Map)?.map(
      (k, e) => MapEntry(k as String, e),
    ),
  );
}

Map<String, dynamic> _$AtomItemToJson(AtomItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('title', instance.title);
  writeNotNull('updated', instance.updated);
  writeNotNull('summary', instance.summary);
  writeNotNull('author', instance.author?.toJson());
  writeNotNull('links', instance.links?.map((e) => e?.toJson())?.toList());
  writeNotNull('eventId', instance.eventId);
  writeNotNull('streamId', instance.streamId);
  writeNotNull('eventType', instance.eventType);
  writeNotNull('eventNumber', instance.eventNumber);
  writeNotNull('isJson', instance.isJson);
  writeNotNull('isMetaData', instance.isMetaData);
  writeNotNull('isLinkMetaData', instance.isLinkMetaData);
  writeNotNull('data', instance.data);
  return val;
}
