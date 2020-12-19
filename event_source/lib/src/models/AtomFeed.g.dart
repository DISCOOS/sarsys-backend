// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AtomFeed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AtomFeed _$AtomFeedFromJson(Map json) {
  return AtomFeed(
    id: json['id'] as String,
    title: json['title'] as String,
    updated: json['updated'] as String,
    author: json['author'] == null
        ? null
        : AtomAuthor.fromJson((json['author'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
    streamId: json['streamId'] as String,
    headOfStream: json['headOfStream'] as bool,
    selfUrl: json['selfUrl'] as String,
    eTag: json['eTag'] as String,
    links: (json['links'] as List)
        ?.map((e) => e == null
            ? null
            : AtomLink.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
    entries: (json['entries'] as List)
        ?.map((e) => e == null
            ? null
            : AtomItem.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList(),
  );
}

Map<String, dynamic> _$AtomFeedToJson(AtomFeed instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('title', instance.title);
  writeNotNull('updated', instance.updated);
  writeNotNull('streamId', instance.streamId);
  writeNotNull('author', instance.author?.toJson());
  writeNotNull('headOfStream', instance.headOfStream);
  writeNotNull('selfUrl', instance.selfUrl);
  writeNotNull('eTag', instance.eTag);
  writeNotNull('links', instance.links?.map((e) => e?.toJson())?.toList());
  writeNotNull('entries', instance.entries?.map((e) => e?.toJson())?.toList());
  return val;
}
