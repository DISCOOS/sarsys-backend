import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:json_annotation/json_annotation.dart';

part 'source.g.dart';

@JsonSerializable(explicitToJson: true)
class SourceModel extends Equatable {
  SourceModel({
    @required this.uuid,
    @required this.type,
  }) : super();

  final String uuid;
  final SourceType type;

  /// Factory constructor for creating a new `SourceModel`  instance
  factory SourceModel.fromJson(Map<String, dynamic> json) => _$SourceModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$SourceModelToJson(this);

  @override
  List<Object> get props => [uuid, type];
}

enum SourceType { device, trackable }
