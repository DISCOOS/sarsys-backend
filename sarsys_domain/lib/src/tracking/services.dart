import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';
import 'package:sarsys_domain/src/core/models/models.dart';
import 'package:sarsys_domain/src/tracking/tracking_utils.dart';

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
/// the track with the most recent timestamp is chosen
/// following a 'last writer wins' strategy.
///
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
    this.repo, {
    @required this.devices,
    this.consume = 1,
    this.dataPath = '.data',
    this.snapshot = true,
    this.maxBackoffTime = const Duration(seconds: 10),
  });
  final int consume;
  final bool snapshot;
  final String dataPath;
  final Duration maxBackoffTime;
  final DeviceRepository devices;
  final Set<String> _managed = {};
  final TrackingRepository repo;
  final Map<String, Set<String>> _sources = {};
  final Logger logger = Logger('$TrackingService');

  EventStoreSubscriptionController<TrackingRepository> _subscription;

  /// Get [Tracking] instances managed by this [TrackingService]
  Set<String> get managed => UnmodifiableSetView(_managed);

  /// Get mapping between [Tracking] and sources
  Map<String, Set<String>> get sources => Map.unmodifiable(_sources);

  /// This stream will only contain [DomainEvent] pushed to remote stream
  final _streamController = StreamController<DomainEvent>.broadcast();

  /// Persist [Tracking] managed by this service.
  /// This solves the restart problem, which will not
  /// fetch already consumed TrackingCreated events.
  /// IMPORTANT: This solutions REQUIRES that same
  /// AQUEDUCT instance is restarted in stateful manner,
  /// f.ex. using a StatefulSet in Kubernetes (files are
  /// kept between restarts of same logical instance)
  ///
  Box<String> _box;

  /// Get remote [Event] stream.
  Stream<DomainEvent> asStream() {
    return _streamController.stream;
  }

  /// When true, this manager should not be used any more
  bool get disposed => _disposed;
  bool _disposed = false;

  /// Build competitive [Tracking] service
  FutureOr build({bool init = false}) async {
    // Initialize from snapshot?
    if (snapshot) {
      await _load(init);
    }

    // Register events of interest
    repo.store.bus.register<TrackingSourceAdded>(this);
    repo.store.bus.register<TrackingSourceRemoved>(this);
    repo.store.bus.register<DevicePositionChanged>(this);
    repo.store.bus.register<TrackingPositionChanged>(this);

    // Start competition with other tracking service instances
    await _subscription?.cancel();
    _subscription = EventStoreSubscriptionController<TrackingRepository>(
      logger: logger,
      onDone: _onDone,
      onEvent: _onEvent,
      onError: _onError,
      maxBackoffTime: maxBackoffTime,
    );
    final complete = _subscription.compete(
      repo,
      stream: STREAM,
      group: EventStore.toCanonical([
        repo.store.prefix,
        '$runtimeType',
      ]),
      consume: consume,
      number: EventNumber.first,
      strategy: ConsumerStrategy.RoundRobin,
    );
    logger.info('Built with consumption count $consume from stream $STREAM');
    return complete;
  }

  Future _load(bool init) async {
    _box = await Hive.openBox('$runtimeType');
    if (init) {
      await _box.clear();
      _box.values;
    } else {
      final futures = List<String>.from(_box.values ?? <String>[])
          .map(
            (json) => _fromJson(json),
          )
          .map(
            (event) => _replayEvent(event),
          );
      // Will not on each command
      // before executing the next
      await Future.wait(futures);
    }
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
  Future dispose() async {
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
  void handle(Object source, DomainEvent message) async {
    try {
      if (message.remote) {
        switch (message.runtimeType) {
          case TrackingCreated:
            await _onTrackingCreated(message as TrackingCreated);
            break;
          case TrackingSourceAdded:
            await _onTrackingSourceAdded(message as TrackingSourceAdded);
            break;
          case TrackingSourceRemoved:
            await _onTrackingSourceRemoved(message as TrackingSourceRemoved);
            break;
          case DevicePositionChanged:
            await _onDevicePositionChanged(message as DevicePositionChanged);
            break;
          case TrackingPositionChanged:
            await _onSourcePositionChanged(message as TrackingPositionChanged);
            break;
          case TrackingDeleted:
            await _onTrackingDeleted(message as TrackingDeleted);
            break;
        }
      }
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to handle $message: $error with stacktrace: $stackTrace',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  Future _replayEvent(DomainEvent event) async {
    if (event is TrackingCreated) {
      return _onTrackingCreated(event, replay: true);
    } else if (event is TrackingSourceAdded) {
      return _onTrackingSourceAdded(event);
    } else if (event is TrackingDeleted) {
      return _onTrackingDeleted(event, replay: true);
    }
  }

  /// Build map of all source uuids to its tracking uuids
  void _onTrackingCreated(TrackingCreated event, {bool replay = false}) async {
    final tuuid = repo.toAggregateUuid(event);
    if (!_managed.contains(tuuid)) {
      // Ensure that tracking is persisted to this instance?
      if (!replay && snapshot) {
        await _box.put(tuuid, _toJson(event));
      }
      _managed.add(tuuid);
      logger.info('Added tracking $tuuid for position processing');
    }
    // Only attempt to add sources from tracking that exists during replay (stale
    if (!replay || replay && repo.contains(tuuid)) {
      _addToStream([event], 'Analysing source mappings for tracking $tuuid', replay: replay);
      return _addSources(tuuid);
    } else if (replay) {
      await _removeTracking(tuuid);
      logger.info('Deleted stale tracking $tuuid');
    }
  }

  Future _removeTracking(String tuuid) async {
    _managed.remove(tuuid);
    _removeSources(tuuid);
    if (snapshot) {
      // Stale tracking object, remove it from hive
      await _box.delete(tuuid);
    }
  }

  /// Stop management and remove from service
  void _onTrackingDeleted(TrackingDeleted event, {bool replay = false}) async {
    final tuuid = repo.toAggregateUuid(event);
    if (_managed.contains(tuuid) && !replay) {
      await _removeTracking(tuuid);
      _addToStream([event], 'Removed tracking $tuuid from service', replay: replay);
    }
  }

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
    final tuuid = repo.toAggregateUuid(event);
    try {
      if (managed.contains(tuuid)) {
        final data = repo.get(tuuid).data;
        final suuid = event.toSourceUuid(data);
        if (_addSource(tuuid, suuid)) {
          _addToStream(
            [event],
            'Looking for other active tracks attached to ${event.toSourceType(data)} $suuid',
          );
          final other = _findTrackManagedByOthers(tuuid, suuid);
          final trx = repo.getTransaction(tuuid);
          await _ensureTrack(
            tuuid,
            event.toId(data),
            event.toEntity(data),
            positions:
                other == null ? <Map<String, dynamic>>[] : other.toJson().listAt<Map<String, dynamic>>(POSITIONS),
            status: ATTACHED,
          );
          await _updateTrackingStatus(tuuid);
          await _aggregate(tuuid);
          await trx.push();
        }
      } else {
        await _ensureDetached(event);
      }
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to push changes in Tracking $tuuid,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
    } finally {
      if (repo.inTransaction(tuuid)) {
        repo.rollback(tuuid);
      }
    }
  }

  /// If [TrackingSourceRemoved] was from a [Tracking] instance
  /// managed by this [TrackingService], the state of the
  /// associated track is changed to 'detached'
  void _onTrackingSourceRemoved(TrackingSourceRemoved event) async {
    return await _ensureDetached(event);
  }

  /// If [PositionEvent.source] belongs to a track managed by this
  /// [TrackingService] new position is added to attached track
  /// and a new [Tracking.point] is calculated based on current
  /// aggregation parameters.
  void _onDevicePositionChanged(DevicePositionChanged event) async {
    // Only process events with remote origin
    if (event.remote) {
      final duuid = repo.toAggregateUuid(event);
      if (_sources.containsKey(duuid) && devices.contains(duuid)) {
        final device = devices.get(duuid);
        if (device.elementAt<bool>('trackable') ?? false) {
          final tuuids = _sources[duuid].where((tuuid) => managed.contains(tuuid));
          for (var tuuid in tuuids) {
            await _addPosition(tuuid, event);
          }
        } else {
          _addToStream(
            [event],
            'Device $duuid is not trackable',
          );
        }
      }
    }
  }

  /// If [PositionEvent.source] belongs to a track managed by this
  /// [TrackingService] new position is added to attached track
  /// and a new [Tracking.point] is calculated based on current
  /// aggregation parameters.
  void _onSourcePositionChanged(PositionEvent event) async {
    final suuid = repo.toAggregateUuid(event);
    if (_sources.containsKey(suuid)) {
      final tuuids = _sources[suuid].where((tuuid) => managed.contains(tuuid));
      for (var tuuid in tuuids) {
        await _addPosition(tuuid, event);
      }
    }
  }

  /// Add position to track for given source
  Future<Iterable<DomainEvent>> _addPosition(String tuuid, PositionEvent event) async {
    try {
      final track = _findTrack(
        TrackingModel.fromJson(repo.get(tuuid).data),
        repo.toAggregateUuid(event),
      );
      if (track != null) {
        final trx = repo.getTransaction(
          tuuid,
        );
        final position = event.position;
        final positions = track.positions ?? [];
        positions.add(position);

        final events = await _updateTrack(
          tuuid,
          track.cloneWith(positions: positions).toJson(),
        );
        if (events?.isNotEmpty == true) {
          _addToStream(
            [event, ...events],
            'Added ${enumName(position.source)} position to track ${track.id} in tracking $tuuid',
          );
          await _aggregate(tuuid);
          return await trx.push();
        }
      }
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to push changes in Tracking $tuuid,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
    } finally {
      if (repo.inTransaction(tuuid)) {
        repo.rollback(tuuid);
      }
    }
    return <DomainEvent>[];
  }

  /// Calculate geometric mean of last position in all tracks
  Future _aggregate(String uuid) async {
    final tracking = TrackingModel.fromJson(
      repo.get(uuid).data,
    );

    if (tracking.status == TrackingStatus.tracking) {
      // Calculate geometric centre of all last position in all
      // tracks as the arithmetic mean of positions coordinates
      final next = TrackingUtils.average(tracking);

      // Only add tracking history if position has changed
      if (tracking.position != next && next.isNotEmpty) {
        final history = List<PositionModel>.from(tracking.history ?? [])..add(next);
        final effort = TrackingUtils.effort(history);
        final distance = TrackingUtils.distance(
          history,
          distance: tracking.distance ?? 0,
        );
        final speed = TrackingUtils.speed(distance, effort);
        final events = await _updateTrackingPosition({
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
    return Future.value();
  }

  TrackModel _findTrackManagedByMe(String tuuid, String suuid) =>
      // Only one attached track for each unique source in each manager instance
      _firstOrNull(
        _sources[suuid]
            // Find all tracking objects managed by me that tracks given source
            ?.where((managed) => managed == tuuid)
            // Find source objects in other tracking objects
            ?.map(
              (other) => _findTrack(TrackingModel.fromJson(repo.get(other).data), suuid),
            )
            // Filter out all detached tracks
            ?.where((track) => track?.status == TrackStatus.attached),
      );

  TrackModel _findTrackManagedByOthers(String tuuid, String suuid) =>
      // TODO: Select the track with most recent timestamp if multiple was found
      _firstOrNull(
        _sources[suuid]
            // Find all other tracking objects tracking given source
            ?.where((other) => other != tuuid)
            // Find source objects in other tracking objects
            ?.map(
              (other) => _findTrack(TrackingModel.fromJson(repo.get(other).data), suuid),
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
    List<Map<String, dynamic>> positions,
    String status,
  }) async {
    assert(source != null, "'source' can not be null");
    final tracking = repo.get(uuid);
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
      return await repo.execute(AddTrackToTracking(uuid, track));
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to add track to Tracking $uuid for '
        '${track.mapAt(SOURCE).elementAt(TYPE)} '
        '${track.mapAt(SOURCE).elementAt(UUID)},\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
      return <DomainEvent>[];
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrack(String uuid, Map<String, dynamic> track) async {
    try {
      return await repo.execute(UpdateTrackingTrack(uuid, track));
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to update track ${track[UUID]} in Tracking $uuid,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
      return <DomainEvent>[];
    }
  }

  String _inferTrackingStatus(Map<String, dynamic> tracking, String current) {
    final hasSource = (tracking.elementAt(SOURCES) as List).isNotEmpty;
    final next = ['ready'].contains(current)
        ? (hasSource ? 'tracking' : 'ready')
        : (hasSource
            ? (['paused'].contains(current) ? current : 'tracking')
            : (['closed'].contains(current) ? current : 'ready'));
    return next;
  }

  Future _updateTrackingStatus(String uuid) async {
    try {
      final tracking = repo.get(uuid).data;
      final current = tracking.elementAt<String>('status') ?? 'none';
      var next = _inferTrackingStatus(tracking, current);
      if (current != next) {
        final events = await repo.execute(UpdateTrackingStatus({
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
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to update tracking $uuid status,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrackingPosition(Map<String, Object> tracking) async {
    try {
      return await repo.execute(UpdateTrackingPosition(tracking));
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to update tracking ${tracking[UUID]},\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
      return <DomainEvent>[];
    }
  }

  /// Check if tracking exist in repository.
  ///
  /// Will ensure that repository has caught up with
  /// head of event stream before checking if uuid exists.
  Future<bool> _checkTracking(String uuid) async {
    if (!repo.contains(uuid)) {
      await repo.catchup(
        master: true,
        uuids: [uuid],
      );
    }
    return repo.contains(uuid);
  }

  Future _addSources(String tuuid) async {
    try {
      if (await _checkTracking(tuuid)) {
        final tracking = repo.get(tuuid);
        final tracks = tracking.asEntityArray(TRACKS);
        final sources = tracking.asEntityArray(SOURCES).toList();
        // Add sources currently unmapped by this service
        final added = sources
            .where(
              (source) => _addSource(tuuid, source[UUID] as String),
            )
            .toList();
        // Map sources to tracks
        final changed = tracks.isEmpty
            ? added.map((source) => {SOURCE: source})
            : added.where(
                (source) => tracks.toList().any((track) => track.elementAt('source/uuid') == source),
              );
        // Update tracks of sources that was not already mapped
        for (var track in changed) {
          await _ensureTrack(
            tuuid,
            track[ID] as String,
            Map.from(track[SOURCE] as Map),
            status: ATTACHED,
            positions: List.from(track[POSITIONS] as List ?? []),
          );
        }
        await _updateTrackingStatus(tuuid);
      } else {
        throw AggregateNotFound(
          'Tracking $tuuid not found in $repo after catch up',
        );
      }
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to push changes in Tracking $tuuid,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  /// Append tracking uuid to list of tracking uuids for given source
  ///
  /// Returns true if number of tracking uuids changed
  bool _addSource(String tuuid, String suuid) {
    //
    // TODO: Identify circular reference (will produce reentrant code)

    final length = _sources[suuid]?.length ?? 0;
    return length < _sources.update(suuid, (uuids) => uuids..add(tuuid), ifAbsent: () => {tuuid}).length;
  }

  /// Remove tracking uuid from list of tracking uuids for given source
  ///
  /// Returns true if number of tracking uuids changed
  bool _removeSources(String tuuid) {
    final changed = _sources.entries.where((entry) => entry.value.contains(tuuid)).map(
          (entry) => MapEntry(entry.key, entry.value..remove(tuuid)),
        );
    _sources.addEntries(changed);
    final empty = _sources.entries.where((entry) => entry.value.isEmpty).toList()
      ..forEach(
        (entry) => _sources.remove(entry.key),
      );
    return changed.isNotEmpty || empty.isNotEmpty;
  }

  Future _ensureDetached(TrackingSourceEvent event) async {
    final tuuid = repo.toAggregateUuid(event);
    final data = repo.get(tuuid).data;
    final suuid = event.toSourceUuid(data);
    final track = _findTrackManagedByMe(tuuid, suuid);
    if (track != null) {
      _addToStream(
        [event],
        'Detaching track ${track.id} from source ${track.source.uuid}',
      );
      try {
        final trx = repo.getTransaction(tuuid);
        final events = await _ensureTrack(
          tuuid,
          track.id,
          track.source.toJson(),
          status: DETACHED,
        );
        if (events.isNotEmpty) {
          await _updateTrackingStatus(tuuid);
        }
        await trx.push();
      } finally {
        if (repo.inTransaction(tuuid)) {
          repo.rollback(tuuid);
        }
      }
    }
  }

  void _addToStream(Iterable<DomainEvent> events, String message, {bool replay = false}) {
    events.forEach((event) {
      _streamController.add(event);
      logger.info('Processed ${event.type}${replay ? '[replay]' : ''}: $message');
    });
  }

  /// Process [TrackingCreated] events fetched from persistent subscription
  /// and add [Tracking]
  void _onEvent(TrackingRepository repository, SourceEvent event) async {
    try {
      final domain = repository.toDomainEvent(event);
      if (domain is TrackingCreated) {
        await _onTrackingCreated(domain);
      } else if (domain is TrackingDeleted) {
        await _onTrackingDeleted(domain);
      }
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to handle $event,\n'
        'error: $error,\n'
        'stackTrace: ${Trace.format(stackTrace)}',
        error,
        Trace.from(stackTrace),
      );
    }
  }

  void _onDone(TrackingRepository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_disposed) {
      try {
        _subscription.reconnect();
      } catch (error, stackTrace) {
        logger.severe(
          'Failed to reconnect to repository,\n'
          'error: $error,\n'
          'stackTrace: ${Trace.format(stackTrace)}',
          error,
          Trace.from(stackTrace),
        );
      }
    }
  }

  void _onError(TrackingRepository repository, dynamic error, StackTrace stackTrace) {
    logger.network(
      'Competing subscription failed $error,\n'
      'stackTrace: ${Trace.format(stackTrace)}',
      error,
      stackTrace,
    );
    if (!_disposed) {
      try {
        _subscription.reconnect();
      } catch (e, stackTrace) {
        logger.severe(
          'Failed to reconnect to repository,\n'
          'error: $e,\n'
          'stackTrace: ${Trace.format(stackTrace)}',
          e,
          Trace.from(stackTrace),
        );
      }
    }
  }

  String _toJson(TrackingCreated event) => jsonEncode({
        'uuid': event.uuid,
        'data': event.data,
        'created': event.created.toIso8601String(),
      });

  TrackingCreated _fromJson(String data) {
    final json = jsonDecode(data);
    return TrackingCreated(
      Message(
        local: true,
        uuid: json['uuid'] as String,
        data: Map.from(json['data'] as Map),
        created: DateTime.parse(json['created'] as String),
      ),
    );
  }
}
