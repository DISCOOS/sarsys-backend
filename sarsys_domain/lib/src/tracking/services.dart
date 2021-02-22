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
    this.snapshot = true,
    this.maxPaused = 500,
    this.dataPath = '.data',
    this.maxBackoffTime = const Duration(seconds: 10),
  }) {
    _context = Context(Logger('$TrackingService'));
  }
  final int consume;
  final bool snapshot;
  final int maxPaused;
  final String dataPath;
  final Duration maxBackoffTime;
  final DeviceRepository devices;
  final Set<String> _managed = {};
  final TrackingRepository repo;
  final Map<String, Set<String>> _sources = {};

  Context _context;

  /// Get last [Tracking] event processed
  DomainEvent get lastTrackingEvent => _lastTrackingEvent;
  DomainEvent _lastTrackingEvent;

  /// Get [Duration] metrics for [Tracking] event processing
  DurationMetric get trackingMetrics => _metrics['tracking'];

  /// Get last [PositionEvent] processed
  PositionEvent get lastPositionEvent => _lastPositionEvent;
  PositionEvent _lastPositionEvent;

  /// Get [Duration] metrics for [PositionEvent] event processing
  DurationMetric get positionMetrics => _metrics['position'];

  /// Check if [Tracking] with given [uuid] is managed by this service
  bool isManagerOf(String uuid) => _managed.contains(uuid);

  /// Get [Tracking] instances managed by this [TrackingService]
  Set<String> get managed => UnmodifiableSetView(_managed);

  /// Get mapping between [Tracking] and sources
  Map<String, Set<String>> get sources => Map.unmodifiable(_sources);

  /// This stream will only contain [DomainEvent] pushed to remote stream
  final _streamController = StreamController<DomainEvent>.broadcast();

  EventStoreSubscriptionController<TrackingRepository> _subscription;

  /// Persist [Tracking] managed by this service.
  /// This solves the restart problem, which will not
  /// fetch already consumed TrackingCreated events.
  /// IMPORTANT: This solutions REQUIRES that same
  /// AQUEDUCT instance is restarted in stateful manner,
  /// f.ex. using a StatefulSet in Kubernetes (files are
  /// kept between restarts of same logical instance)
  ///
  LazyBox<String> _box;

  /// Get remote [Event] stream.
  Stream<DomainEvent> asStream() {
    return _streamController.stream;
  }

  /// Check if service is competing
  bool get isStarted => _isCompeting;
  bool _isCompeting = false;

  FutureOr<bool> start() async {
    if (!_isCompeting) {
      // Start competition with other tracking service instances
      _subscription = EventStoreSubscriptionController<TrackingRepository>(
        onDone: _onDone,
        onEvent: _onEvent,
        onError: _onError,
        maxBackoffTime: maxBackoffTime,
      );
      _subscription.compete(
        repo,
        stream: STREAM,
        consume: consume,
        group: EventStore.toCanonical([
          repo.store.prefix,
          '$runtimeType',
        ]),
        number: EventNumber.first,
        strategy: ConsumerStrategy.RoundRobin,
      );
      _isCompeting = true;
    } else if (isPaused) {
      _subscription.resume();
    }

    return _isCompeting;
  }

  FutureOr<bool> stop() async {
    if (_isCompeting) {
      _subscription?.pause();
      return _subscription.isPaused;
    }
    return false;
  }

  /// When true, this manager should not be used any more
  bool get isDisposed => _disposed;
  bool _disposed = false;

  /// Build competitive [Tracking] service.
  /// Returns true if service started to compete
  FutureOr build({
    Context context,
    bool init = false,
    bool start = true,
  }) async {
    // Initialize from snapshot?
    if (snapshot) {
      await _load(init);
    }

    // Register events of interest
    repo.store.bus.register<TrackingSourceAdded>(this);
    repo.store.bus.register<TrackingSourceRemoved>(this);
    repo.store.bus.register<DevicePositionChanged>(this);
    repo.store.bus.register<TrackingPositionChanged>(this);

    if (start) {
      await this.start();
    }

    _context.info(
      'Built with consumption count $consume from stream $STREAM',
      category: 'TrackingService.build',
    );

    return _isCompeting;
  }

  Future _load(bool init) async {
    _box = await await Hive.openLazyBox<String>('$runtimeType');
    if (init) {
      await _box.clear();
    } else {
      final values = <TrackingCreated>[];
      for (var tuuid in _box.keys) {
        values.add(_fromJson(await _box.get(
          tuuid,
        )));
      }
      final futures = values.map(
        (event) => _replayEvent(event),
      );
      // Will not on each command
      // before executing the next
      await Future.wait(futures);
    }
  }

  bool get isPaused => _subscription?.isPaused == true;

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

  final List<DomainEvent> _paused = [];

  @override
  void handle(Object source, DomainEvent event) async {
    final tic = DateTime.now();
    if (isPaused) {
      _paused.add(event);
      if (_paused.length > maxPaused) {
        _paused.remove(_paused.first);
      }
      return;
    }
    if (isStarted) {
      try {
        if (event.remote) {
          switch (event.runtimeType) {
            case TrackingCreated:
              await _onTrackingCreated(event as TrackingCreated);
              break;
            case TrackingSourceAdded:
              await _onTrackingSourceAdded(event as TrackingSourceAdded);
              break;
            case TrackingSourceRemoved:
              await _onTrackingSourceRemoved(event as TrackingSourceRemoved);
              break;
            case DevicePositionChanged:
              await _onDevicePositionChanged(event as DevicePositionChanged);
              break;
            case TrackingPositionChanged:
              await _onSourcePositionChanged(event as TrackingPositionChanged);
              break;
            case TrackingDeleted:
              await _onTrackingDeleted(event as TrackingDeleted);
              break;
          }
          // Calculate duration statistics
          _onProcessed(tic, event);
        }
      } catch (error, stackTrace) {
        _context.error(
          'Failed to handle ${event.type} ${event.uuid} with: $error',
          category: 'TrackingService.handle',
          error: error,
          data: {
            'source': source?.toString(),
            'event.type': '${event.type}',
            'event.uuid': '${event.uuid}',
            'event.number': '${event.number}',
            'event.remote': '${event.remote}',
            'event.created': '${event.created.toIso8601String()}',
            'event.data': '${jsonEncode(event.data)}',
            'event.repository.ready': '${repo.isReady}',
            'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
          },
          stackTrace: Trace.from(stackTrace),
        );
      }
    }
  }

  void _onProcessed(DateTime tic, DomainEvent event) {
    if (event is PositionEvent) {
      _lastPositionEvent = event;
      _metrics['position'] = _metrics['position'].next(tic);
    } else {
      _lastTrackingEvent = event;
      _metrics['tracking'] = _metrics['tracking'].next(tic);
    }
  }

  final _metrics = {
    'tracking': DurationMetric.zero,
    'position': DurationMetric.zero,
  };

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
  Future _onTrackingCreated(TrackingCreated event, {bool replay = false}) async {
    return _addTracking(event, replay);
  }

  Future<bool> addTracking(String uuid) async {
    if (_managed.contains(uuid)) {
      return true;
    }
    final tracking = await _tryGet(uuid);
    if (tracking != null) {
      return _addTracking(
        tracking.createdBy as TrackingCreated,
        false,
      );
    }
    return false;
  }

  FutureOr<Tracking> _tryGet(String uuid) async {
    if (!repo.exists(uuid)) {
      await repo.catchup(
        master: true,
        uuids: [uuid],
        context: _context,
      );
    }
    // Only get aggregate if is exists in storage!
    return repo.store.contains(uuid) ? repo.get(uuid, context: _context) : null;
  }

  Future<bool> _addTracking(TrackingCreated event, bool replay) async {
    final tuuid = repo.toAggregateUuid(event);
    var exists = _managed.contains(tuuid);
    if (!exists) {
      // Ensure that tracking is persisted to this instance?
      if (!replay && snapshot) {
        await _box.put(tuuid, _toJson(event));
      }
      exists = _managed.add(tuuid);
      _context.info(
        'Added tracking $tuuid for position processing',
        category: 'TrackingService._addTracking',
      );
    }
    // Only attempt to add sources from tracking that exists during replay (stale
    if (!replay || replay && repo.contains(tuuid)) {
      _addToStream([event], 'Analysing source mappings for tracking $tuuid', replay: replay);
      await _addSources(tuuid);
    } else if (replay) {
      await removeTracking(tuuid);
      _context.info(
        'Deleted stale tracking $tuuid',
        category: 'TrackingService._addTracking',
      );
    }
    return exists;
  }

  Future<bool> removeTracking(String tuuid) async {
    final wasManaged = _managed.remove(tuuid);
    final removedSources = _removeSources(tuuid);
    if (snapshot) {
      // Stale tracking object, remove it from hive
      await _box.delete(tuuid);
    }
    return wasManaged || removedSources;
  }

  /// Stop management and remove from service
  Future _onTrackingDeleted(TrackingDeleted event, {bool replay = false}) async {
    final tuuid = repo.toAggregateUuid(event);
    if (_managed.contains(tuuid) && !replay) {
      await removeTracking(tuuid);
      _addToStream([event], 'Removed tracking $tuuid from service', replay: replay);
    }
    return Future.value();
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
  Future _onTrackingSourceAdded(TrackingSourceAdded event) async {
    Transaction trx;
    final tuuid = repo.toAggregateUuid(event);
    try {
      if (managed.contains(tuuid)) {
        final data = repo.get(tuuid, context: _context).data;
        final suuid = event.toSourceUuid(data);
        if (_addSource(tuuid, suuid)) {
          _addToStream(
            [event],
            'Looking for other active tracks attached to ${event.toSourceType(data)} $suuid',
          );
          final other = _findTrackManagedByOthers(tuuid, suuid);
          trx = repo.getTransaction(tuuid);
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
      _context.error(
        'Failed to push changes in Tracking $tuuid for event ${event.type} ${event.uuid} with: $error',
        category: 'TrackingService._onTrackingSourceAdded',
        error: error,
        data: {
          'event.type': '${event.type}',
          'event.uuid': '${event.uuid}',
          'event.number': '${event.number}',
          'event.remote': '${event.remote}',
          'event.created': '${event.created.toIso8601String()}',
          'event.data': '${jsonEncode(event.data)}',
          if (trx != null) ...{
            'trx.changes': '${trx.changes.length}',
            if (trx.changes.isNotEmpty) 'trx.changes.last': '${trx.changes.last.type}@${trx.changes.last.number}',
            if (trx.changes.isNotEmpty) 'trx.changes.first': '${trx.changes.first.type}@${trx.changes.first.number}',
            'trx.concurrent': '${trx.concurrent.length}',
            'trx.conflicts': '${trx.conflicting.length}',
            'trx.results': '${trx.result?.length}',
            'trx.remaining': '${trx.remaining.length}',
            'trx.startedAt': '${Trace.from(trx.startedAt).frames.first}',
            'trx.startedBy': '${trx.startedBy}',
            if (trx.hasFailed) 'trx.error': '${trx.error}',
          } else
            'trx': 'none',
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
      );
    } finally {
      if (repo.inTransaction(tuuid)) {
        repo.rollback(tuuid);
      }
    }
    return Future.value();
  }

  /// If [TrackingSourceRemoved] was from a [Tracking] instance
  /// managed by this [TrackingService], the state of the
  /// associated track is changed to 'detached'
  Future _onTrackingSourceRemoved(TrackingSourceRemoved event) {
    return _ensureDetached(event);
  }

  /// If [PositionEvent.source] belongs to a track managed by this
  /// [TrackingService] new position is added to attached track
  /// and a new [Tracking.point] is calculated based on current
  /// aggregation parameters.
  Future _onDevicePositionChanged(DevicePositionChanged event) async {
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
    return Future.value();
  }

  /// If [PositionEvent.source] belongs to a track managed by this
  /// [TrackingService] new position is added to attached track
  /// and a new [Tracking.point] is calculated based on current
  /// aggregation parameters.
  Future _onSourcePositionChanged(PositionEvent event) async {
    final suuid = repo.toAggregateUuid(event);
    if (_sources.containsKey(suuid)) {
      final tuuids = _sources[suuid].where((tuuid) => managed.contains(tuuid));
      for (var tuuid in tuuids) {
        await _addPosition(tuuid, event);
      }
    }
    return Future.value();
  }

  /// Add position to track for given source
  Future<Iterable<DomainEvent>> _addPosition(String tuuid, PositionEvent event) async {
    Transaction trx;
    try {
      final track = _findTrack(
        TrackingModel.fromJson(repo.get(tuuid, context: _context).data),
        repo.toAggregateUuid(event),
      );
      if (track != null) {
        trx = repo.getTransaction(
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
      _context.error(
        'Failed to push changes in Tracking $tuuid for event ${event.type} ${event.uuid} with: $error',
        category: 'TrackingService._addPosition',
        error: error,
        data: {
          'event.type': '${event.type}',
          'event.uuid': '${event.uuid}',
          'event.number': '${event.number}',
          'event.remote': '${event.remote}',
          'event.created': '${event.created.toIso8601String()}',
          'event.data': '${jsonEncode(event.data)}',
          if (trx != null) ...{
            'trx.changes': '${trx.changes.length}',
            if (trx.changes.isNotEmpty) 'trx.changes.last': '${trx.changes.last.type}@${trx.changes.last.number}',
            if (trx.changes.isNotEmpty) 'trx.changes.first': '${trx.changes.first.type}@${trx.changes.first.number}',
            'trx.concurrent': '${trx.concurrent.length}',
            'trx.conflicts': '${trx.conflicting.length}',
            'trx.results': '${trx.result?.length}',
            'trx.remaining': '${trx.remaining.length}',
            'trx.startedAt': '${Trace.from(trx.startedAt).frames.first}',
            'trx.startedBy': '${trx.startedBy}',
            if (trx.hasFailed) 'trx.error': '${trx.error}',
          } else
            'trx': 'none',
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
      );
    } finally {
      if (repo.inTransaction(tuuid)) {
        repo.rollback(tuuid);
      }
    }
    return <DomainEvent>[];
  }

  /// Calculate geometric mean of last position in all tracks
  FutureOr<void> _aggregate(String uuid) async {
    final tracking = TrackingModel.fromJson(
      repo.get(uuid, context: _context).data,
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
        _context.debug(
          'Aggregated position for Tracking $uuid',
          category: 'TrackingService._addTracking',
        );
        if (events.isNotEmpty) {
          _addToStream(events, 'Updated tracking $uuid position');
        }
      }
    }
  }

  TrackModel _findTrackManagedByMe(String tuuid, String suuid) =>
      // Only one attached track for each unique source in each manager instance
      _firstOrNull(
        _sources[suuid]
            // Find all tracking objects managed by me that tracks given source
            ?.where((managed) => managed == tuuid)
            // Find source objects in other tracking objects
            ?.map(
              (other) => _findTrack(
                  TrackingModel.fromJson(
                    repo.get(other, context: _context).data,
                  ),
                  suuid),
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
              (other) => _findTrack(
                  TrackingModel.fromJson(
                    repo.get(other, context: _context).data,
                  ),
                  suuid),
            )
            // Filter out all detached tracks
            ?.where((track) => track?.status == TrackStatus.attached),
      );

  T _firstOrNull<T>(Iterable<T> list) => list?.isNotEmpty == true ? list.first : null;

  TrackModel _findTrack(TrackingModel tracking, String source) => tracking.tracks?.firstWhere(
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
    final tracking = repo.get(uuid, context: _context);
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
      return await repo.execute(
        AddTrackToTracking(uuid, track),
        context: _context,
      );
    } catch (error, stackTrace) {
      _context.error(
        'Failed to push changes in Tracking $uuid for track '
        '${track.mapAt(SOURCE).elementAt(TYPE)} ${track.mapAt(SOURCE).elementAt(UUID)} with: $error',
        category: 'TrackingService._addTrack',
        error: error,
        data: {
          'tracking.uuid': uuid,
          'tracking.track.uuid': '${track[UUID]}',
          'tracking.track.json': '${jsonEncode(track)}',
          'tracking.source.type': '${track.mapAt(SOURCE).elementAt(TYPE)}',
          'tracking.source.uuid': '${track.mapAt(SOURCE).elementAt(UUID)}',
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
      );
      return <DomainEvent>[];
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrack(String uuid, Map<String, dynamic> track) async {
    try {
      return await repo.execute(
        UpdateTrackingTrack(uuid, track),
        context: _context,
      );
    } catch (error, stackTrace) {
      _context.error(
        'Failed to update track ${track[UUID]} in Tracking $uuid'
        '${track.mapAt(SOURCE).elementAt(TYPE)} ${track.mapAt(SOURCE).elementAt(UUID)} with: $error',
        category: 'TrackingService._updateTrack',
        error: error,
        data: {
          'tracking.uuid': uuid,
          'tracking.track.uuid': '${track[UUID]}',
          'tracking.track.json': '${jsonEncode(track)}',
          'tracking.source.type': '${track.mapAt(SOURCE).elementAt(TYPE)}',
          'tracking.source.uuid': '${track.mapAt(SOURCE).elementAt(UUID)}',
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
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
    Map<String, dynamic> tracking;
    try {
      tracking = repo.get(uuid, context: _context).data;
      final current = tracking.elementAt<String>('status') ?? 'none';
      var next = _inferTrackingStatus(tracking, current);
      if (current != next) {
        final events = await repo.execute(
          UpdateTrackingStatus({
            UUID: uuid,
            STATUS: next,
          }),
          context: _context,
        );
        if (events.isNotEmpty) {
          _addToStream(
            events,
            'Updated tracking $uuid status to $next',
          );
        }
      }
    } catch (error, stackTrace) {
      _context.error(
        'Failed to update tracking $uuid status with: $error',
        category: 'TrackingService._updateTrackingStatus',
        error: error,
        data: {
          'tracking.uuid': uuid,
          'tracking.status': uuid,
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
      );
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrackingPosition(Map<String, Object> tracking) async {
    try {
      return await repo.execute(
        UpdateTrackingPosition(tracking),
        context: _context,
      );
    } catch (error, stackTrace) {
      final uuid = tracking.elementAt<String>(UUID);
      _context.error(
        'Failed to update position for tracking $uuid status with: $error',
        category: 'TrackingService._updateTrackingPosition',
        error: error,
        data: {
          'tracking.uuid': uuid,
          'tracking.position.json': jsonEncode(tracking.elementAt(POSITION)),
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
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
        context: _context,
      );
    }
    return repo.contains(uuid);
  }

  Future _addSources(String tuuid) async {
    try {
      if (await _checkTracking(tuuid)) {
        final tracking = repo.get(
          tuuid,
          context: _context,
        );
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
      _context.error(
        'push changes in Tracking $tuuid with: $error',
        category: 'TrackingService._addSources',
        error: error,
        data: {
          'tracking.uuid': tuuid,
          'event.repository.ready': '${repo.isReady}',
          'event.repository.snapshot.number': '${repo.hasSnapshot ? repo.snapshot.number : 'none'}',
        },
        stackTrace: Trace.from(stackTrace),
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
    if (changed.isNotEmpty || empty.isNotEmpty) {
      _context.info(
        'Removed tracking $tuuid from service',
        category: 'TrackingService._removeSources',
      );
      return true;
    }
    return false;
  }

  Future _ensureDetached(TrackingSourceEvent event) async {
    final tuuid = repo.toAggregateUuid(event);
    final data = repo.get(tuuid, context: _context).data;
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
      _context.debug(
        'Processed ${event.type}${replay ? '[replay]' : ''}: $message',
        category: 'TrackingService._addToStream',
      );
    });
  }

  /// Process [TrackingCreated] events fetched from persistent subscription
  /// and add [Tracking]
  void _onEvent(Context context, TrackingRepository repository, SourceEvent event) async {
    try {
      final domain = repository.toDomainEvent(event);
      if (domain is TrackingCreated) {
        await _onTrackingCreated(domain);
      } else if (domain is TrackingDeleted) {
        await _onTrackingDeleted(domain);
      }
    } catch (error, stackTrace) {
      context.error(
        'Failed to handle $event with error $error',
        error: error,
        stackTrace: stackTrace,
        category: 'TrackingService._onEvent',
      );
    }
  }

  void _onDone(Context context, TrackingRepository repository) {
    context.debug(
      '${repository.runtimeType}: subscription closed',
      category: 'TrackingService._onDone',
    );
    if (!_disposed) {
      try {
        _subscription.reconnect();
      } catch (error, stackTrace) {
        context.error(
          'Failed to reconnect to repository with error: $error',
          error: error,
          stackTrace: stackTrace,
          category: 'TrackingService._onDone',
        );
      }
    }
  }

  void _onError(Context context, TrackingRepository repository, Object error, StackTrace stackTrace) {
    context.error(
      'Competing subscription failed $error,\n'
      'stackTrace: ${Trace.format(stackTrace)}',
      error: error,
      stackTrace: stackTrace,
      category: 'TrackingService._onError',
    );
    if (!_disposed) {
      try {
        _subscription.reconnect();
      } catch (e, stackTrace) {
        context.error(
          'Failed to reconnect to repository with error: $e',
          error: error,
          stackTrace: Trace.from(stackTrace),
          category: 'TrackingService._onError',
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
