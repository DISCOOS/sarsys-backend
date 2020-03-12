import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_domain/src/core/models/models.dart';

/// A [Tracking] domain service.
///
/// This class compete with other [TrackingService]
/// instances on which [Tracking] instances it should manage
/// a position for. A persistent subscription on projection
/// '$et-TrackingCreated' with [ConsumerStrategy.RoundRobin]
/// is made when [build()] is called. This ensures than only
/// one [TrackingService] will manage tracks and
/// aggregate position from these for each [Tracking] instance,
/// regardless of how many [TrackingService] instances
/// are running in parallel, minimizing write contention on
/// each [Tracking] instance event stream.
///
/// Each [TrackingService] instance listen to events
/// when a source is added to, or removed from, a [Tracking]
/// instance it manages. When a source is added to a [Tracking]
/// instance it manages, a track is added to it with status
/// 'attached'. When a source is removed from a [Tracking]
/// instance it manages, the track is retained and put in
/// 'detached' mode.
///
/// Each source can only be attached to one [Tracking]
/// instance at any time. This invariant is enforced by
/// each manager by listening for [TrackingSourceAdded]
/// events. When a source is already attached to another
/// [Tracking] instance, the manager of the new instance
/// will copy the track from the previous [Tracking]
/// instance. In the unlikely event of a source being
/// concurrently attached to multiple [Tracking] instances,
/// the track with the most recent timestamp is chosen.
/// Managers of previous [Tracking] instances will detach
/// the source from the track it manages eventually.
/// This minimises the likelihood that positions are lost
/// when the same source is added to multiple [Tracking]
/// instances concurrently.
///
class TrackingService extends MessageHandler<DomainEvent> {
  static const String ID = 'id';
  static const String UUID = 'uuid';
  static const String TYPE = 'type';
  static const String SPEED = 'speed';
  static const String EFFORT = 'effort';
  static const String DISTANCE = 'distance';
  static const String STATUS = 'status';
  static const String TRACKS = 'tracks';
  static const String SOURCE = 'source';
  static const String SOURCES = 'sources';
  static const String HISTORY = 'history';
  static const String ATTACHED = 'attached';
  static const String DETACHED = 'detached';
  static const String POSITION = 'position';
  static const String POSITIONS = 'positions';
  static const String STREAM = '\$et-TrackingCreated';

  TrackingService(
    this.repository, {
    this.consume = 5,
    this.maxBackoffTime = const Duration(seconds: 10),
  });
  final int consume;
  final Duration maxBackoffTime;
  final TrackingRepository repository;
  final Set<String> _managed = {};
  final Map<String, Set<String>> _sources = {};
  final Logger logger = Logger('$TrackingService');

  SubscriptionController<TrackingRepository> _subscription;

  Set<String> get managed => Set.from(_managed);
  Map<String, Set<String>> get sources => Map.from(_sources);

  /// This stream will only contain [DomainEvent] pushed to remote stream
  final _streamController = StreamController<DomainEvent>.broadcast();

  /// Get remote [Event] stream.
  Stream<DomainEvent> asStream() {
    return _streamController.stream;
  }

  /// When true, this manager should not be used any more
  bool get disposed => _disposed;
  bool _disposed = false;

  /// Build competitive [Tracking] service
  FutureOr build() async {
    await _subscription?.cancel();
    _subscription = SubscriptionController<TrackingRepository>(
      logger: logger,
      onDone: _onDone,
      onEvent: _onEvent,
      onError: _onError,
      maxBackoffTime: maxBackoffTime,
    );
    final complete = _subscription.compete(
      repository,
      stream: STREAM,
      group: '$runtimeType',
      consume: consume,
      number: EventNumber.first,
      strategy: ConsumerStrategy.RoundRobin,
    );
    repository.store.bus.register<TrackingSourceAdded>(this);
    repository.store.bus.register<TrackingSourceRemoved>(this);
    repository.store.bus.register<DevicePositionChanged>(this);
    repository.store.bus.register<TrackingPositionChanged>(this);
    logger.info('Built with consumption count $consume from $STREAM');
    return complete;
  }

  bool get isPaused => _subscription?.isPaused;

  /// Pause all subscriptions
  void pause() async {
    _subscription?.pause();
  }

  /// Resume all subscriptions
  void resume() async {
    _subscription?.resume();
  }

  /// Must be called to prevent memory leaks
  void dispose() async {
    if (_streamController?.hasListener == true && _streamController?.isClosed == false) {
      // See https://github.com/dart-lang/sdk/issues/19095#issuecomment-108436560
      // ignore: unawaited_futures
      _streamController.close();
    }
    await _subscription?.cancel();
    _subscription = null;
    _disposed = true;
  }

  @override
  void handle(DomainEvent message) {
    try {
      switch (message.runtimeType) {
        case TrackingCreated:
          _onTrackingCreated(message);
          break;
        case TrackingSourceAdded:
          _onTrackingSourceAdded(message);
          break;
        case TrackingSourceRemoved:
          _onTrackingSourceRemoved(message);
          break;
        case DevicePositionChanged:
          _onSourcePositionChanged(message);
          break;
        case TrackingPositionChanged:
          _onSourcePositionChanged(message);
          break;
      }
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to handle $message: $e with stacktrace: $stackTrace',
      );
    }
  }

  /// Build map of all source uuids to its tracking uuids
  void _onTrackingCreated(TrackingCreated event) async => await _ensureManaged(event);

  /// Handles invariants
  ///
  /// Each source can only be attached to one [Tracking]
  /// instance at any time. This invariant is enforced by
  /// each manager by listening for [TrackingSourceAdded]
  /// events. When a source is already attached to another
  /// [Tracking] instance, the manager of the new instance
  /// will copy the track from the previous [Tracking]
  /// instance. In the unlikely event of a source being
  /// concurrently attached to multiple [Tracking] instances,
  /// the track with the most recent timestamp is chosen.
  /// Managers of previous [Tracking] instances will detach
  /// the source from the track it manages eventually.
  /// This minimises the likelihood that positions are lost
  /// when the same source is added to multiple [Tracking]
  /// instances concurrently.
  ///
  void _onTrackingSourceAdded(TrackingSourceAdded event) async {
    final uuid = repository.toAggregateUuid(event);
    if (_managed.contains(uuid)) {
      await _ensureManaged(event);
    } else {
      await _ensureDetached(event);
    }
  }

  /// If [TrackingSourceRemoved] was from a [Tracking] instance
  /// managed by this [TrackingService], the state of the
  /// associated track is changed to 'detached'
  void _onTrackingSourceRemoved(TrackingSourceRemoved event) async => await _ensureDetached(event);

  /// If [PositionEvent.source] belongs to a track managed by this
  /// [TrackingService] new position is added to attached track
  /// and a new [Tracking.point] is calculated based on current
  /// aggregation parameters.
  void _onSourcePositionChanged(PositionEvent event) async {
    final suuid = repository.toAggregateUuid(event);
    if (_sources.containsKey(suuid)) {
      final tuuids = _sources[suuid].where((tuuid) => _managed.contains(tuuid));
      await Future.forEach(tuuids, (tuuid) => _addPosition(tuuid, event));
    }
  }

  /// Add position to track for given source
  Future _addPosition(String uuid, PositionEvent event) async {
    final track = _findTrack(
      TrackingModel.fromJson(repository.get(uuid).data),
      repository.toAggregateUuid(event),
    );
    if (track != null) {
      final positions = track.positions ?? [];
      positions.add(PositionModel.fromJson(event.value));

      final events = await _updateTrack(
        uuid,
        track.cloneWith(positions: positions).toJson(),
      );
      if (events?.isNotEmpty == true) {
        _addToStream(
          [event, ...events],
          'Added ${event.source} position to track ${track.id} in tracking $uuid',
        );
        await _aggregate(uuid);
      }
    }
  }

  /// Calculate geometric mean of last position in all tracks
  Future _aggregate(String uuid) async {
    final tracking = TrackingModel.fromJson(
      repository.get(uuid).data,
    );
    if (tracking.status == TrackingStatus.tracking) {
      // Calculate geometric centre of all last position in all
      // tracks as the arithmetic mean of positions coordinates
      final next = _average(tracking);

      // Only add tracking history if position has changed
      if (tracking.position != next) {
        final history = List<PositionModel>.from(tracking.history ?? [])..add(next);
        final effort = asEffort(history);
        final distance = asDistance(
          history,
          distance: tracking.distance ?? 0,
        );
        final speed = asSpeed(distance, effort);
        final events = await _updateTrackingInformation({
          UUID: uuid,
          SPEED: speed,
          DISTANCE: distance,
          EFFORT: effort?.inMicroseconds,
          POSITION: next.toJson(),
          HISTORY: history.map((position) => position.toJson()).toList(),
        });
        logger.fine('Aggregated position for Tracking $uuid');
        if (events.isNotEmpty) {
          _addToStream(events, 'Updated tracking $uuid position');
        }
      }
    }
  }

  PositionModel _average(TrackingModel tracking) {
    final current = tracking.position;
    final sources = tracking.sources;

    // Calculate geometric centre of all source tracks as the arithmetic mean of the input coordinates
    if (sources.isEmpty) {
      return current;
    } else if (sources.length == 1) {
      return _findTrack(tracking, sources.first.uuid)?.positions?.last ?? current;
    }
    final tracks = tracking.tracks;
    // Aggregate
    var sum = tracks.fold<List<num>>(
      [0.0, 0.0, 0.0, DateTime.now().millisecondsSinceEpoch],
      (sum, track) => track.positions.isEmpty
          ? sum
          : [
              track.positions.last.lat + sum[0],
              track.positions.last.lon + sum[1],
              (track.positions.last.acc ?? 0.0) + sum[2],
              min(track.positions.last.timestamp.millisecondsSinceEpoch, sum[3]),
            ],
    );
    final count = tracks.length;
    return PositionModel.from(
      source: SourceType.tracking,
      lat: sum[0] / count,
      lon: sum[1] / count,
      acc: sum[2] / count,
      timestamp: DateTime.fromMillisecondsSinceEpoch(sum[3]),
    );
  }

  double asSpeed(double distance, Duration effort) =>
      distance.isNaN == false && effort.inMicroseconds > 0.0 ? distance / effort.inSeconds : 0.0;

  double asDistance(List<PositionModel> history, {double distance = 0, int tail = 2}) {
    distance ??= 0;
    var offset = max(0, history.length - tail - 1);
    var i = offset + 1;
    history?.skip(offset)?.forEach((p) {
      i++;
      distance += i < history.length
          ? eucledianDistance(
              history[i]?.lat ?? p.lat,
              history[i]?.lon ?? p.lon,
              p.lat,
              p.lon,
            )
          : 0.0;
    });
    return distance;
  }

  double eucledianDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final degLen = 110250;
    final x = lat1 - lat2;
    final y = (lon1 - lon2) * cos(lat2 * pi / 180.0);
    return degLen * sqrt(x * x + y * y);
  }

  Duration asEffort(List<PositionModel> history) => history?.isNotEmpty == true
      ? history.last.timestamp.difference(
          history.first.timestamp,
        )
      : Duration.zero;

  TrackModel _findTrackManagedByMe(String tracking, String source) =>
      // Only one attached track for each unique source in each manager instance
      _firstOrNull(
        _sources[source]
            // Find all tracking objects managed by me that tracks given source
            ?.where((managed) => managed == tracking)
            // Find source objects in other tracking objects
            ?.map(
              (other) => _findTrack(TrackingModel.fromJson(repository.get(other).data), source),
            )
            // Filter out all detached tracks
            ?.where((track) => track?.status == TrackStatus.attached),
      );

  TrackModel _findTrackManagedByOthers(String tracking, String source) =>
      // TODO: Select the track with most recent timestamp if multiple was found
      _firstOrNull(
        _sources[source]
            // Find all other tracking objects tracking given source
            ?.where((other) => other != tracking)
            // Find source objects in other tracking objects
            ?.map(
              (other) => _findTrack(TrackingModel.fromJson(repository.get(other).data), source),
            )
            // Filter out all detached tracks
            ?.where((track) => track?.status == TrackStatus.attached),
      );

  T _firstOrNull<T>(Iterable<T> list) => list?.isNotEmpty == true ? list.first : null;

  TrackModel _findTrack(TrackingModel tracking, String source) => tracking.tracks.firstWhere(
        (track) => track.source.uuid == source,
        orElse: () => null,
      );

  Future<Iterable<DomainEvent>> _ensureTrack(
    String uuid,
    String id,
    Map<String, dynamic> source, {
    Map<String, dynamic> positions,
    String status,
  }) async {
    final tracking = repository.get(uuid);
    final tracks = tracking.asEntityArray(TRACKS);
    final exists = tracks.contains(id);
    final command = exists
        ? _updateTrack(
            uuid,
            tracks.elementAt(id).data
              ..addAll({
                if (status != null) STATUS: status,
                if (positions != null) POSITIONS: positions,
              }))
        : _addTrack(uuid, {
            SOURCE: source,
            STATUS: status ??= ATTACHED,
            if (positions != null) POSITIONS: positions,
          });
    final events = await command;
    if (events.isNotEmpty) {
      _addToStream(
        events,
        '${exists ? 'Detached track from' : 'Attached track to'} ${source[TYPE]} ${source[UUID]}',
      );
    }
    return events;
  }

  FutureOr<Iterable<DomainEvent>> _addTrack(String uuid, Map<String, Object> track) async {
    try {
      return await repository.execute(AddTrackToTracking(uuid, track));
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to add track ${track[ID]} to Tracking $uuid: $e, stacktrace: $stackTrace',
      );
      return null;
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrack(String uuid, Map<String, dynamic> track) async {
    try {
      return await repository.execute(UpdateTrackingTrack(uuid, track));
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to update track ${track[ID]} in Tracking $uuid: $e, stacktrace: $stackTrace',
      );
      return null;
    }
  }

  String _deriveTrackingStatus(Map<String, dynamic> tracking, current) {
    final hasSource = (tracking.elementAt(SOURCES) as List).isNotEmpty;
    final next = ['created'].contains(current)
        ? (hasSource ? 'tracking' : 'created')
        : (hasSource ? 'tracking' : (['closed'].contains(current) ? current : 'paused'));
    return next;
  }

  Future _updateTrackingStatus(String uuid) async {
    try {
      final tracking = repository.get(uuid).data;
      final current = tracking.elementAt('status') ?? 'none';
      var next = _deriveTrackingStatus(tracking, current);
      if (current != next) {
        final events = await repository.execute(UpdateTrackingStatus({
          UUID: uuid,
          STATUS: next,
        }));
        if (events.isNotEmpty) {
          _addToStream(
            events,
            'Updated tracking $uuid status to $next',
          );
        }
      }
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to update tracking $uuid status: $e, stacktrace: $stackTrace',
      );
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrackingInformation(Map<String, Object> tracking) async {
    try {
      return await repository.execute(UpdateTrackingInformation(tracking));
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to update tracking ${tracking[UUID]}: $e, stacktrace: $stackTrace',
      );
      return null;
    }
  }

  /// Check if tracking exist in repository.
  ///
  /// Will ensure that repository has caught up with
  /// head of event stream before checking if uuid exists.
  Future<bool> _checkTracking(TrackingRepository repository, String uuid) async {
    if (!repository.contains(uuid)) {
      await repository.catchUp();
    }
    return repository.contains(uuid);
  }

  Future _ensureManaged(DomainEvent event) async {
    final uuid = repository.toAggregateUuid(event);
    if (event is TrackingCreated) {
      _addToStream([event], 'Analysing source mappings for tracking $uuid');
      return _addSources(repository, uuid);
    } else if (event is TrackingSourceAdded) {
      if (_addSource(event.sourceUuid, uuid)) {
        _addToStream([event], 'Looking for other active tracks attached to ${event.sourceType} ${event.sourceUuid}');
        final other = _findTrackManagedByOthers(uuid, event.sourceUuid);
        await _ensureTrack(
          uuid,
          event.id,
          event.entity,
          positions: other ?? {}[POSITIONS],
          status: ATTACHED,
        );
        await _aggregate(uuid);
        await _updateTrackingStatus(uuid);
      }
    }
  }

  Future _addSources(Repository repository, String uuid) async {
    if (await _checkTracking(repository, uuid)) {
      final tracking = repository.get(uuid);
      final tracks = tracking.asEntityArray(TRACKS);
      final sources = tracking.asEntityArray(SOURCES).toList();
      // Add sources currently unmapped by this service
      final added = sources
          .where(
            (source) => _addSource(source[UUID], uuid),
          )
          .toList();
      // Map sources to tracks
      final changed = tracks.isEmpty
          ? added.map((source) => {SOURCE: source})
          : added.where(
              (source) => tracks.toList().any((track) => track.elementAt('source/uuid') == source),
            );
      // Update tracks of sources that was not already mapped
      await Future.forEach(
        changed,
        (track) => _ensureTrack(
          uuid,
          track[ID],
          track[SOURCE],
          status: ATTACHED,
          positions: track[POSITIONS] ?? {},
        ),
      );
      await _updateTrackingStatus(uuid);
    } else {
      logger.severe(
        'Tracking $uuid not found in $repository after catch up',
      );
    }
  }

  /// Append tracking uuid to list of tracking uuids for given source
  ///
  /// Returns true if number of tracking uuids changed
  bool _addSource(String source, String tracking) {
    //
    // TODO: Identify circular reference (will produce reentrant code)

    final length = _sources[source]?.length ?? 0;
    return length < _sources.update(source, (uuids) => uuids..add(tracking), ifAbsent: () => {tracking}).length;
  }

  Future _ensureDetached(DomainEvent event) async {
    if (event is TrackingSourceAdded || event is TrackingSourceRemoved) {
      final uuid = repository.toAggregateUuid(event);
      final source = (event as TrackingSourceEvent).sourceUuid;
      final track = _findTrackManagedByMe(uuid, source);
      if (track != null) {
        _addToStream(
          [event],
          'Detaching track ${track.id} from source ${track.source.uuid}',
        );
        final events = await _ensureTrack(
          uuid,
          track.id,
          track.source.toJson(),
          status: DETACHED,
        );
        if (events.isNotEmpty) {
          await _updateTrackingStatus(uuid);
        }
      }
    }
  }

  void _addToStream(List<DomainEvent> events, String message) {
    events.forEach((event) {
      _streamController.add(event);
      logger.info('Processed ${event.type}: $message');
    });
  }

  /// Process [TrackingCreated] events fetched from persistent subscription
  /// and add [Tracking]
  void _onEvent(TrackingRepository repository, SourceEvent event) async {
    try {
      final domain = repository.toDomainEvent(event);
      if (domain is TrackingCreated) {
        final uuid = repository.toAggregateUuid(event);
        _managed.add(uuid);
        await _ensureManaged(domain);
        logger.fine('Added tracking $uuid for position processing');
      }
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to handle $event: $e with stacktrace: $stackTrace',
      );
    }
  }

  void _onDone(TrackingRepository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_disposed) {
      try {
        _subscription.reconnect(
          repository,
        );
      } on Exception catch (e, stackTrace) {
        logger.severe(
          'Failed to reconnect to repository: $e with stacktrace: $stackTrace',
        );
      }
    }
  }

  void _onError(TrackingRepository repository, dynamic error, StackTrace stackTrace) {
    logger.severe(
      'Competing subscription failed with: $error. stactrace: $stackTrace',
    );
    if (!_disposed) {
      try {
        _subscription.reconnect(
          repository,
        );
      } on Exception catch (e, stackTrace) {
        logger.severe(
          'Failed to reconnect to repository: $e with stacktrace: $stackTrace',
        );
      }
    }
  }
}
