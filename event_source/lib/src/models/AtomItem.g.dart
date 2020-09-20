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
      ));
}

Map<String, dynamic> _$AtomItemToJson(AtomItem instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'updated': instance.updated,
      'summary': instance.summary,
      'author': instance.author?.toJson(),
      'links': instance.links?.map((e) => e?.toJson())?.toList(),
      'eventId': instance.eventId,
      'streamId': instance.streamId,
      'eventType': instance.eventType,
      'eventNumber': instance.eventNumber,
      'isJson': instance.isJson,
      'isMetaData': instance.isMetaData,
      'isLinkMetaData': instance.isLinkMetaData,
      'data': instance.data
    };
