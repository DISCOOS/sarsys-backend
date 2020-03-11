import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sarsys_domain/src/core/models/position.dart';
import 'package:sarsys_domain/src/core/models/source.dart';

part 'track.g.dart';

@JsonSerializable(explicitToJson: true)
class TrackModel extends Equatable {
  TrackModel({
    @required this.id,
    @required this.status,
    @required this.source,
    @required this.positions,
  }) : super();

  final String id;
  final TrackStatus status;
  final SourceModel source;
  final List<PositionModel> positions;

  /// Factory constructor for creating a new `TrackModel`  instance
  factory TrackModel.fromJson(Map<String, dynamic> json) => _$TrackModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$TrackModelToJson(this);

  @override
  List<Object> get props => [
        id,
        status,
        source,
        positions,
      ];

  TrackModel cloneWith({
    String id,
    TrackStatus status,
    SourceModel source,
    List<PositionModel> positions,
  }) =>
      TrackModel(
        id: id ?? this.id,
        status: status ?? this.status,
        source: source ?? this.source,
        positions: positions ?? this.positions,
      );
}

enum TrackStatus { attached, detached }
