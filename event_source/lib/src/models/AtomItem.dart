import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'AtomAuthor.dart';
import 'AtomLink.dart';

part 'AtomItem.g.dart';

@JsonSerializable()
class AtomItem extends Equatable {
  const AtomItem({
    @required this.id,
    @required this.title,
    @required this.updated,
    @required this.author,
    @required this.summary,
    @required this.links,
    // Embedded fields
    this.streamId,
    this.eventId,
    this.eventType,
    this.eventNumber,
    this.isJson,
    this.isMetaData,
    this.isLinkMetaData,
    this.data,
  });

  /// Factory constructor for creating a new `AtomItem` instance
  factory AtomItem.fromJson(Map<String, dynamic> json) => _$AtomItemFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$AtomItemToJson(this);

  static const String edit = 'edit';
  static const String alternate = 'alternate';

  final String id;
  final String title;
  final String updated;
  final String summary;
  final AtomAuthor author;
  final List<AtomLink> links;

  // --- Embedded ---
  final String eventId;
  final String streamId;
  final String eventType;
  final int eventNumber;
  final bool isJson;
  final bool isMetaData;
  final bool isLinkMetaData;
  final Map<String, dynamic> data;

  bool has(String relation) => links.any((test) => test.relation == relation);

  String getUri(String relation) => links
      .firstWhere(
        (test) => test.relation == relation,
        orElse: () => null,
      )
      ?.uri;

  @override
  List<Object> get props => [
        id,
        title,
        updated,
        summary,
        links,
        data,
      ];
}
