import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sarsys_domain/src/core/models/position.dart';
import 'package:sarsys_domain/src/core/models/source.dart';
import 'package:sarsys_domain/src/core/models/track.dart';

part 'tracking.g.dart';

@JsonSerializable(explicitToJson: true)
class TrackingModel extends Equatable {
  TrackingModel({
    @required this.uuid,
    @required this.status,
    @required this.speed,
    @required this.effort,
    @required this.tracks,
    @required this.sources,
    @required this.history,
    @required this.position,
    @required this.distance,
  }) : super();

  final String uuid;

  @JsonKey(nullable: true)
  final TrackingStatus status;

  final double speed;
  final Duration effort;
  final double distance;
  final PositionModel position;

  final List<TrackModel> tracks;
  final List<SourceModel> sources;
  final List<PositionModel> history;

  /// Factory constructor for creating a new `TrackingModel`  instance
  factory TrackingModel.fromJson(Map<String, dynamic> json) => _$TrackingModelFromJson(json);

  /// Declare support for serialization to JSON
  Map<String, dynamic> toJson() => _$TrackingModelToJson(this);

  @override
  List<Object> get props => [
        uuid,
        speed,
        status,
        effort,
        tracks,
        sources,
        history,
        distance,
        position,
      ];

  /// Clone with given devices and state
  TrackingModel cloneWith({
    double speed,
    double distance,
    Duration effort,
    PositionModel position,
    List<SourceModel> sources,
    List<PositionModel> history,
    TrackingStatus status,
    List<TrackModel> tracks,
  }) {
    return TrackingModel(
      uuid: uuid,
      status: status ?? this.status,
      position: position ?? this.position,
      distance: distance ?? this.distance,
      speed: speed ?? this.speed,
      effort: effort ?? this.effort,
      sources: sources ?? this.sources,
      history: history ?? this.history,
      tracks: tracks ?? this.tracks,
    );
  }
}

enum TrackingStatus {
  created,
  tracking,
  paused,
  closed,
}
