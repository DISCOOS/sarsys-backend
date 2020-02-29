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

  Map<String, dynamic> _findTrackManagedByMe(String uuid, TrackingSourceEvent event) =>
      // Only one attached track for each unique source in each manager instance
      _firstOrNull(
        _sources[event.source[UUID]]
            // Find all tracking objects managed by me that tracks given source
            ?.where((managed) => managed == uuid)
            // Find source objects in other tracking objects
            ?.map((other) => _findTrack(repository.get(other), event.source[UUID]))
            // Filter out all detached tracks
            ?.where((source) => source?.elementAt(STATUS) == ATTACHED),
      );

  Map<String, dynamic> _findTrackManagedByOthers(String uuid, Map<String, dynamic> source) =>
      // TODO: Select the track with most recent timestamp if multiple was found
      _firstOrNull(
        _sources[source[UUID]]
            // Find all other tracking objects tracking given source
            ?.where((other) => other != uuid)
            // Find source objects in other tracking objects
            ?.map((other) => _findTrack(repository.get(other), source[UUID]))
            // Filter out all detached tracks
            ?.where((source) => source?.elementAt(STATUS) == ATTACHED),
      );

  T _firstOrNull<T>(Iterable<T> list) => list?.isNotEmpty == true ? list.first : null;

  Map<String, dynamic> _findTrack(Tracking tracking, String uuid) => tracking
      .asEntityArray(
        TRACKS,
      )
      .toList()
      .firstWhere(
        (track) => track[SOURCE][UUID] == uuid,
        orElse: () => null,
      );

  Future<Iterable<DomainEvent>> _updateTrack(
    String uuid,
    String id, {
    Map<String, dynamic> positions,
    String status,
  }) async {
    final tracking = repository.get(uuid);
    final tracks = tracking.asEntityArray(TRACKS);
    final track = tracks.elementAt(id).data
      ..addAll({
        if (status != null) STATUS: status,
        if (positions != null) POSITIONS: positions,
      });
    try {
      return await repository.execute(UpdateTrackingSource(uuid, track))
        ..forEach(_addToStream);
    } on Exception catch (e, stackTrace) {
      logger.severe(
        'Failed to update track $id in Tracking $uuid: $e, stacktrace: $stackTrace',
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
      if (_appendToSources(event.source, uuid)) {
        _addToStream(event);
        final other = _findTrackManagedByOthers(uuid, event.source);
        await _updateTrack(
          uuid,
          event.id,
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
      final tracks = tracking.asEntityArray(TRACKS).toList();
      // Append tracking uuid to list of tracking uuids for given source if not added already
      await tracks.where((track) => _appendToSources(track[SOURCE], uuid)).forEach((track) async {
        await _updateTrack(
          uuid,
          track[ID],
          status: ATTACHED,
        );
      });
    } else {
      logger.severe('Tracking $uuid not found in $repository after catch up');
    }
  }

  Future _ensureDetached(DomainEvent event) async {
    if (event is TrackingSourceAdded || event is TrackingSourceRemoved) {
      final uuid = repository.toAggregateUuid(event);
      final track = _findTrackManagedByMe(uuid, event);
      if (track != null) {
        await _updateTrack(
          uuid,
          track[ID],
          status: DETACHED,
        );
        _addToStream(event);
      }
    }
  }

  bool _appendToSources(
    Map<String, dynamic> source,
    String uuid,
  ) =>
      (_sources[source[UUID]]?.length ?? 0) <
      _sources
          .update(
            source[UUID],
            (uuids) => uuids..add(uuid),
            ifAbsent: () => {uuid},
          )
          .length;

  void _addToStream(DomainEvent event) {
    _streamController.add(event);
  }
}
