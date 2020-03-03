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
    @required this.streamId,
    @required this.author,
    @required this.summary,
    @required this.links,
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
  final String streamId;
  final String summary;
  final AtomAuthor author;
  final List<AtomLink> links;

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
      ];
}
