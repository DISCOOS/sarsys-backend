import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'AtomAuthor.dart';
import 'AtomItem.dart';
import 'AtomLink.dart';

part 'AtomFeed.g.dart';

@JsonSerializable()
class AtomFeed extends Equatable {
  const AtomFeed({
    @required this.id,
    @required this.title,
    @required this.updated,
    @required this.author,
    @required this.headOfStream,
    @required this.selfUrl,
    @required this.eTag,
    @required this.links,
    @required this.entries,
  });

  /// Factory constructor for creating a new `AtomFeed` instance
  factory AtomFeed.fromJson(Map<String, dynamic> json) => _$AtomFeedFromJson(json);

  static const String self = 'self';
  static const String first = 'first';
  static const String previous = 'previous';
  static const String next = 'next';
  static const String last = 'first';
  static const String metadata = 'next';

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$AtomFeedToJson(this);

  final String id;
  final String title;
  final String updated;
  final AtomAuthor author;
  final bool headOfStream;
  final String selfUrl;
  final String eTag;
  final List<AtomLink> links;
  final List<AtomItem> entries;

  bool has(String relation) => links.any((test) => test.relation == relation);

  String getUri(String relation) => links.firstWhere((test) => test.relation == relation)?.uri;

  @override
  List<Object> get props => [
        id,
        title,
        updated,
        author,
        headOfStream,
        selfUrl,
        eTag,
        links,
        entries,
      ];
}
