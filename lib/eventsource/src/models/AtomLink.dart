import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'AtomLink.g.dart';

@JsonSerializable()
class AtomLink extends Equatable {
  const AtomLink({
    @required this.uri,
    @required this.relation,
  });

  /// Factory constructor for creating a new `AtomLink` instance
  factory AtomLink.fromJson(Map<String, dynamic> json) => _$AtomLinkFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$AtomLinkToJson(this);

  final String uri;
  final String relation;

  @override
  List<Object> get props => [
        uri,
        relation,
      ];
}
