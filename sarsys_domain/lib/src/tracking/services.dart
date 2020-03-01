import 'dart:async';

import 'package:logging/logging.dart';
import 'package:event_source/event_source.dart';
import 'package:sarsys_domain/sarsys_domain.dart';

/// A competitive [Tracking] position aggregation manager.
///
/// This class compete with other [TrackingPositionManager]
/// instances on which [Tracking] instances it should manage
/// a position for. A persistent subscription on projection
/// '$et-TrackingCreated' with [ConsumerStrategy.RoundRobin]
/// is made when [build()] is called. This ensures than only
/// one [TrackingPositionManager] will manage tracks and
/// aggregate position from these for each [Tracking] instance,
/// regardless of how many [TrackingPositionManager] instances
/// are running in parallel, minimizing write contention on
/// each [Tracking] instance event stream.
///
/// Each [TrackingPositionManager] instance listen to events
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
class TrackingPositionManager extends MessageHandler<DomainEvent> {
  static const String ID = 'id';
  static const String UUID = 'uuid';
  static const String STATUS = 'status';
  static const String TRACKS = 'tracks';
  static const String SOURCE = 'source';
  static const String SOURCES = 'sources';
  static const String ATTACHED = 'attached';
  static const String DETACHED = 'detached';
  static const String POSITIONS = 'positions';
  static const String STREAM = '\$et-TrackingCreated';

  TrackingPositionManager(
    this.repository, {
    this.consume = 5,
    this.maxBackoffTime = const Duration(seconds: 10),
  });
  final int consume;
  final Duration maxBackoffTime;
  final TrackingRepository repository;
  final Set<String> _managed = {};
  final Map<String, Set<String>> _sources = {};
  final Logger logger = Logger('$TrackingPositionManager');

  SubscriptionController _subscription;

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

  /// Build competitive [Tracking] position processor
  void build() {
    _subscription?.dispose();
    _subscription = SubscriptionController<TrackingRepository>(
      logger: logger,
      onDone: _onDone,
      onEvent: _onEvent,
      onError: _onError,
      maxBackoffTime: maxBackoffTime,
    )..compete(
        repository,
        stream: STREAM,
        group: '$runtimeType',
        consume: consume,
        number: EventNumber.first,
        strategy: ConsumerStrategy.RoundRobin,
      );
    repository.store.bus.register<TrackingSourceAdded>(this);
    repository.store.bus.register<TrackingSourceRemoved>(this);
    repository.store.bus.register<DeviceInformationUpdated>(this);
//    repository.store.bus.register<TrackingSourceChanged>(this);
//    repository.store.bus.register<UnitInformationUpdated>(this);
//    repository.store.bus.register<PersonnelInformationUpdated>(this);
  }

  /// Must be called to prevent memory leaks
  void dispose() {
    _subscription?.dispose();
    _subscription = null;
    _streamController.close();
    _disposed = true;
  }

  @override
  void handle(DomainEvent message) {
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
      case DeviceInformationUpdated:
        _onDeviceInformationUpdated(message);
        break;
//      case TrackingSourceChanged:
//        _onTrackingSourceChanged(message);
//        break;
//      case PersonnelInformationUpdated:
//        _onPersonnelInformationUpdated(message);
//        break;
//      case UnitInformationUpdated:
//        _onUnitInformationUpdated(message);
//        break;
    }
  }

  /// Build map of all source uuids to its tracking uuids
  void _onTrackingCreated(TrackingCreated event) async => _ensureManaged(event);

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
  /// managed by this [TrackingPositionManager], the state of the
  /// associated track is changed to 'detached'
  void _onTrackingSourceRemoved(TrackingSourceRemoved event) async => await _ensureDetached(event);

  void _onDeviceInformationUpdated(DeviceInformationUpdated event) {
    if (event.changed.containsKey('position')) {
      final uuid = repository.toAggregateUuid(event);
      if (_sources.containsKey(uuid) && _managed.any(_sources[uuid].contains)) {
        // TODO: Update track
        _addToStream(event);
      }
    }
  }

  /// Calculate geometric mean of last position in all tracks
  Future _aggregatePosition(String uuid) async {
    logger.fine('Aggregated position for Tracking $uuid');
  }

//  void _onTrackingSourceChanged(TrackingSourceChanged event) {
//    final uuid = repository.toAggregateUuid(event);
//    if (_managed.contains(uuid)) {
//      // TODO: Calculate new position
//    }
//  }
//
//  void _onUnitInformationUpdated(UnitInformationUpdated event) {
//    final position = event.changed['position'];
//    if (position != null) {
//      final uuid = repository.toAggregateUuid(event);
//      if (_sources.containsKey(uuid)) {
//        // TODO: Change track status to 'detached' when Unit status is
//      }
//    }
//  }
//
//  void _onPersonnelInformationUpdated(PersonnelInformationUpdated event) {
//    final position = event.changed['status'];
//    if (position != null) {
//      final uuid = repository.toAggregateUuid(event);
//      if (_sources.containsKey(uuid)) {
//        // TODO: Change if personnel is attached to track status to 'detached'
//      }
//    }
//  }

  /// Process [TrackingCreated] events fetched from persistent subscription
  /// and add [Tracking]
  void _onEvent(TrackingRepository repository, SourceEvent event) async {
    final domain = repository.toDomainEvent(event);
    if (domain is TrackingCreated) {
      final uuid = repository.toAggregateUuid(event);
      _managed.add(uuid);
      await _ensureManaged(domain);
      logger.fine('Added tracking $uuid for position processing');
    }
  }

  void _onDone(TrackingRepository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_disposed) {
      _subscription.reconnect(
        repository,
        repository.store,
      );
    }
  }

  void _onError(TrackingRepository repository, dynamic error, StackTrace stackTrace) {
    logger.severe(
      'Competing subscription failed with: $error. stactrace: $stackTrace',
    );
    if (!_disposed) {
      _subscription.reconnect(
        repository,
        repository.store,
      );
    }
  }

  Map<String, dynamic> _findTrackManagedByMe(String tracking, String source) =>
      // Only one attached track for each unique source in each manager instance
      _firstOrNull(
        _sources[source]
            // Find all tracking objects managed by me that tracks given source
            ?.where((managed) => managed == tracking)
            // Find source objects in other tracking objects
            ?.map((other) => _findTrack(repository.get(other), source))
            // Filter out all detached tracks
            ?.where((track) => track?.elementAt(STATUS) == ATTACHED),
      );

  Map<String, dynamic> _findTrackManagedByOthers(String tracking, String source) =>
      // TODO: Select the track with most recent timestamp if multiple was found
      _firstOrNull(
        _sources[source]
            // Find all other tracking objects tracking given source
            ?.where((other) => other != tracking)
            // Find source objects in other tracking objects
            ?.map((other) => _findTrack(repository.get(other), source))
            // Filter out all detached tracks
            ?.where((track) => track?.elementAt(STATUS) == ATTACHED),
      );

  T _firstOrNull<T>(Iterable<T> list) => list?.isNotEmpty == true ? list.first : null;

  Map<String, dynamic> _findTrack(Tracking tracking, String source) => tracking
      .asEntityArray(
        TRACKS,
      )
      .toList()
      .firstWhere(
        (track) => track[SOURCE][UUID] == source,
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
    final command = tracks.contains(id)
        ? _updateTrack(
            uuid,
            tracks.elementAt(id).data
              ..addAll({
                if (status != null) STATUS: status,
                if (positions != null) POSITIONS: positions,
              }))
        : _addTrack(uuid, {
            SOURCE: source,
            if (status != null) STATUS: status,
            if (positions != null) POSITIONS: positions,
          });
    final events = await command;
    return events..forEach(_addToStream);
  }

  FutureOr<Iterable<DomainEvent>> _addTrack(String uuid, Map<String, Object> track) async {
    try {
      return await repository.execute(AddTrackToTracking(uuid, track));
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to add track ${track['id']} to Tracking $uuid: $e, stacktrace: $stackTrace',
      );
      return null;
    }
  }

  FutureOr<Iterable<DomainEvent>> _updateTrack(String uuid, Map<String, Object> track) async {
    try {
      return await repository.execute(UpdateTrackingTrack(uuid, track));
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to update track ${track['id']} in Tracking $uuid: $e, stacktrace: $stackTrace',
      );
      return null;
    }
  }

  Future<bool> _checkTracking(TrackingRepository repository, String uuid) async {
    if (!repository.contains(uuid)) {
      await repository.catchUp();
    }
    return repository.contains(uuid);
  }

  Future _ensureManaged(DomainEvent event) async {
    final uuid = repository.toAggregateUuid(event);
    if (event is TrackingCreated) {
      _addToStream(event);
      await _mapSources(repository, uuid);
    } else if (event is TrackingSourceAdded) {
      if (_appendToSources(event.sourceUuid, uuid)) {
        _addToStream(event);
        final other = _findTrackManagedByOthers(uuid, event.sourceUuid);
        await _ensureTrack(
          uuid,
          event.id,
          event.entity,
          positions: other ?? {}[POSITIONS],
          status: ATTACHED,
        );
        await _aggregatePosition(uuid);
      }
    }
  }

  Future _mapSources(Repository repository, String uuid) async {
    if (await _checkTracking(repository, uuid)) {
      final tracking = repository.get(uuid);
      final tracks = tracking.asEntityArray(TRACKS);
      final sources = tracking.asEntityArray(SOURCES).toList();
      final added = await sources.where((source) => _appendToSources(source[UUID], uuid)).toList();
      final changed = tracks.isEmpty
          ? added.map((source) => {SOURCE: source})
          : added.where(
              (source) => tracks.toList().any((track) => track.elementAt('source/uuid') == source),
            );
      changed.forEach((track) async {
        await _ensureTrack(
          uuid,
          track[ID],
          track[SOURCE],
          status: ATTACHED,
          positions: track[POSITIONS] ?? {},
        );
      });
    } else {
      logger.severe('Tracking $uuid not found in $repository after catch up');
    }
  }

  /// Append tracking uuid to list of tracking uuids for given source
  ///
  /// Returns true if number of tracking uuids changed
  bool _appendToSources(
    String source,
    String tracking,
  ) =>
      (_sources[source]?.length ?? 0) <
      _sources
          .update(
            source,
            (uuids) => uuids..add(tracking),
            ifAbsent: () => {tracking},
          )
          .length;

  Future _ensureDetached(DomainEvent event) async {
    if (event is TrackingSourceAdded || event is TrackingSourceRemoved) {
      final uuid = repository.toAggregateUuid(event);
      final source = (event as TrackingSourceEvent).sourceUuid;
      final track = _findTrackManagedByMe(uuid, source);
      if (track != null) {
        await _ensureTrack(
          uuid,
          track[ID],
          track[SOURCE],
          status: DETACHED,
        );
        _addToStream(event);
      }
    }
  }

  void _addToStream(DomainEvent event) {
    _streamController.add(event);
  }
}
