import 'dart:math';

import 'package:sarsys_domain/src/core/models/models.dart';
import 'package:sarsys_domain/src/core/proj4d.dart';

class TrackingUtils {
  /// Calculate average speed from distance and duration
  static double speed(double distance, Duration duration) =>
      distance.isNaN == false && duration.inMicroseconds > 0.0 ? distance / duration.inSeconds : 0.0;

  /// Calculate distance from history
  static double distance(
    List<PositionModel> history, {
    double distance = 0,
    int tail = 2,
  }) {
    distance ??= 0;
    var offset = max(0, history.length - tail - 1);
    var i = offset + 1;
    history?.skip(offset)?.forEach((p) {
      i++;
      distance += i < history.length
          ? ProjMath.eucledianDistance(
              history[i]?.lat ?? p.lat,
              history[i]?.lon ?? p.lon,
              p.lat,
              p.lon,
            )
          : 0.0;
    });
    return distance;
  }

  /// Calculate effort from history
  static Duration effort(List<PositionModel> history) => history?.isNotEmpty == true
      ? history.last.timestamp.difference(
          history.first.timestamp,
        )
      : Duration.zero;

  /// Calculate tracking position as geometric
  /// average of last position in each track
  static PositionModel average(TrackingModel tracking) {
    final current = tracking.position;
    final sources = tracking.sources;

    // Calculate geometric centre of all
    // source tracks as the arithmetic mean
    // of the input coordinates
    if (sources.isEmpty) {
      return current;
    } else if (sources.length == 1) {
      final track = find(tracking, sources.first.uuid);
      return track?.positions?.last ?? current;
    }
    final tracks = tracking.tracks;
    // Aggregate lat, lon, acc and latest timestamp in tracks
    var sum = tracks.fold<List<num>>(
      [0.0, 0.0, 0.0, 0.0],
      (sum, track) => track.positions.isEmpty
          ? sum
          : [
              track.positions.last.lat + sum[0],
              track.positions.last.lon + sum[1],
              (track.positions.last.acc ?? 0.0) + sum[2],
              max(
                sum[3],
                track.positions.last.timestamp.millisecondsSinceEpoch,
              ),
            ],
    );
    final count = tracks.length;
    return PositionModel(
      geometry: PointModel.fromCoords(
        lat: sum[0] / count,
        lon: sum[1] / count,
      ),
      properties: PositionModelProps(
        acc: sum[2] / count,
        source: PositionSource.aggregate,
        timestamp: DateTime.fromMillisecondsSinceEpoch(sum[3]),
      ),
    );
  }

  /// Attach given [source] to a track
  static TrackingModel attach(TrackingModel tracking, SourceModel source) {
    final sources = Set<SourceModel>.from(tracking.sources)..add(source);
    final tracks = List<TrackModel>.from(tracking.tracks);
    final existing = find(tracking, source.uuid);
    final track = existing == null
        ? TrackModel(
            id: source.uuid,
            positions: [],
            source: source,
            status: TrackStatus.attached,
          )
        : existing.cloneWith(
            status: TrackStatus.attached,
          );
    return tracking.cloneWith(
      sources: sources.toList(),
      tracks: tracks..add(track),
    );
  }

  /// Detach [SourceModel] with given [suuid] from track
  static TrackingModel detach(
    TrackingModel tracking,
    String suuid, {
    bool delete = false,
  }) {
    final sources = List<SourceModel>.from(tracking.sources)
      ..removeWhere(
        (source) => source.uuid == suuid,
      );
    List tracks = delete
        ? findAndDelete(
            tracking,
            suuid,
          )
        : findAndDetach(
            tracking,
            suuid,
          );
    return tracking.cloneWith(
      sources: sources,
      tracks: tracks,
      status: derive(tracking.status, sources),
    );
  }

  static TrackingModel closed(TrackingModel tracking) {
    return tracking.cloneWith(
      status: TrackingStatus.closed,
      sources: [],
      tracks: tracking.tracks.map((track) => track.cloneWith(status: TrackStatus.detached)).toList(),
    );
  }

  static TrackingModel reopened(TrackingModel tracking) {
    if (TrackingStatus.closed == tracking.status) {
      final sources = tracking.tracks.map((track) => track.source);
      final tracks = tracking.tracks.map((track) => track.cloneWith(status: TrackStatus.attached));
      return tracking.cloneWith(
        status: derive(TrackingStatus.closed, sources, defaultStatus: TrackingStatus.created),
        sources: sources.toList(),
        tracks: tracks.toList(),
      );
    }
    return tracking;
  }

  static List<TrackModel> findAndDelete(TrackingModel tracking, String suuid) {
    final track = find(tracking, suuid);
    final tracks = List.from(tracking.tracks);
    if (track != null) {
      tracks.remove(track);
    }
    return tracks;
  }

  static List<TrackModel> findAndDetach(TrackingModel tracking, String suuid) {
    final track = find(tracking, suuid);
    final tracks = List.from(tracking.tracks);
    if (track != null) {
      tracks.remove(track);
      tracks.add(
        track.cloneWith(status: TrackStatus.detached),
      );
    }
    return tracks;
  }

  /// Find track for given [SourceModel] with [suuid]
  static TrackModel find(TrackingModel tracking, String suuid) => tracking.tracks.firstWhere(
        (track) => track.source.uuid == suuid,
        orElse: () => null,
      );

  static TrackingStatus derive(
    TrackingStatus current,
    Iterable<SourceModel> sources, {
    TrackingStatus defaultStatus,
  }) {
    final hasSources = sources.isNotEmpty;
    final next = [TrackingStatus.created].contains(current)
        ? (hasSources ? TrackingStatus.tracking : TrackingStatus.created)
        : (hasSources
            ? TrackingStatus.tracking
            : ([TrackingStatus.closed].contains(current) ? (defaultStatus ?? current) : TrackingStatus.paused));
    return next;
  }
}
