import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'AtomAuthor.g.dart';

@JsonSerializable()
class AtomAuthor extends Equatable {
  const AtomAuthor({
    @required this.name,
  });

  /// Factory constructor for creating a new `AtomAuthor` instance
  factory AtomAuthor.fromJson(Map<String, dynamic> json) => _$AtomAuthorFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$AtomAuthorToJson(this);

  final String name;

  @override
  List<Object> get props => [
        name,
      ];
}
