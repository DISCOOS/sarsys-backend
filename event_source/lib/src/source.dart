import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:event_source/event_source.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:json_patch/json_patch.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';
import 'package:stack_trace/stack_trace.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'domain.dart';
import 'models/AtomFeed.dart';
import 'models/AtomItem.dart';
import 'models/snapshot_model.dart';
import 'results.dart';
import 'storage.dart';
import 'stream.dart' hide StreamResult;
import 'stream.dart' as queue show StreamResult;

const Duration defaultWaitFor = Duration(milliseconds: 3000);
const Duration defaultPullEvery = Duration(milliseconds: 100);

/// Storage class managing events locally in memory received from event store server
@sealed
class EventStore {
  /// [EventStore] constructor
  ///
  /// Parameter [bus] is required. [EventStore] uses it
  /// to publish events after a successful [push] of events
  /// to the appropriate canonical stream.
  ///
  /// Parameter [aggregate] is required. It defines the
  /// aggregate name segment in the [canonicalStream] to source
  /// events from.
  ///
  /// Parameter [prefix] is optional. If given,
  /// it is concatenated with [aggregate] using
  /// `EventStore.toCanonical([prefix, stream])` which
  /// returns a canonical stream name of colon-delimited
  /// stream segments.
  ///
  /// Parameter [useInstanceStreams] controls how this
  /// repository is writing events for each [AggregateRoot]
  /// instance.
  ///
  /// If true, events for each [AggregateRoot] is
  /// written to a separate aggregate instance stream. Each
  /// instance streams are identified by concatenating
  /// [prefix], [aggregate] and [AggregateRoot.uuid] using
  /// `EventStore.toCanonical([prefix, aggregate, uuid])`.
  ///
  /// This is the default behavior since it will minimize
  /// write contention an hence reduce the number of
  /// [WrongExpectedEventVersion] thrown by method [push].
  ///
  /// [EventStore] uses the system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  /// to project all stream instances of [AggregateRoot]s
  /// into one single category stream. This reduces the number
  /// of connections required to subscribe to events making
  /// the overall network load as low as possible. System
  /// projections must be enabled for this to work.
  ///
  /// If false, all events are sourced from the same
  /// [canonicalStream]. This is typically appropriate for
  /// aggregates with a low write-rate or where write
  /// contention is not an issue. In most cases however, it
  /// is probably not a good idea to source all events from
  /// the same stream.
  ///
  EventStore({
    @required this.bus,
    @required this.aggregate,
    @required this.connection,
    @required Storage snapshots,
    this.prefix,
    this.useInstanceStreams = true,
  })  : _snapshots = snapshots,
        logger = Logger('EventStore[${toCanonical([prefix, aggregate])}][${connection.port}]');

  /// Get canonical stream name
  static String toCanonical(List<String> segments) => segments
      .where(
        (test) => test?.trim()?.isNotEmpty == true,
      )
      .join(':');

  /// The name of canonical stream to source events from.
  ///
  /// If [useInstanceStreams] is true, events from all instance
  /// streams are projected by the system projection
  /// [$by_category](https://eventstore.org/docs/projections/system-projections/index.html?tabs=tabid-5#by-category)
  /// to a category stream with name equal to the concatenation
  /// of '$ce-', [prefix] and [aggregate] with colon ':' as
  /// delimiter. All events are read from the category
  /// stream, including any subscriptions.
  ///
  /// Events for each [AggregateRoot] is written to separate
  /// aggregate instance streams. The name of each instance
  /// stream is a concatenation of [prefix], [aggregate] and
  /// [AggregateRoot.uuid]. Method [toInstanceStream] will return
  /// the name of the stream which the events are written to.
  ///
  /// If [useInstanceStreams] is false, all events are
  /// read and written to [canonicalStream], equal to the
  /// concatenation [prefix] and [aggregate] with colon ':'
  /// as delimiter.
  ///
  String get canonicalStream => useInstanceStreams
      ? '\$ce-${toCanonical([
          prefix,
          aggregate,
        ])}'
      : toCanonical([
          prefix,
          aggregate,
        ]);

  /// Stream prefix
  final String prefix;

  /// Stream name
  final String aggregate;

  /// If true, eventstore will write events for each
  /// [AggregateRoot] instance to a separate stream
  final bool useInstanceStreams;

  /// [MessageBus] instance
  final MessageBus bus;

  /// [Logger] instance
  final Logger logger;

  /// [EventStoreConnection] instance
  final EventStoreConnection connection;

  /// Get number of events in store
  int get length => _events.length;

  /// Check if store is empty
  bool get isEmpty => _events.isEmpty;

  /// Check if store is not empty
  bool get isNotEmpty => _events.isNotEmpty;

  /// Map from [Event.uuid] to [AggregateRoot.uuid].
  Map<String, String> get eventMap => Map.unmodifiable(_events);

  /// Map from [AggregateRoot.uuid] to set of [Event.uuid]s
  Map<String, Set<SourceEvent>> get aggregateMap => Map.unmodifiable(_aggregates);

  /// [Map] of events for each aggregate root sourced from stream.
  ///
  /// [LinkedHashMap] remembers the insertion order of keys, and
  /// keys are iterated in the order they were inserted into the map.
  /// This is important for stream id inference from key order.
  ///
  /// [LinkedHashSet] remembers the insertion order of keys, and
  /// keys are iterated in the order they were inserted into the map.
  /// This is important for ensuring that last added [SourceEvent]
  /// can be fetched using [Iterable.last] operation.
  final LinkedHashMap<String, LinkedHashSet<SourceEvent>> _aggregates =
      LinkedHashMap<String, LinkedHashSet<SourceEvent>>();

  /// Map from [Event.uuid] to [AggregateRoot.uuid].
  ///
  /// [LinkedHashMap] remembers the insertion order of keys, and
  /// keys are iterated in the order they were inserted into the map.
  /// This is important for stream id inference from key order.
  ///
  /// This map is used to count number of events
  final LinkedHashMap<String, String> _events = LinkedHashMap();

  /// Get [AggregateRoot.uuid] from given [Event].
  /// Returns null if event does not exist.
  String getAggregateUuid(Event event) => _events[event.uuid];

  /// Check if given [Event] exist in store
  bool containsEvent(Event event) => _events.containsKey(event.uuid);

  /// Check event [SourceEvent] with given [uuid]
  SourceEvent getEvent(String uuid) =>
      _events.containsKey(uuid) ? _aggregates[_events[uuid]].where((e) => e.uuid == uuid).firstOrNull : null;

  /// Get snapshots [Storage] instance
  Storage get snapshots => _snapshots;

  /// Set snapshots [Storage] instance
  set snapshots(Storage snapshots) {
    _snapshots = snapshots;
    if (_snapshots == null && !_snapshots.contains(_snapshot?.uuid)) {
      _snapshot = null;
    }
  }

  Storage _snapshots;

  /// Current snapshot
  SnapshotModel get snapshot => _snapshot;
  SnapshotModel _snapshot;

  /// Current event number for [canonicalStream]
  ///
  /// If AggregateRoot [uuid] is given, the aggregate
  /// instance stream number is returned. This numbers
  /// is the same as for the [canonicalStream] if
  /// [useInstanceStreams] is false.
  ///
  /// If [stream] is given, this takes precedence and
  /// returns the event number for this stream.
  ///
  /// If stream does not exist, [EventNumber.none] is returned.
  ///
  EventNumber current({String stream, String uuid}) {
    if (stream != canonicalStream) {
      final isInstance = (uuid != null || stream != null);
      if (isInstance) {
        assert(useInstanceStreams, 'only allowed when instance streams are used');
        // Stream takes precedence over uuid
        if (stream != null) {
          uuid = toAggregateUuid(stream);
        }
        if (_aggregates.containsKey(uuid)) {
          if (_aggregates[uuid].isNotEmpty) {
            return _aggregates[uuid].last.number;
          } else if (_snapshot != null) {
            // Store is reset to snapshot
            // with no events applied yet
            return EventNumber(
              _snapshot.aggregates[uuid].number.value,
            );
          }
        }
        return EventNumber.none;
      }
    }
    if (_snapshot == null) {
      return EventNumber.none + _events.keys.length;
    }
    final number = EventNumber(_snapshot.number.value);
    final offset = _events.keys.length - _snapshot.aggregates.length;
    if (_snapshot.isPartial) {
      // TODO: This is wrong. Need to store position in projection as well
      return number - min(0, _snapshot.missing - offset);
    }
    return number + offset;
  }

  /// Replay events on given [repo].
  ///
  /// Throws an [InvalidOperation] if
  /// [Repository.store] is not this
  /// [EventStore]. The [bus] is notified
  /// that replay of [AggregateRoot] of
  /// type [T] is performed.
  Future<int> replay<T extends AggregateRoot>(
    Repository<Command, T> repo, {
    String suuid,
    bool strict = true,
    bool master = false,
    List<String> uuids = const [],
  }) async {
    final startTime = DateTime.now();

    // Sanity checks
    _assertState();
    _assertRepository(repo);

    try {
      // Stop subscriptions
      // from catching up
      pause();

      bus.replayStarted<T>();

      // Clear current state
      final offsets = await reset(
        repo,
        uuids: uuids,
        strict: strict,
        // Always replay from last snapshot if not given
        suuid: suuid ?? snapshots?.last?.uuid,
      );

      var count = 0;
      final isPartial = repo.hasSnapshot && repo.snapshot.isPartial;
      final snapshot = repo.hasSnapshot ? (repo.snapshot.isPartial ? '(partial snapshot) ' : '(snapshot) ') : '';

      logger.info(
        "Replay events on ${uuids.isEmpty ? 'all' : uuids.length} ${repo.aggregateType}s $snapshot",
      );

      // Catchup on instance streams first?
      if ((isPartial || uuids.isNotEmpty) && useInstanceStreams) {
        for (var uuid in offsets.keys) {
          if (_isDisposed) break;
          final tic = DateTime.now();
          final offset = offsets[uuid];
          final stream = toInstanceStream(uuid);
          final events = await _catchup(
            repo,
            offset: offset,
            strict: strict,
            stream: stream,
          );
          logger.info(
            "Replayed $events events from stream '$stream' with offset ${offset.value} $snapshot"
            'in ${DateTime.now().difference(tic).inMilliseconds} ms',
          );
          count += events;
        }
      }

      var streams = offsets.length;

      if (!_isDisposed && uuids.isEmpty) {
        final tic = DateTime.now();
        // Start from first event after snapshot
        final offset = _toStreamOffset(
          repo,
          stream: canonicalStream,
        );

        // Fetch all events from canonical stream
        final events = await _catchup(
          repo,
          strict: strict,
          master: master,
          offset: offset,
          stream: canonicalStream,
        );
        logger.info(
          "Replayed $events events from stream '${canonicalStream}' with offset ${offset.value} $snapshot"
          'in ${DateTime.now().difference(tic).inMilliseconds} ms',
        );

        streams += 1;
        count += events;
      }
      if ((isPartial || uuids.isNotEmpty) && useInstanceStreams) {
        logger.info(
          'Replayed $count events from $streams streams $snapshot'
          'in ${DateTime.now().difference(startTime).inMilliseconds} ms',
        );
      }

      return count;
    } finally {
      bus.replayEnded<T>();
      resume();
    }
  }

  /// Reset repository to remote state.
  /// This will all local changes.
  Future<Map<String, EventNumber>> reset(
    Repository repo, {
    String suuid,
    bool strict = true,
    List<String> uuids = const [],
  }) async {
    final numbers = <String, EventNumber>{};
    final hasSnapshot = await repo.reset(
      uuids: uuids,
      suuid: suuid,
    );
    _snapshot = repo.snapshot;
    final existing = hasSnapshot ? _snapshot.aggregates.keys : _aggregates.keys;
    final keep = uuids.isNotEmpty ? uuids : existing;
    final base = existing.toList()..retainWhere((uuid) => keep.contains(uuid));

    _purge(
      repo,
      base,
      numbers,
      remote: false,
      strict: strict,
    );

    for (var uuid in base) {
      _tainted.remove(uuid);
      _cordoned.remove(uuid);
    }

    return numbers;
  }

  /// Purge events sourced before current [Repository.snapshot],
  /// and will set [snapshot] to [Repository.snapshot]. Returns
  /// purged events per [AggregateRoot.uuid].
  Map<String, EventNumber> purge(
    Repository repo, {
    bool strict = true,
    List<String> uuids = const [],
  }) {
    final numbers = <String, EventNumber>{};
    if (repo.hasSnapshot && _snapshot?.uuid != repo.snapshot.uuid) {
      _snapshot = repo.snapshot;
      final existing = _snapshot.aggregates.keys.toList();
      final keep = uuids.isNotEmpty ? uuids : repo.snapshot.aggregates.keys;
      final base = existing..retainWhere((uuid) => keep.contains(uuid));
      repo.purge(uuids: uuids);
      _purge(
        repo,
        base,
        numbers,
        remote: false,
        strict: strict,
      );
    }
    return numbers;
  }

  void _purge(
    Repository repo,
    Iterable<String> base,
    Map<String, EventNumber> numbers, {
    @required bool remote,
    @required bool strict,
  }) {
    final hasSnapshot = repo.hasSnapshot;
    for (var uuid in base) {
      // Remove all events for given aggregate
      // ignore: prefer_collection_literals
      final events = _aggregates[uuid] ?? LinkedHashSet<SourceEvent>();

      // Find all events before snapshot
      final before = events;
      for (var event in before) {
        _events.remove(event.uuid);
      }

      events.clear();
      final stream = toInstanceStream(uuid);
      if (hasSnapshot) {
        final aggregate = repo.get(
          uuid,
          strict: strict,
        );
        for (var e in aggregate.applied) {
          if (remote) {
            assert(e.remote, 'must be remote');
          }
          events.add(e.toSourceEvent(
            streamId: stream,
            number: e.number,
            uuidFieldName: repo.uuidFieldName,
          ));
          _events[e.uuid] = uuid;
        }
      }

      // Register aggregate in store (needed
      // to calculate event number later)
      _aggregates[uuid] = events;

      // Start from first event (tail or snapshot)
      final offset = _toStreamOffset(
        repo,
        stream: stream,
      );
      numbers[uuid] = offset;
    }
  }

  /// Tainted aggregates.
  Map<String, Object> get tainted => Map.unmodifiable(_tainted);
  final _tainted = <String, Object>{};

  /// Check if aggregate with given [uuid] is tainted
  bool isTainted(String uuid) => _tainted.containsKey(uuid);

  /// Taint aggregate with given [uuid].
  ///
  /// A tainted aggregate is in a erroneous
  /// state that. A [reset] will remove the
  /// aggregate from the tainted state.
  ///
  /// Typical reasons for tainting an
  /// aggregate are errors states that
  /// potentially have a automatic resolution.
  ///
  /// If the automatic resolution fails, the
  /// aggregate should be tainted.
  ///
  void taint(Repository repo, String uuid, Object reason) {
    _assertRepository(repo);
    _tainted[uuid] = reason;
    logger.severe(_toMethod('Tainted ${repo.aggregateType} $uuid', [
      'reason: $reason',
    ]));
  }

  bool untaint(String uuid) {
    return _tainted.remove(uuid) != null;
  }

  /// Cordoned aggregates.
  Map<String, Object> get cordoned => Map.unmodifiable(_cordoned);
  final _cordoned = <String, Object>{};

  /// Check if aggregate with given [uuid] is cordoned
  bool isCordoned(String uuid) => _cordoned.containsKey(uuid);

  /// Cordon given aggregate with given [uuid].
  ///
  /// Cordoned aggregates are read-only
  /// and catchup will not be performed
  /// for it. A [reset] will remove the
  /// aggregate from the cordoned state.
  ///
  /// A cordoned aggregate is not
  /// tainted by definition.
  ///
  /// Typical reasons for cordoning an
  /// aggregate are errors states that
  /// need a manual resolution.
  ///
  void cordon(Repository repo, String uuid, Object reason) {
    _assertRepository(repo);
    _cordoned[uuid] = reason;
    _tainted.remove(uuid);
    logger.severe(_toMethod('Cordoned ${repo.aggregateType} $uuid', [
      'reason: $reason',
    ]));
  }

  bool uncordon(String uuid) {
    return _cordoned.remove(uuid) != null;
  }

  EventNumber _toStreamOffset(
    Repository repo, {
    @required String stream,
  }) {
    return _toStreamHead(repo, stream: stream) + 1;
  }

  EventNumber _toStreamHead(
    Repository repo, {
    @required String stream,
  }) {
    final uuid = toAggregateUuid(stream);
    if (uuid != null) {
      final head = repo
          .get(
            uuid,
            // Do not fail! Error handling will skip events automatically
            strict: false,
            createNew: false,
          )
          ?.headEvent;
      if (head != null) {
        return head.number;
      }
    }
    return current(stream: stream);
  }

  /// Catch up with streams.
  /// If [useInstanceStreams] is
  /// true, use [uuids] to only
  /// catchup to instance streams
  /// for given [AggregateRoot.uuid].
  ///
  Future<int> catchup(
    Repository repo, {
    bool strict = true,
    bool master = false,
    List<String> uuids = const [],
  }) async {
    try {
      var count = 0;
      final streams = _toStreams(uuids);

      logger.info(
        "Catchup events on ${uuids.isEmpty ? 'all' : uuids.length} ${repo.aggregateType}s",
      );

      // Stop subscriptions
      // from catching up
      pause();

      // Catchup to given streams
      for (var stream in streams) {
        final previous = current(stream: stream);
        final next = _toStreamOffset(repo, stream: stream);
        final events = await _catchup(
          repo,
          offset: next,
          stream: stream,
          strict: strict,
          master: master,
        );
        if (_isDisposed) break;
        final actual = current(stream: stream);
        if (events > 0) {
          logger.info(
            'Caught up from event $previous to $actual with $events events from remote stream $stream',
          );
        } else {
          logger.info(
            'Local stream $stream is at same event number as remote stream ($previous)',
          );
        }
        count += events;
      }
      return count;
    } finally {
      resume();
    }
  }

  Iterable<String> _toStreams(List<String> uuids) {
    return useInstanceStreams && uuids.isNotEmpty
        // Catchup to given instance streams only
        ? uuids.map((uuid) => toInstanceStream(uuid))
        // Catchup to all streams
        : [canonicalStream];
  }

  /// Flag controlling async handling of events.
  /// If [true], this store is either disposed
  /// or paused.
  bool get _shouldSkipEvents => isDisposed || isPaused;

  /// Catch up with canonical stream
  /// from given (position) [offset]
  ///
  Future<int> _catchup(
    Repository repo, {
    @required bool strict,
    @required String stream,
    @required EventNumber offset,
    bool master = false,
  }) async {
    if (isDisposed) {
      return 0;
    }
    assert(isPaused, 'subscriptions must be paused');

    var count = 0;

    // Lower bound is last known event number in stream
    final actual = EventNumber(
      max(offset.value, current(stream: stream).value),
    );

    final uuid = toAggregateUuid(stream);
    logger.fine(
      _toMethod('_catchUp', [
        'uuid: $uuid',
        'stream: $stream',
        'number.offset: $offset',
        'number.actual: $actual',
        'number.current: ${current(stream: stream)}',
      ]),
    );

    final events = connection.readEventsAsStream(
      stream: stream,
      number: actual,
      master: master,
    );

    // Process results as they arrive
    final completer = Completer();
    final subscription = events.listen(
      (result) {
        try {
          count = _onResult(
            result,
            repo,
            count,
            strict: strict,
          );
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      // Handle errors from connection
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
        logger.network(
          _toMethod('Failed to process events from $stream@$actual', [
            'cause: unknown',
            'error: $error',
            _toObject('debug', [
              'connection: ${connection.host}:${connection.port}',
              'repository: ${repo.runtimeType}',
              'repository.empty: ${repo.isEmpty}',
              'isInstanceStream: $useInstanceStreams',
              'store.events.count: $length',
            ])
          ]),
          error,
          stackTrace,
        );
      },
      cancelOnError: true,
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    try {
      await completer.future;
    } finally {
      await subscription.cancel();
    }
    return count;
  }

  int _onResult(
    ReadResult result,
    Repository repo,
    int count, {
    @required bool strict,
  }) {
    if (!isDisposed && result.isOK) {
      // Group events by aggregate uuid
      final eventsPerAggregate = groupBy<SourceEvent, String>(
        result.events,
        (event) => repo.toAggregateUuid(event),
      );

      // Apply events to aggregates
      eventsPerAggregate.forEach(
        (uuid, events) {
          final domainEvents = _applyAll(
            repo,
            uuid,
            events,
            strict: strict,
          );
          // Publish remotely created events.
          // Handlers can determine events with
          // local origin using the local field
          // in each Event
          publish(domainEvents);
        },
      );

      count += result.events.length;

      // Free up memory
      snapshotWhen(repo);
    }
    return count;
  }

  /// Save a snapshot when locally stored events exceeds [snapshots.threshold].
  ///
  /// Will only save if [Storage.automatic] is true.
  ///
  /// Returns [true] if snapshot is saved, [false] otherwise.
  ///
  bool snapshotWhen(Repository repo) {
    final willSave = repo.isSaveable;
    if (willSave && repo.store.snapshots.automatic == true) {
      repo.save();
    }
    return willSave;
  }

  void _updateAll(
    String uuid,
    String uuidFieldName,
    Iterable<SourceEvent> events, {
    @required bool strict,
  }) {
    var idx = 0;
    final stream = toInstanceStream(uuid);
    final offset = current(stream: stream);
    var previous = offset;

    final sourced = _aggregates.putIfAbsent(
      uuid,
      () => LinkedHashSet<SourceEvent>(),
    );

    for (var event in events) {
      if (strict) {
        // Only check local events. If
        // event is remote, we should
        // skip it instead later when
        // applying to aggregate.
        if (event.local) {
          // Event numbers in instance streams SHOULD ALWAYS
          // be sorted in an ordered monotone incrementing
          // manner. This check ensures that if and only if
          // the assumption is violated, an InvalidOperation
          // exception is thrown. This ensures that previous
          // next states can be calculated safely without any
          // risk of applying patches out-of-order, removing the
          // need to store these states in each event. Do not
          // evaluate events that exist locally only by skipping
          // to first event with number bigger then offset.
          if (event.number <= offset) {
            previous = _assertStrictMonotone(
              uuid: uuid,
              next: event,
              index: idx++,
              stream: stream,
              previous: previous,
              uuidFieldName: uuidFieldName,
            );
          }
        }
      }

      // Already added?
      if (!sourced.add(event)) {
        if (event.remote) {
          final prev = sourced.lookup(event);
          // Workaround for LinkedHashSet
          // will not change when equal
          // event is added (equality is
          // made on type and uuid only)
          prev.remote = true;
        }
      }

      // Only update if absent to preserve insertion order
      _events.putIfAbsent(event.uuid, () => uuid);
    }
  }

  Iterable<DomainEvent> _applyAll(
    Repository repo,
    String uuid,
    List<SourceEvent> events, {
    @required bool strict,
  }) {
    // IMPORTANT: Append to store before applying to repository!
    // This ensures that the event added to an aggregate during
    // construction is overwritten with the remote event actual
    // received here.
    _updateAll(
      uuid,
      repo.uuidFieldName,
      events,
      strict: strict,
    );

    // Will replay or catchup
    final aggregate = repo.get(
      uuid,
      strict: strict,
    );
    final applied = aggregate.applied;
    return applied.where((e) => events.contains(e));
  }

  /// Check if events for [AggregateRoot] with given [uuid] exists
  bool contains(String uuid) => _aggregates.containsKey(uuid);

  /// Get events for given [AggregateRoot.uuid]
  Iterable<SourceEvent> get(String uuid) => List.from(_aggregates[uuid] ?? {});

  /// Commit applied events to store.
  Iterable<DomainEvent> _commit(
    String uuid,
    String uuidFieldName,
    Iterable<DomainEvent> changes,
  ) {
    _assertState();

    // Do not save events during replay,
    // is applied in _catchup instead.
    if (bus.isReplaying == false && changes.isNotEmpty) {
      _updateAll(
        uuid,
        uuidFieldName,
        _toSourceEvents(
          events: changes,
          uuidFieldName: uuidFieldName,
          stream: toInstanceStream(uuid),
        ),
        strict: true,
      );
    }
    return changes;
  }

  /// Publish events to [bus] and [asStream]
  void publish(Iterable<DomainEvent> events) {
    events.forEach((e) => bus.publish(this, e));
    if (_streamController != null) {
      events.forEach(_streamController.add);
    }
  }

  /// Get name of aggregate stream for [AggregateRoot.uuid].
  String toStream(String uuid) {
    return useInstanceStreams ? toInstanceStream(uuid) : canonicalStream;
  }

  /// Get name of aggregate instance stream for [AggregateRoot.uuid].
  String toInstanceStream(String uuid) {
    if (useInstanceStreams) {
      final index = _aggregates.keys.toList().indexOf(uuid);
      return '${toCanonical([prefix, aggregate])}-${index < 0 ? _aggregates.length : index}';
    }
    return canonicalStream;
  }

  /// Get [AggregateRoot.uuid] from instance stream.
  ///
  /// If not found, [null] is returned.
  ///
  String toAggregateUuid(String stream) {
    final parts = stream.split('-');
    final index = int.tryParse(parts.last);
    if (index == null || index >= _aggregates.length) {
      return null;
    }
    return _aggregates.keys.toList().elementAt(index);
  }

  /// Push all changes to AggregateRoot with given [uuid] to [connection].
  ///
  /// This method is typically not called directly by clients. Instead
  /// use a [Repository]. If called from outside a [Repository] with
  /// an open [Transaction] for given [aggregate], it will remain
  /// open, leading to unexpected results.
  ///
  /// If [allowUpdates] is true (default) and this method is called
  /// without any [Transaction] for given [AggregateRoot], remote
  /// changes are merged with local changes in [AggregateRoot]
  /// concurrently with this async call. If an [Transaction] exists,
  /// remote changes are not applied.
  ///
  /// If [allowUpdates] is false (default), all subscriptions are
  /// [pause]d until this method had completed. This prevents any
  /// modifications to occur concurrently with this async call.
  /// Pausing all subscriptions impacts all aggregates, increasing
  /// the time it takes to catchup to any changes made to these
  /// in write-heavy situations (writes will block read).
  ///
  /// Throws an [WrongExpectedEventVersion] if current event number
  /// aggregate instance stream for [aggregate] stored locally is not
  /// equal to the last event number in aggregate instance stream.
  /// This failure is recoverable when the store has caught up with
  /// all events in [canonicalStream].
  ///
  /// Throws an [WriteFailed] for all other failures. This failure
  /// is not recoverable.
  Future<Iterable<DomainEvent>> push(
    String uuid,
    Iterable<DomainEvent> changes, {
    bool allowUpdates = true,
    String uuidFieldName = 'uuid',
  }) async {
    _assertState();
    if (changes.isEmpty) {
      return [];
    }
    final stream = toInstanceStream(uuid);
    final offset = current(stream: stream);
    final version = toExpectedVersion(stream);

    // Has a remote concurrent write occurred?
    if (offset >= changes.first.number) {
      // No need to try to write, just fail directly
      throw WrongExpectedEventVersion(
        'Wrong expected EventNumber',
        stream: stream,
        actual: offset,
        expected: ExpectedVersion.from(
          changes.first.number,
        ),
      );
    }

    var idx = 0;
    changes.fold<EventNumber>(
      offset,
      (previous, next) => _assertStrictMonotone(
        uuid: uuid,
        next: next,
        index: idx++,
        stream: stream,
        previous: previous,
        uuidFieldName: uuidFieldName,
      ),
    );

    try {
      if (!allowUpdates) {
        pause();
      }
      final result = await connection.writeEvents(
        stream: stream,
        version: version,
        events: changes.map((e) => e.toEvent(uuidFieldName)),
      );
      logger.fine(
        _toObject('writeEvents', [
          'uuid: $uuid',
          'version: $version',
          'first: ${changes.first.type}@${changes.first.number}',
          'last: ${changes.last.type}@${changes.last.number}',
          'code: ${result.statusCode}',
          'reason: ${result.reasonPhrase}'
        ]),
      );
      if (_isDisposed) return changes;

      if (result.isCreated) {
        // Commit all changes
        // after successful write
        _commit(uuid, uuidFieldName, changes);
        // Check if commits caught up
        // with last known event in
        // aggregate instance stream
        _assertCurrentVersion(
          stream,
          result.actual,
          reason: 'Push with expected version ${version.value} failed',
        );

        return changes;
      } else if (result.isWrongESNumber) {
        throw WrongExpectedEventVersion(
          result.reasonPhrase,
          stream: stream,
          actual: result.actual,
          expected: result.expected,
        );
      }
      throw WriteFailed(
        'Failed to push changes to $stream: '
        '${changes.map((event) => event.runtimeType)}: '
        '${result.statusCode} ${result.reasonPhrase}',
      );
    } finally {
      if (!allowUpdates) {
        resume();
      }
    }
  }

  /// Get expected version number for given stream.
  ///
  /// IMPORTANT: If no event number exists for given
  /// [stream], [ExpectedVersion.none] MUST BE used
  /// to ensure that only the first concurrent writer
  /// will succeed to create same instance stream.
  /// This will result in a '400 Wrong expected
  /// EventNumber' response forcing a catchup to
  /// occur before a retry is attempted with
  /// an new expected stream id created by
  /// [toInstanceStream], which is based on current
  /// aggregate count (safe since all consumers
  /// are guaranteed to receive events in same
  /// order).
  ///
  ExpectedVersion toExpectedVersion(String stream) {
    final number = current(stream: stream) ?? EventNumber.none;
    return number.isNone ? ExpectedVersion.none : ExpectedVersion.from(number);
  }

  /// Subscription controller for each repository
  /// subscribing to events from [canonicalStream]
  /// TODO: Really not needed as there is a 1-to-1 relationship between repo and store
  final _controllers = <Type, EventStoreSubscriptionController>{};

  /// Subscribe given [repository] to compete for changes from [canonicalStream]
  ///
  /// This will create a
  /// [persistent subscription group](https://eventstore.com/docs/http-api/competing-consumers/index.html)
  /// of repositories with same [Repository.aggregateType], where the
  /// name of the group is [Repository.aggregateType].
  ///
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  EventStoreSubscriptionController compete(
    Repository repository, {
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    _controllers[repository.runtimeType]?.cancel();

    // Get existing or create new
    final controller = _subscribe(
      _controllers[repository.runtimeType] ??
          EventStoreSubscriptionController(
            logger: logger,
            onDone: _onSubscriptionDone,
            onEvent: _onSubscriptionEvent,
            onError: _onSubscriptionError,
            maxBackoffTime: maxBackoffTime,
          ),
      repository,
      competing: true,
      consume: consume,
      strategy: strategy,
    );
    _controllers[repository.runtimeType] = controller;
    return controller;
  }

  /// Subscribe given [repo] to receive changes from [canonicalStream]
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  EventStoreSubscriptionController subscribe(
    Repository repo, {
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) {
    // Sanity checks
    _assertState();
    _assertRepository(repo);

    // Dispose current subscription if exists
    _controllers[repo.runtimeType]?.cancel();

    // Get existing or create new
    final controller = _subscribe(
      _controllers[repo.runtimeType] ??
          EventStoreSubscriptionController(
            logger: logger,
            onDone: _onSubscriptionDone,
            onEvent: _onSubscriptionEvent,
            onError: _onSubscriptionError,
            maxBackoffTime: maxBackoffTime,
          ),
      repo,
      competing: false,
    );
    _controllers[repo.runtimeType] = controller;
    return controller;
  }

  EventStoreSubscriptionController _subscribe(
    EventStoreSubscriptionController controller,
    Repository repository, {
    int consume = 20,
    bool competing = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) {
    // Get next event in stream
    final number = repository.store._toStreamOffset(
      repository,
      stream: canonicalStream,
    );
    return competing
        ? controller.compete(
            repository,
            number: number,
            consume: consume,
            strategy: strategy,
            stream: canonicalStream,
            group: '${repository.aggregateType}',
          )
        : controller.subscribe(
            repository,
            number: number,
            stream: canonicalStream,
          );
  }

  /// Handle event from subscriptions
  void _onSubscriptionEvent(Repository repo, SourceEvent event) {
    // In case paused after events
    // are sent from controller
    if (_shouldSkipEvents) {
      return;
    }

    // Sanity checks
    _assertNotReplaying(repo);

    final uuid = repo.toAggregateUuid(event);
    final actual = current(uuid: uuid);
    final stream = toInstanceStream(uuid);

    try {
      // IMPORTANT: Append to store before applying to repository!
      // This ensures that the event added to an aggregate during
      // construction is overwritten with the remote event actual
      // received here.
      _updateAll(
        uuid,
        repo.uuidFieldName,
        [event],
        strict: true,
      );

      // Event is already applied to aggregate?
      final isApplied = _isApplied(uuid, event, repo);

      if (isApplied) {
        _onReplace(uuid, stream, event, actual, repo);
      } else {
        // This method is only
        _onApply(uuid, stream, event, actual, repo);
      }

      if (logger.level <= Level.FINE) {
        final aggregate = repo.get(uuid, createNew: false, strict: false);
        final applied = aggregate?.applied?.where((e) => e.uuid == event.uuid)?.firstOrNull;
        logger.fine(
          _toMethod('_onSubscriptionEvent', [
            _toObject('${repo.runtimeType}', [
              'event.type: ${event.type}',
              'event.uuid: ${event.uuid}',
              'number: ${event.number}',
              'event.sourced: ${_isSourced(uuid, event)}',
              'event.applied: $isApplied',
              'event.patches: ${applied?.patches?.length}',
              'aggregate.uuid: ${aggregate.uuid}',
              'aggregate.stream: $stream',
              'repository: ${repo.runtimeType}',
              'repository.isEmpty: $isEmpty',
              'repository.number.instance: $actual',
              'isInstanceStream: $useInstanceStreams',
            ]),
          ]),
        );
      }
    } finally {
      snapshotWhen(repo);
    }
  }

  bool _isSourced(String uuid, SourceEvent event) => _aggregates.containsKey(uuid) && _aggregates[uuid].contains(event);
  bool _isApplied(String uuid, SourceEvent event, Repository repo) =>
      repo.contains(uuid) && repo.get(uuid, strict: false).isApplied(event);

  /// Replace event with local 'created' value
  ///
  /// Field 'created' is not stable until it is
  /// written to EventStore. This method  will
  /// apply event to aggregate which in turn
  /// calls method _setModifiers in AggregateRoot,
  /// overwriting fields _createdBy and _changedBy
  /// ensuring that the local 'created' value is
  /// replaced with the stable value.
  void _onReplace(
    String uuid,
    String stream,
    SourceEvent event,
    EventNumber actual,
    Repository repository,
  ) {
    logger.fine(
      _toMethod('_onReplace', [
        _toObject('${event.type}', [
          'event.uuid: ${event.uuid}',
          'number: ${event.number}',
          'remove: ${_isSourced(uuid, event)}',
        ]),
      ]),
    );

    // Catch up with stream
    final aggregate = repository.get(uuid);
    final domainEvent = repository.toDomainEvent(event);
    aggregate.apply(domainEvent);

    // Publish remotely created events.
    // Handlers can determine events with
    // remote origin using the local field
    // in each Event
    publish([domainEvent]);
  }

  /// Apply unseen event to [AggregateRoot] with given [uuid]
  ///
  /// If [Aggregate] is currently in a [Transaction] that
  /// does not allow remote updates, or subscriptions
  /// is [pause]ed, the event is added to [store] only to
  /// be applied later. Events will be applied when
  /// the [Transaction] completes or when subscriptions
  /// are [resume]ed (if not transaction is open for
  /// given [AggregateRoot]).
  ///
  void _onApply(
    String uuid,
    String stream,
    SourceEvent event,
    EventNumber actual,
    Repository repository,
  ) {
    // Only apply events with numbers bigger then current
    if (event.number > actual) {
      logger.fine(
        _toMethod('_onApply', [
          _toObject('${event.type}', [
            'event.uuid: ${event.uuid}',
            'number: ${event.number}',
            'remove: ${_isSourced(uuid, event)}',
          ]),
        ]),
      );

      // Do not apply is subscriptions are suspended
      final allowAnyUpdates = !isPaused;

      // Do not apply if a transaction exists
      final allowTrxUpdates = !repository.inTransaction(uuid);

      if (allowAnyUpdates && allowTrxUpdates) {
        // Catch up with stream
        final exists = repository.contains(uuid);
        final aggregate = repository.get(uuid);
        final domainEvent = repository.toDomainEvent(event);
        if (!aggregate.isApplied(event)) {
          if (exists) {
            aggregate.apply(domainEvent);
          }
          // Only commit if new
          if (aggregate.isNew) {
            aggregate.commit();
          }
        }
        // Publish remotely created events.
        // Handlers can determine events with
        // local origin using the local field
        // in each Event
        publish([domainEvent]);
      }
    }
  }

  /// Handle subscription completed
  void _onSubscriptionDone(Repository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_isDisposed) {
      _controllers[repository.runtimeType].reconnect();
    }
  }

  /// Handle subscription errors
  void _onSubscriptionError(Repository repository, Object error, StackTrace stackTrace) {
    _onFatal(
      '${repository.runtimeType} subscription failed',
      error,
      stackTrace,
    );
    if (!_isDisposed) {
      _controllers[repository.runtimeType].reconnect();
    }
  }

  void _onFatal(String message, Object error, StackTrace stackTrace) {
    logger.network(
      _toMethod('_onFatal', [
        'message: $message',
        'error: $error',
        'stacktrace: ${Trace.format(stackTrace)}',
      ]),
      error,
      stackTrace,
    );
  }

  /// When true, this store should not be used any more
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Assert that this [EventStore] is not [isDisposed]
  void _assertState() {
    if (_isDisposed) {
      throw InvalidOperation('$this is disposed');
    }
  }

  /// Assert that this this [EventStore] is managed by [repository]
  void _assertRepository(Repository repository) {
    if (repository.store != this) {
      throw InvalidOperation('This $this is not managed by ${repository.runtimeType}');
    }
  }

  /// Assert that given [repository] is not replaying
  void _assertNotReplaying(Repository repository) {
    if (repository.isReplaying) {
      print('${repository.runtimeType} is replaying');
      // throw InvalidOperation('${repository.runtimeType} is replaying');
    }
  }

  /// Assert that current event number for [stream] is caught up with last known event
  void _assertCurrentVersion(String stream, EventNumber actual, {String reason = 'Catch up failed'}) {
    final number = current(stream: stream);
    if (number != actual) {
      final stackTrace = StackTrace.current;
      final error = EventNumberMismatch(
        stream: stream,
        actual: actual,
        message: reason,
        current: current(stream: stream),
      );
      logger.severe(
        _toMethod('_assertCurrentVersion', [
          _toObject('${error.runtimeType}', [
            'debug: ${toDebugString(stream)}',
            'error: ${error.message}',
            'stackTrace: ${Trace.format(stackTrace)}',
          ])
        ]),
        error,
        Trace.from(stackTrace),
      );
      throw error;
    }
  }

  EventNumber _assertStrictMonotone({
    @required int index,
    @required Event next,
    @required String uuid,
    @required String stream,
    @required EventNumber previous,
    @required String uuidFieldName,
  }) {
    final expected = next.number.value;
    final delta = expected - previous.value;
    if (delta != 1) {
      throw EventNumberNotStrictMonotone(
        uuid: uuid,
        event: next,
        uuidFieldName: uuidFieldName,
        expected: EventNumber(expected),
        mode: next.remote ? 'remote' : 'applied',
      );
    }
    return next.number;
  }

  /// This stream will only contain [DomainEvent] pushed to remote stream
  StreamController<Event> _streamController;

  /// Get remote [Event] stream.
  Stream<Event> asStream() {
    _streamController ??= StreamController.broadcast();
    return _streamController.stream;
  }

  int _paused = 0;
  bool get isPaused => !isDisposed && _paused > 0;

  /// Pause all subscriptions
  Map<Type, EventNumber> pause() {
    _assertState();
    final numbers = <Type, EventNumber>{};
    if (!isPaused) {
      _controllers.forEach(
        (type, controller) {
          numbers[type] = controller.pause();
        },
      );
    }
    _paused++;
    if (logger.level <= Level.FINE) {
      final trace = Trace.current(1);
      final callee = trace.frames.first;
      logger.fine(_toMethod('pause', [
        'paused: $_paused',
        'callee: ${callee}',
      ]));
    }
    return numbers;
  }

  /// Resume all subscriptions.
  /// Returns current subscription
  /// event number.
  ///
  /// See [EventStoreSubscriptionController.current]
  ///
  Map<Type, EventNumber> resume() {
    final numbers = <Type, EventNumber>{};
    if (isPaused) {
      _paused--;
      if (!isPaused) {
        // Resume or restart from current number
        _controllers.forEach(
          (type, controller) {
            if (_shouldRestart(controller)) {
              // This will NOT create a new instance
              // of EventStoreSubscriptionController,
              // which is what we want.
              if (controller.isCompeting) {
                controller = compete(
                  controller.repository,
                  consume: controller.consume,
                  strategy: controller.strategy,
                  maxBackoffTime: controller.maxBackoffTime,
                );
              } else {
                controller = subscribe(
                  controller.repository,
                  maxBackoffTime: controller.maxBackoffTime,
                );
              }
              numbers[type] = controller.current;
            } else {
              numbers[type] = controller.resume();
            }
          },
        );
      }
    }
    if (logger.level <= Level.FINE) {
      final trace = Trace.current(1);
      final callee = trace.frames.first;
      logger.fine(_toMethod('resume', [
        'paused: $_paused',
        'callee: ${callee}',
      ]));
    }
    return numbers;
  }

  bool _shouldRestart(EventStoreSubscriptionController controller) {
    final number = controller.current;
    final actual = current();
    final diff = actual.value - number.value;
    if (diff > 0) {
      logger.fine(
        'Subscription on ${controller.repository.aggregateType} is behind '
        '(last: $number, actual: $actual, diff: $diff) > restarting',
      );
      return true;
    }
    return false;
  }

  /// Clear events in store and close connection
  Future dispose() async {
    _isDisposed = true;
    _aggregates.clear();

    try {
      // Will not on each command
      // before executing the next
      await Future.wait(
        _controllers.values.map((c) => c.cancel()),
      );
    } on ClientException catch (e, stackTrace) {
      logger.network(
        'Failed to dispose one or more subscriptions '
        'with error: $e,\n'
        'stacktrace: ${Trace.format(stackTrace)}',
        e,
        stackTrace,
      );
    }

    _controllers.clear();
    if (_streamController?.hasListener == true && _streamController?.isClosed == false) {
      // See https://github.com/dart-lang/sdk/issues/19095#issuecomment-108436560
      // ignore: unawaited_futures
      _streamController.close();
    }
  }

  String toDebugString([String stream]) {
    final uuid = _aggregates.keys.firstWhere(
      (uuid) => toInstanceStream(uuid) == stream,
      orElse: () => 'not found',
    );
    return '$runtimeType: {\n'
        'aggregate.uuid: $uuid,\n'
        'store.stream: $stream,\n'
        'store.canonicalStream: $canonicalStream},\n'
        'store.count: ${_aggregates.length},\n'
        '}';
  }

  Iterable<SourceEvent> _toSourceEvents({
    @required String stream,
    @required String uuidFieldName,
    @required Iterable<DomainEvent> events,
  }) {
    assert(stream != null);
    assert(events != null);
    assert(uuidFieldName != null);
    return events.map((e) => e.toSourceEvent(
          streamId: stream,
          number: e.number,
          uuidFieldName: uuidFieldName,
        ));
  }

  /// Check if a [EventStoreSubscriptionController]
  /// exists for given [repository]
  bool hasSubscription(Repository repository) => _controllers.containsKey(repository.runtimeType);
}

/// Class for handling a subscription with automatic reconnection on failures
class EventStoreSubscriptionController<T extends Repository> {
  EventStoreSubscriptionController({
    @required this.onEvent,
    @required this.onDone,
    @required this.onError,
    @required this.logger,
    this.maxBackoffTime = const Duration(seconds: 10),
  });

  /// [Logger] instance
  final Logger logger;

  final void Function(T repository) onDone;
  final void Function(T repository, SourceEvent event) onEvent;
  final void Function(T repository, Object error, StackTrace stackTrace) onError;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// [EventHandler] instance
  EventHandler<SourceEvent> _handler;

  /// Reconnect count. Uses in exponential backoff calculation
  int reconnects = 0;

  /// Number of events processed
  int get processed => _processed;
  int _processed = 0;

  /// Get current [EventNumber]
  /// (position in canonical stream).
  /// Same as [offset] + [processed].
  EventNumber get current => _offset + _processed;

  /// Get subscription [offset].
  EventNumber get offset => _offset;
  EventNumber _offset = EventNumber.none;

  /// Reference for cancelling in [cancel]
  Timer _timer;

  /// Repository instance
  T get repository => _repository;
  T _repository;

  /// Flag indication if subscription is competing for events with other consumers
  bool get isCompeting => _competing;
  bool _competing = false;

  /// Get subscription group if competing for events
  String get group => _group;
  String _group;

  /// Event consumer strategy if subscription is competing for events with other consumers
  ConsumerStrategy get strategy => _strategy;
  ConsumerStrategy _strategy;

  /// Number of events to consume if subscription is competing for events with other consumers
  int get consume => _consume;
  int _consume;

  /// Subscribe to events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  EventStoreSubscriptionController<T> subscribe(
    T repository, {
    @required String stream,
    EventNumber number = EventNumber.first,
  }) {
    _handler?.cancel();
    _group = null;
    _processed = 0;
    _consume = null;
    _strategy = null;
    _offset = number;
    _competing = false;
    _repository = repository;

    // Handle events from stream
    _listen(repository.store.connection.subscribe(
      stream: stream,
      number: number,
    ));

    logger.fine(
      '${repository.runtimeType} > Subscribed to $stream@$number',
    );
    return this;
  }

  /// Compete for events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  EventStoreSubscriptionController<T> compete(
    T repository, {
    @required String stream,
    @required String group,
    int consume = 20,
    EventNumber number = EventNumber.first,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) {
    _handler?.cancel();
    _competing = true;
    _group = group;
    _processed = 0;
    _offset = number;
    _consume = consume;
    _strategy = strategy;
    _repository = repository;

    // Handle events from stream
    _listen(repository.store.connection.compete(
      stream: stream,
      group: group,
      number: number,
      consume: consume,
      strategy: strategy,
    ));

    logger.fine(
      '${repository.runtimeType} > Competing from $stream@$number',
    );
    return this;
  }

  void _listen(Stream<SourceEvent> events) async {
    assert(
      _handler?.isCancelled != false,
      'Handler must be cancelled',
    );

    _handler = EventHandler<SourceEvent>(logger);
    _handler.listen(
      _repository,
      events,
      onEvent: (SourceEvent event) {
        _alive(_repository, event);
        onEvent(_repository, event);
      },
      onPause: () => _timer?.cancel(),
      onDone: () => onDone(_repository),
      onFatal: (event) async {
        // Was unable to handle error
        await cancel();

        // Cleanup
        final type = repository.runtimeType;
        repository.store._controllers.remove(type);
      },
      onError: (error, StackTrace stackTrace) => onError(
        _repository,
        error,
        stackTrace,
      ),
    );
  }

  Future _retry() async {
    try {
      _timer.cancel();
      _timer = null;
      logger.info(
        '${_repository.runtimeType}: SubscriptionController is '
        'reconnecting to stream ${repository.store.canonicalStream}, attempt: $reconnects',
      );
      await _restart();
    } catch (e, stackTrace) {
      logger.network('Failed to reconnect: $e: $stackTrace', e, stackTrace);
    }
  }

  Future _restart() async {
    await _handler?.cancel();
    if (_competing) {
      final controller = await _repository.store.compete(
        repository,
        consume: _consume,
        strategy: _strategy,
        maxBackoffTime: maxBackoffTime,
      );
      _handler = controller._handler;
    } else {
      final controller = await repository.store.subscribe(
        repository,
        maxBackoffTime: maxBackoffTime,
      );
      _handler = controller._handler;
    }
  }

  int toNextReconnectMillis() {
    final wait = toNextTimeout(reconnects++, maxBackoffTime);
    logger.info('Wait ${wait}ms before reconnecting (attempt: $reconnects)');
    return wait;
  }

  void reconnect() async {
    if (!_repository.store.connection.isClosed) {
      // Wait for current timer to complete
      _timer ??= Timer(
        Duration(
          milliseconds: toNextReconnectMillis(),
        ),
        _retry,
      );
    }
  }

  void _alive(T repository, SourceEvent event) {
    if (reconnects > 0) {
      final connection = repository.store.connection;
      logger.info(
        '${repository.runtimeType} reconnected to '
        "'${connection.host}:${connection.port}' after ${reconnects} attempts",
      );
      reconnects = 0;
    }
    _processed++;
    _lastEvent = event;
  }

  /// Get last seen [SourceEvent]
  SourceEvent get lastEvent => _lastEvent;
  SourceEvent _lastEvent;

  /// Check if underlying subscription is paused
  bool get isPaused => _handler?.isPaused == true;

  EventNumber pause() {
    _handler?.pause();
    return current;
  }

  EventNumber resume() {
    _handler?.resume();
    return current;
  }

  Future cancel() {
    _timer?.cancel();
    _repository = null;
    _isCancelled = true;
    return _handler?.cancel();
  }

  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;
}

class EventHandler<T extends Event> {
  EventHandler(this.logger);

  final Logger logger;

  void Function() _onPause;
  void Function() _onResume;
  Future Function(T event) _onFatal;

  /// Underlying stream subscription
  StreamSubscription<T> _subscription;

  /// Check if underlying subscription is paused
  bool get isPaused => _subscription.isPaused == true;

  /// Check if underlying subscription is cancelled.
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  /// Request that the stream pauses events until further notice.
  void pause() {
    _subscription.pause();
    if (_onPause != null) {
      _onPause();
    }
  }

  /// Resume after a pause.
  void resume() {
    _subscription.resume();
    if (_onResume != null) {
      _onResume();
    }
  }

  /// Cancels the underlying subscription.
  Future cancel() async {
    _isCancelled = true;
    return _subscription.cancel();
  }

  void _checkState() {
    assert(!_isCancelled, 'underlying subscription is cancelled');
  }

  /// Handle [Event] of type [T] from stream
  void listen(
    Repository repo,
    Stream<T> stream, {
    @required Function(T event) onEvent,
    void Function() onDone,
    void Function() onPause,
    void Function() onResume,
    Future Function(T event) onFatal,
    void Function(Object error, StackTrace stackTrace) onError,
  }) {
    _checkState();
    _onPause = onPause;
    _onFatal = onFatal;
    _onResume = onResume;
    _subscription = stream.listen(
      (event) {
        _checkState();
        if (!isPaused) {
          _onEvent(
            onEvent,
            event,
            repo,
          );
        }
      },
      onDone: onDone,
      onError: onError,
      cancelOnError: false,
    );
  }

  Future _onEvent(
    Function(T event) onEvent,
    T event,
    Repository repo,
  ) async {
    try {
      onEvent(event);
    } catch (error, stackTrace) {
      final uuid = repo.toAggregateUuid(event);
      final stream = repo.store.toInstanceStream(uuid);
      final message = 'Failed to process ${event.type}@${event.number} from $stream';
      final aggregate = repo.get(uuid, strict: false);

      final isFatal = ErrorHandler(logger).handle(
        event,
        skip: true,
        repo: repo,
        error: error,
        message: message,
        aggregate: aggregate,
        stackTrace: stackTrace,
      );
      if (isFatal) {
        rethrow;
      }
    }
  }
}

class ErrorHandler<T extends Event> {
  ErrorHandler(
    this.logger, {
    Future Function(T event) onFatal,
  }) : _onFatal = onFatal;

  factory ErrorHandler.from(EventHandler<T> handler) => ErrorHandler<T>(
        handler.logger,
        onFatal: handler._onFatal,
      );

  final Logger logger;
  final Future Function(T event) _onFatal;

  bool handle(
    T event, {
    @required bool skip,
    @required Object error,
    @required String message,
    @required Repository repo,
    @required StackTrace stackTrace,
    @required AggregateRoot aggregate,
  }) {
    switch (error.runtimeType) {
      case JsonPatchError:
        handleJsonPatchError(
          event,
          repo: repo,
          skip: skip,
          message: message,
          aggregate: aggregate,
          error: error as JsonPatchError,
          stackTrace: Trace.from(stackTrace),
        );
        return false;
      case EventNumberNotEqual:
        handleEventNumberNotEqual(
          event,
          repo: repo,
          skip: skip,
          message: message,
          aggregate: aggregate,
          stackTrace: Trace.from(stackTrace),
          error: error as EventNumberNotEqual,
        );
        return false;
      case EventNumberNotStrictMonotone:
        handleEventNumberNotStrictMonotone(
          event,
          repo: repo,
          skip: skip,
          message: message,
          aggregate: aggregate,
          stackTrace: Trace.from(stackTrace),
          error: error as EventNumberNotStrictMonotone,
        );
        return false;
      default:
        handleFatal(
          event,
          repo: repo,
          error: error,
          message: message,
          stackTrace: stackTrace,
        );
        return true;
    }
  }

  void handleEventNumberNotEqual(
    T event, {
    @required bool skip,
    @required String message,
    @required Repository repo,
    @required StackTrace stackTrace,
    @required AggregateRoot aggregate,
    @required EventNumberNotEqual error,
  }) {
    // If not handled, every successive event will
    // throw a EventNumberNotStrictMonotone
    // eventually leading to a partial snapshot
    // being stored. Although this exception should
    // never happen, regressions might lead to
    // it happen anyway, which should be logged
    // and handled as follows:

    // ------------------------------------------------
    // 1. On first event: cordon, skip and continue
    // 2. On second event+: skip and continue
    //
    // When aggregate is cordoned, catchup is
    // disabled and aggregate is put in read-only
    // mode until reset or replay is preformed.

    // TODO: Implement recovery from handleEventNumberNotEqual

    final uuid = repo.toAggregateUuid(event);

    _handle(
      event,
      repo: repo,
      skip: skip,
      fatal: true,
      error: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      object: _toObject('${repo.aggregateType}', [
        'uuid: ${error.uuid}',
        _toObject('number', [
          'delta: ${error.delta}',
          'actual: ${error.actual}',
          'expected: ${error.expected}',
        ])
      ]),
      cause: 'Failed to apply ${event.type}@${event.number} on ${repo.aggregateType} $uuid',
    );
  }

  void handleEventNumberNotStrictMonotone(
    T event, {
    @required bool skip,
    @required String message,
    @required Repository repo,
    @required StackTrace stackTrace,
    @required AggregateRoot aggregate,
    @required EventNumberNotStrictMonotone error,
  }) {
    // If not handled, every successive event will
    // throw a EventNumberNotStrictMonotone
    // eventually leading to a partial snapshot
    // being stored. Although this exception should
    // never happen, regressions might lead to
    // it happen anyway, which should be logged
    // and handled as follows:

    // ------------------------------------------------
    // 1. On first event: cordon, skip and continue
    // 2. On second event+: skip and continue
    //
    // When aggregate is cordoned, catchup is
    // disabled and aggregate is put in read-only
    // mode until reset or replay is preformed.

    // TODO: Implement recovery from EventNumberNotStrictMonotone

    final uuid = repo.toAggregateUuid(event);

    _handle(
      event,
      repo: repo,
      skip: skip,
      fatal: true,
      error: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      object: _toObject('${repo.aggregateType}', [
        'uuid: ${error.uuid}',
        _toObject('number', [
          'delta: ${error.delta}',
          'actual: ${error.actual}',
          'expected: ${error.expected}',
        ])
      ]),
      cause: 'Failed to apply ${event.type}@${event.number} on ${repo.aggregateType} $uuid',
    );
  }

  void handleJsonPatchError(
    T event, {
    @required bool skip,
    @required String message,
    @required Repository repo,
    @required JsonPatchError error,
    @required StackTrace stackTrace,
    @required AggregateRoot aggregate,
  }) {
    // If not handled, every successive event will
    // throw a JsonPatchError eventually leading to
    // a partial snapshot being stored. Although this
    // exception should never happen, regressions
    // might lead to it happen anyway, which should
    // be logged and handled as follows:

    // ------------------------------------------------
    // 1. On first event: taint, skip and continue
    // 2. On second event: cordon, skip and continue
    // 3. On third event+: skip and continue
    //
    // When aggregate is cordoned, catchup is
    // disabled and aggregate is put in read-only
    // mode until reset or replay is preformed.

    // TODO: Implement recovery from JsonPatchError

    _handle(
      event,
      repo: repo,
      skip: skip,
      fatal: false,
      error: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      object: _toObject('${repo.aggregateType}', [
        'uuid: ${aggregate.uuid}',
      ]),
      cause: 'Failed to apply ${event.type}@${event.number} '
          'on ${repo.aggregateType} ${aggregate.uuid}',
    );
  }

  void _handle(
    T event, {
    @required bool skip,
    @required bool fatal,
    @required Object error,
    @required String cause,
    @required String object,
    @required Repository repo,
    @required Trace stackTrace,
    @required AggregateRoot aggregate,
  }) {
    final store = repo.store;
    final uuid = aggregate.uuid;

    if (_assertExists(event, cause, object, repo, aggregate, error, stackTrace)) {
      // Should skip event only?
      if (store.isCordoned(uuid)) {
        // Apply it safely by skip patching?
        if (skip) {
          final message = _onSkip(
            event,
            repo,
            aggregate,
            _toMethod(cause, [
              'resolution: event skipped',
              'error: $error',
            ]),
          );
          logger.fine(message);
        }
        return;
      }

      // Should cordon?
      if (store.isTainted(uuid)) {
        // Apply it safely by skip patching?
        final message = skip
            ? _onSkip(
                event,
                repo,
                aggregate,
                _toMethod(cause, [
                  'resolution: event skipped',
                  'error: $error',
                ]),
              )
            : cause;
        store.cordon(repo, uuid, message);
        return;
      }

      // First error, skip? and taint
      final message = skip
          ? _onSkip(
              event,
              repo,
              aggregate,
              _toMethod(cause, [
                'resolution: event skipped',
                'error: $error',
                toDebug(event, repo, aggregate),
              ]),
            )
          : cause;

      if (fatal) {
        store.cordon(repo, uuid, message);
      } else {
        store.taint(repo, uuid, message);
      }
    }
  }

  String _onSkip(T event, Repository repo, AggregateRoot aggregate, String message) {
    aggregate.apply(
      event is DomainEvent
          ? event
          : repo.toDomainEvent(
              event,
              strict: false,
            ),
      skip: true,
    );
    return message;
  }

  bool _assertExists(
    T event,
    String cause,
    String object,
    Repository repo,
    AggregateRoot aggregate,
    Object error,
    Trace stackTrace,
  ) {
    if (aggregate == null) {
      final uuid = repo.toAggregateUuid(event);
      // This is a fatal error
      handleFatal(
        event,
        repo: repo,
        message: _toMethod(cause, [
          _toObject('${repo.aggregateType} $uuid not found in repository', [
            object,
            _toObject('cause', [
              'error: $error',
              'stackTrace: ${Trace.format(StackTrace.current)}',
            ]),
          ]),
          toDebug(event, repo, aggregate),
        ]),
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }

    if (!repo.store.contains(aggregate.uuid)) {
      // This is a fatal error
      handleFatal(
        event,
        repo: repo,
        message: _toMethod(cause, [
          _toObject('Event ${event.type} not found in store', [
            object,
            _toObject('cause', [
              'error: $error',
              'stackTrace: ${Trace.format(StackTrace.current)}',
            ]),
          ]),
          toDebug(event, repo, aggregate),
        ]),
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
    return true;
  }

  static bool isHandling(Object error) => error is JsonPatchError || error is EventNumberNotStrictMonotone;

  static String toDebug(Event event, Repository repo, AggregateRoot aggregate) {
    final uuid = aggregate?.uuid;
    return _toObject('debug', [
      'connection: ${repo.store.connection.host}:${repo.store.connection.port}',
      'event.type: ${event.type}',
      'event.uuid: ${event.uuid}',
      'event.number: ${event.number}',
      _toObject(
        'event.patches',
        event.patches.map((p) => '$p').toList(),
      ),
      'aggregate.uuid: ${uuid ?? repo.toAggregateUuid(event)}',
      'aggregate.type: ${repo.aggregateType}',
      'aggregate.number: ${aggregate?.number}',
      'repository: ${repo.runtimeType}',
      'repository.empty: ${repo.isEmpty}',
      'isInstanceStream: ${repo.store.useInstanceStreams}',
      'store.events.count: ${repo.store.length}',
    ]);
  }

  void handleFatal(
    T event, {
    @required Object error,
    @required Repository repo,
    String message,
    StackTrace stackTrace,
  }) {
    final store = repo.store;
    final uuid = repo.toAggregateUuid(event);
    final stream = repo.store.toInstanceStream(uuid);

    // Concatenate additional error information
    message = _toMethod(message, [
      'event: ${event.type}@${event.number}',
      'stream: $stream',
      'resolution: cordon ${repo.aggregateType} $uuid',
      _toObject('cause', [
        'error: $error',
        'stacktrace: ${Trace.format(stackTrace)}',
      ]),
      toDebug(
        event,
        repo,
        repo.get(uuid, createNew: false, strict: false),
      ),
    ]);

    store.cordon(repo, uuid, message);

    if (_onFatal != null) {
      _onFatal(event);
    }
  }
}

// TODO: Add delete operation to EventStoreConnection

/// EventStore HTTP connection class
@sealed
class EventStoreConnection {
  EventStoreConnection({
    this.host = 'http://127.0.0.1',
    this.port = 2113,
    this.pageSize = 20,
    this.requireMaster = false,
    this.enforceAddress = true,
    this.credentials = UserCredentials.defaultCredentials,
    Duration connectionTimeout = const Duration(seconds: 10),
  })  : _logger = Logger('EventStoreConnection[port:$port]'),
        client = IOClient(
          HttpClient()..connectionTimeout = connectionTimeout,
        );

  final int port;
  final String host;
  final int pageSize;
  final Client client;
  final bool requireMaster;
  final bool enforceAddress;
  final UserCredentials credentials;

  final Logger _logger;

  /// Get atom feed from stream
  Future<FeedResult> getFeed({
    @required String stream,
    int pageSize,
    bool embed = false,
    bool master = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = defaultWaitFor,
  }) async {
    _assertState();
    final actual = number.isNone ? EventNumber.first : number;
    final url = '$host:$port/streams/$stream${_toFeedUri(
      embed: embed,
      number: actual,
      direction: direction,
      pageSize: pageSize ?? this.pageSize,
    )}';
    _logger.finer('getFeed: REQUEST $url');

    final headers = {
      'Authorization': credentials.header,
      'ES-RequireMaster': '${master && requireMaster}',
      'Accept': 'application/vnd.eventstore.atom+json',
      if (waitFor.inMilliseconds > 0) 'ES-LongPoll': '${waitFor.inSeconds}',
    };
    final response = await client.get(
      url,
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/vnd.eventstore.atom+json',
        if (waitFor.inMilliseconds > 0) 'ES-LongPoll': '${waitFor.inSeconds}'
      },
    );
    _logger.finer('getFeed: RESPONSE ${response.statusCode}');
    if (response.statusCode != HttpStatus.temporaryRedirect) {
      return FeedResult.from(
        stream: stream,
        number: actual,
        embedded: embed,
        response: response,
        direction: direction,
      );
    }
    _logger.fine(
      'Redirect read to master ${response.headers['location']}',
    );
    try {
      final redirected = await client.get(
        response.headers['location'],
        headers: headers,
      );
      if (redirected.statusCode != 200) {
        _logger.warning(
          'Redirect read from master ${response.headers['location']} '
          'failed with ${redirected.statusCode} ${redirected.reasonPhrase}',
        );
      }
      return FeedResult.from(
        stream: stream,
        number: actual,
        embedded: embed,
        response: response,
        direction: direction,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Redirect read to master ${response.headers['location']} failed',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  String _toFeedUri({EventNumber number, Direction direction, int pageSize, bool embed}) {
    String uri;
    if (number.isFirst) {
      uri = '/0/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
    } else if (number.isLast) {
      uri = '/head/backward/$pageSize';
    } else if (!number.isNone) {
      uri = '/${number.value}/${direction == Direction.forward ? 'forward' : 'backward'}/$pageSize';
    } else {
      throw ArgumentError('Event number can not be $number');
    }
    if (embed) {
      uri = '$uri?embed=body';
    }
    _logger.finest(uri);
    return uri;
  }

  /// Read events in [AtomFeed.entries] and return all in one result
  Future<ReadResult> readEvents({
    @required String stream,
    bool embed = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    final result = await getFeed(
      embed: embed,
      stream: stream,
      number: number,
      direction: direction,
    );
    if (result.isOK == false) {
      return ReadResult(
        stream: stream,
        atomFeed: result.atomFeed,
        statusCode: result.statusCode,
        reasonPhrase: result.reasonPhrase,
        direction: direction,
        number: number,
        events: [],
      );
    }
    return readEventsInFeed(result);
  }

  /// Read events in [AtomFeed.entries] in given [FeedResult.direction] and return all in one result
  Future<ReadResult> readEventsInFeed(FeedResult result) async {
    _assertState();

    final events = <SourceEvent>[];
    if (result.embedded) {
      events.addAll(
        _ensureOrder(result.atomFeed, result.direction).map(
          (item) => SourceEvent(
            data: item.data,
            uuid: item.eventId,
            type: item.eventType,
            streamId: item.streamId,
            number: EventNumber(item.eventNumber),
            created: DateTime.tryParse(item.updated),
          ),
        ),
      );
    } else {
      final requests = _getEvents(
        result.atomFeed,
        result.direction,
        result.number,
      );
      for (var request in requests) {
        final response = await request;
        if (response.statusCode == 200) {
          events.add(
            _toEvent(
              Map<String, dynamic>.from(json.decode(response.body) as Map),
            ),
          );
        }
        assert(
            events.first.number.value <= events.last.number.value,
            'Event numbers must be monotone increasing, \n'
            'first: ${events.first.type}[${events.first.number}], \n'
            'last: ${events.first.type}[${events.last.number}], \n'
            'atomFeed.entries: ${result.atomFeed.entries.map((e) => e.summary)}');
      }
    }
    return ReadResult(
      stream: result.stream,
      statusCode: events.isEmpty ? 404 : 200,
      reasonPhrase: events.isEmpty ? 'Not found' : 'OK',
      events: events,
      atomFeed: result.atomFeed,
      number: events.isEmpty ? result.number : result.number + (events.length - 1),
      direction: result.direction,
    );
  }

  SourceEvent _toEvent(Map<String, dynamic> data) => SourceEvent(
        uuid: data['eventId'] as String,
        type: data['eventType'] as String,
        streamId: data['eventStreamId'] as String,
        data: data['content']['data'] as Map<String, dynamic>,
        created: DateTime.tryParse(data['updated'] as String),
        number: EventNumber(data['content']['eventNumber'] as int),
      );

  /// Read events as paged results and return results as stream
  Stream<ReadResult> readEventsAsStream({
    @required String stream,
    int pageSize = 20,
    bool master = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = defaultWaitFor,
  }) {
    _assertState();

    var controller = _EventStreamController(
      this,
      master: master,
    );

    return controller.read(
      stream: stream,
      number: number,
      waitFor: waitFor,
      pageSize: pageSize,
      direction: direction,
    );
  }

  /// Read events in [AtomFeed.entries] and return all in one result
  Future<ReadResult> readAllEvents({
    @required String stream,
    bool embed = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    // Get Initial atom feed
    var feed = await getFeed(
      embed: embed,
      stream: stream,
      number: number,
      direction: direction,
    );

    if (feed.isOK == false) {
      return ReadResult(
        stream: stream,
        atomFeed: feed.atomFeed,
        statusCode: feed.statusCode,
        reasonPhrase: feed.reasonPhrase,
        direction: direction,
        number: number,
        events: [],
      );
    }

    ReadResult next;
    var result = ReadResult(
      stream: stream,
      number: number,
      direction: direction,
      statusCode: 404,
      reasonPhrase: 'Not found',
      events: [],
    );

    // Loop until all events are fetched from stream
    do {
      next = await readEventsInFeed(feed);
      if (next.isOK) {
        result = result == null ? next : result + next;
        if (hasNextFeed(result)) {
          feed = await getNextFeed(feed)
            ..assertResult();
        }
      }
    } while (next?.isOK == true && hasNextFeed(result));

    return result;
  }

  /// Check if pagination is reached its end
  bool hasNextFeed(FeedResult result) => !(result.direction == Direction.forward ? result.isHead : result.isTail);

  /// Get next [AtomFeed] from previous [FeedResult.atomFeed] in given [FeedResult.direction].
  Future<FeedResult> getNextFeed(FeedResult result) async {
    _assertState();
    final tic = DateTime.now();
    return _checkSlowRead(
      FeedResult.from(
        stream: result.stream,
        number: result.number,
        embedded: result.embedded,
        direction: result.direction,
        response: await client.get(
          _toUri(
            result.direction,
            result.atomFeed,
            result.embedded,
          ),
          headers: {
            'Authorization': credentials.header,
            'Accept': 'application/vnd.eventstore.atom+json',
          },
        ),
      ),
      tic,
      DurationMetric.limit,
    );
  }

  String _toUri(Direction direction, AtomFeed atomFeed, bool embed) {
    var uri = direction == Direction.forward
        ? atomFeed.getUri(AtomFeed.previous) ?? atomFeed.getUri(AtomFeed.first)
        : atomFeed.getUri(AtomFeed.next) ?? atomFeed.getUri(AtomFeed.last);
    if (embed) {
      uri = '$uri$embed=body';
    }
    _logger.finest(uri);
    return uri;
  }

  Iterable<Future<Response>> _getEvents(
    AtomFeed atomFeed,
    Direction direction,
    EventNumber number,
  ) {
    var entries = _ensureOrder(atomFeed, direction);

    if (atomFeed.headOfStream && number.isLast && direction == Direction.forward) {
      // We do not know the EventNumber of the last
      // event in each stream other than
      // '/streams/{name}/head'. When paginating
      // forwards and requested number is
      // [EventNumber.last] we will get last page
      // of events, and not only the last event
      // which is requested. We can work around this
      // by only returning the last entry in
      // [AtomFeed.entries] and current page is
      // [AtomFeed.headOfStream]. This will only
      // fetch the last event from remote log.
      entries = [entries.last];
    }
    return entries.map(
      (item) => _getEvent(_getUri(item)),
    );
  }

  Iterable<AtomItem> _ensureOrder(
    AtomFeed atomFeed,
    Direction direction,
  ) {
    return direction == Direction.forward
        // When direction is forward, reverse order of
        // events to ensure event numbers are monotone
        // increasing (event store always return events
        // in decreasing order)
        ? atomFeed.entries.reversed
        : atomFeed.entries;
  }

  /// Get event from stream
  Future<Response> _getEvent(String url) => client.get(
        _mapUrlTo(url),
        headers: {
          'Authorization': credentials.header,
          'Accept': 'application/vnd.eventstore.atom+json',
        },
      );

  String _getUri(AtomItem item) {
    _logger.finest(item.getUri(AtomItem.alternate));
    return item.getUri(AtomItem.alternate);
  }

  /// Write given [events] to given [stream]
  Future<WriteResult> writeEvents({
    @required String stream,
    @required Iterable<Event> events,
    ExpectedVersion version = ExpectedVersion.any,
  }) async {
    _assertState();
    final tic = DateTime.now();
    final sourced = <SourceEvent>[];
    final data = events.map(
      (event) => {
        'data': event.data,
        'eventType': event.type,
        'eventId': _toSourceEvent(
          event,
          stream: stream,
          events: sourced,
          number: event.number,
        ),
      },
    );
    final url = _toStreamUri(stream);
    final body = json.encode(data.toList());
    final headers = {
      'Authorization': credentials.header,
      'ES-RequireMaster': '$requireMaster',
      'ES-ExpectedVersion': '${version.value}',
      'Content-type': 'application/vnd.eventstore.events+json',
    };
    final response = await client.post(
      url,
      headers: headers,
      body: body,
    );
    if (response.statusCode != HttpStatus.temporaryRedirect) {
      return _checkSlowWrite(
        WriteResult.from(
          stream: stream,
          events: sourced,
          version: version,
          response: response,
        ),
        tic,
        DurationMetric.limit,
      );
    }
    _logger.fine(
      'Redirect write to master ${response.headers['location']}',
    );
    try {
      final redirected = await client.post(
        response.headers['location'],
        headers: headers,
        body: body,
      );
      if (redirected.statusCode != 201) {
        _logger.warning(
          'Redirect write to master ${response.headers['location']} '
          'failed with ${redirected.statusCode} ${redirected.reasonPhrase}',
        );
      }
      return _checkSlowWrite(
        WriteResult.from(
          stream: stream,
          events: sourced,
          version: version,
          response: redirected,
        ),
        tic,
        DurationMetric.limit,
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Redirect write to master ${response.headers['location']} failed',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Get connection metadata
  Map<String, dynamic> toMeta() => {
        'metrics': {
          'read': _metrics['read'].toMeta(),
          'write': _metrics['write'].toMeta(),
        }
      };

  /// Map of metrics
  final Map<String, DurationMetric> _metrics = {
    'read': DurationMetric.zero,
    'write': DurationMetric.zero,
  };

  FeedResult _checkSlowRead(FeedResult feed, DateTime tic, int limit) {
    if (feed?.isOK == true) {
      final metric = _metrics['read'].now(tic);
      if (metric.duration.inMilliseconds > limit) {
        _logger.warning(
          'SLOW READ: Reading ${feed.atomFeed.entries.length} '
          'from ${feed.stream}@${feed.number} in direction ${enumName(feed.direction)} '
          'took ${metric.duration.inMilliseconds} ms',
        );
      }
      _metrics['read'] = metric;
    }
    return feed;
  }

  WriteResult _checkSlowWrite(WriteResult write, DateTime tic, int limit) {
    if (write?.isCreated == true) {
      final metric = _metrics['write'].now(tic);
      if (metric.duration.inMilliseconds > limit) {
        _logger.warning(
          'SLOW WRITE: Writing ${write.events.length} '
          'to ${write.stream} took ${metric.duration.inMilliseconds} ms',
        );
      }
      _metrics['write'] = metric;
    }
    return write;
  }

  String _toStreamUri(String stream) => '$host:$port/streams/$stream';

  String _toSourceEvent(
    Event event, {
    @required String stream,
    @required EventNumber number,
    @required List<SourceEvent> events,
  }) {
    events.add(SourceEvent(
      number: number,
      streamId: stream,
      type: event.type,
      data: event.data,
      uuid: event.uuid,
      local: event.local,
      created: event.created,
    ));
    return event.uuid;
  }

  /// Subscribe to [SourceEvent]s from given [stream]
  Stream<SourceEvent> subscribe({
    @required String stream,
    EventNumber number = EventNumber.last,
    Duration waitFor = defaultWaitFor,
    Duration pullEvery = defaultPullEvery,
  }) {
    _assertState();

    final controller = _EventStoreSubscriptionControllerImpl(
      this,
    );

    return controller.pull(
      stream: stream,
      number: number,
      waitFor: waitFor,
      pullEvery: pullEvery,
    );
  }

  /// Compete for [SourceEvent]s from given [stream]
  Stream<SourceEvent> compete({
    @required String stream,
    @required String group,
    int consume = 20,
    bool accept = true,
    EventNumber number = EventNumber.last,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration pullEvery = defaultPullEvery,
  }) {
    _assertState();

    final controller = _EventStoreSubscriptionControllerImpl(
      this,
    );

    return controller.consume(
      stream: stream,
      group: group,
      accept: accept,
      number: number,
      pageSize: consume,
      strategy: strategy,
      pullEvery: pullEvery,
    );
  }

  /// Get feed for persistent subscription group.
  ///
  /// Will attempt to create subscription group if not found.
  Future<FeedResult> getSubscriptionFeed({
    @required String stream,
    @required String group,
    @required EventNumber number,
    int consume = 20,
    bool embed = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final actual = number.isNone ? EventNumber.first : number;
    final response = await _getSubscriptionGroup(stream, group, consume, embed);
    _logger.finer('getSubscriptionFeed: RESPONSE ${response.statusCode}');
    switch (response.statusCode) {
      case HttpStatus.ok:
        return FeedResult.from(
          stream: stream,
          number: actual,
          embedded: embed,
          response: response,
          subscription: group,
        );
        break;
      case HttpStatus.notFound:
        final result = await createSubscription(
          stream,
          group,
          number: actual,
          strategy: strategy,
        );
        if (result.isCreated || result.isConflict) {
          final retry = await _getSubscriptionGroup(stream, group, consume, embed);
          _logger.finer('getSubscriptionFeed: RETRY ${response.statusCode}');
          return FeedResult.from(
            stream: stream,
            number: actual,
            response: retry,
            embedded: embed,
            subscription: group,
          );
        }
        break;
    }
    return FeedResult.from(
      stream: stream,
      number: actual,
      embedded: embed,
      response: response,
      subscription: group,
    );
  }

  /// Create a persistent subscription.
  ///
  /// Before interacting with a subscription group, you need to create one.
  /// You will receive an error if you attempt to create a subscription group more than once.
  Future<SubscriptionResult> createSubscription(
    String stream,
    String group, {
    EventNumber number = EventNumber.first,
    Duration timeout = const Duration(seconds: 1),
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final url = _mapUrlTo('$host:$port/subscriptions/$stream/$group');
    final result = await client.put(url,
        headers: {
          'Authorization': credentials.header,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'startFrom': number.value,
          // IMPORTANT: This will resolve to events instead of atom items in subscription stream
          'resolveLinktos': true,
          'namedConsumerStrategy': enumName(strategy),
          'messageTimeoutMilliseconds': timeout.inMilliseconds,
        }));
    return SubscriptionResult.from(
      stream: stream,
      group: group,
      number: number,
      strategy: strategy,
      response: result,
    );
  }

  Future<Response> _getSubscriptionGroup(String stream, String group, int count, bool embed) {
    var url = _mapUrlTo('$host:$port/subscriptions/$stream/$group/$count');
    if (embed) {
      url = '$url?embed=body';
    }
    _logger.finer('_getSubscriptionGroup: REQUEST $url');
    return client.get(
      url,
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/vnd.eventstore.competingatom+json',
      },
    );
  }

  /// Acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionAck({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
  }) =>
      _writeSubscriptionAnswer(stream, group, events, nack: false);

  /// Acknowledge all messages in [SubscriptionFeed]
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionAckAll(FeedResult feed) async {
    final url = feed.atomFeed.getUri('ackAll');
    final response = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
      },
    );
    return SubscriptionResult.from(
      stream: feed.stream,
      group: feed.subscription,
      response: response,
    );
  }

  /// Negative acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> writeSubscriptionNack({
    @required String stream,
    @required String group,
    @required List<SourceEvent> events,
    SubscriptionAction action = SubscriptionAction.Retry,
  }) =>
      _writeSubscriptionAnswer(stream, group, events, nack: true);

  /// Acknowledge multiple messages
  ///
  /// Clients must acknowledge (or not acknowledge) messages in the competing consumer model.
  /// If the client fails to respond in the given timeout period, the message will be retried.
  Future<SubscriptionResult> _writeSubscriptionAnswer(
    String stream,
    String group,
    List<SourceEvent> events, {
    bool nack = false,
    SubscriptionAction action = SubscriptionAction.Retry,
  }) async {
    final answer = nack ? 'nack' : 'ack';
    final ids = events.map((event) => event.uuid).join(',');
    final nackAction = nack ? '?action=${enumName(action)}' : '';
    final url = '$host:$port/subscriptions/$stream/$group/$answer?ids=$ids$nackAction';
    final result = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
//        'Content-Type': 'application/json',
      },
    );
    return SubscriptionResult.from(
      stream: stream,
      group: group,
      response: result,
    );
  }

  /// Read state of projection [name]
  Future<ProjectionResult> projectionCommand({
    @required String name,
    @required ProjectionCommand command,
  }) async {
    final url = '$host:$port/projection/$name/command/${enumName(command)}';
    final result = await client.post(
      url,
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/json',
      },
    );
    return ProjectionResult.from(
      name: name,
      response: result,
    );
  }

  /// Read state of projection [name]
  Future<ProjectionResult> readProjection({
    @required String name,
  }) async {
    final result = await client.get(
      '$host:$port/projection/$name',
      headers: {
        'Authorization': credentials.header,
        'Accept': 'application/json',
      },
    );
    return ProjectionResult.from(
      name: name,
      response: result,
    );
  }

  /// When true, this store should not be used any more
  bool get isClosed => _isClosed;
  bool _isClosed = false;
  void _assertState() {
    if (_isClosed) {
      throw InvalidOperation('$this is closed');
    }
  }

  /// Close connection.
  ///
  /// This [EventStoreConnection] instance should be disposed afterwards.
  void close() {
    _isClosed = true;
    client.close();
  }

  @override
  String toString() {
    return 'EventStoreConnection{host: $host, port: $port, pageSize: $pageSize}';
  }

  String _mapUrlTo(String url) {
    if (enforceAddress) {
      var uri = Uri.parse(url);
      final host = uri.host;
      if (uri.hasPort) {
        final next = url.replaceFirst('${uri.scheme}://$host:${uri.port}', '${this.host}:$port');
        return next;
      }
      return url.replaceFirst('$host', '${this.host}:$port');
    }
    return url;
  }
}

class _EventStreamController {
  _EventStreamController(
    this.connection, {
    bool master = false,
  })  : _master = master,
        logger = connection._logger;

  final Logger logger;
  final EventStoreConnection connection;

  int get pageSize => _pageSize;
  int _pageSize;

  String get stream => _stream;
  String _stream;

  Duration get waitFor => _waitFor;
  Duration _waitFor;

  EventNumber get number => _number;
  EventNumber _number;

  Direction get direction => _direction;
  Direction _direction;

  EventNumber get current => _current;
  EventNumber _current;

  ReadResult _pendingResume;
  bool _isPaused = true;

  StreamController<ReadResult> get controller => _controller;
  StreamController<ReadResult> _controller;

  final bool _master;
  bool get master => _master;

  Stream<ReadResult> read({
    @required String stream,
    int pageSize = 20,
    bool broadcast = true,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
    Duration waitFor = defaultWaitFor,
  }) {
    // Setup
    _stream = stream;
    _number = number;
    _current = number;
    _waitFor = waitFor;
    _pageSize = pageSize;
    _direction = direction;

    _controller?.close();
    _controller = broadcast
        ? StreamController<ReadResult>.broadcast(
            onListen: _startRead,
            onCancel: _stopRead,
          )
        : StreamController<ReadResult>(
            onPause: _pauseRead,
            onCancel: _stopRead,
            onListen: _startRead,
            onResume: _startRead,
          );
    return controller.stream;
  }

  void _startRead() async {
    try {
      logger.fine(
        _isPaused
            ? 'Started reading events from $stream@$_number in direction ${enumName(_direction)}'
            : 'Resumed reading events from $stream@$_current in direction ${enumName(_direction)}',
      );
      _resume();

      FeedResult feed;
      do {
        if (!_isPaused) {
          final tic = DateTime.now();
          // Null on pause
          feed = connection._checkSlowRead(
            await _readNext(),
            tic,
            DurationMetric.limit,
          );
        }
      } while (feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty));
      _stopRead();
    } catch (e, stackTrace) {
      _onFatal(
        'Failed to read stream $_stream@$_current in direction ${enumName(_direction)}, error: $e',
        stackTrace,
      );
    }
  }

  void _resume() {
    _isPaused = false;
    if (_pendingResume != null) {
      _onResult(_pendingResume);
      _pendingResume = null;
    }
  }

  Future<FeedResult> _readNext() async {
    final feed = await _nextFeed();
    if (!_isPaused) {
      await _readEventsInFeed(feed);
    }
    return _isPaused ? null : feed;
  }

  void _pauseRead() {
    _isPaused = true;
    logger.fine('Paused reading events from stream $_stream');
  }

  void _stopRead() {
    if (_controller != null) {
      logger.fine('Stopped reading events from stream $_stream@$_current');
      _controller.close();
      _controller = null;
    }
  }

  Future<ReadResult> _readEventsInFeed(FeedResult feed) async {
    if (feed.isOK) {
      final result = await connection.readEventsInFeed(feed);
      if (_isPaused) {
        _pendingResume = result;
      } else {
        _onResult(result);
      }
      return result;
    }
    return ReadResult(
      number: feed.number,
      stream: feed.stream,
      direction: feed.direction,
      atomFeed: feed.atomFeed,
      statusCode: feed.statusCode,
      reasonPhrase: feed.reasonPhrase,
    );
  }

  void _onResult(ReadResult result) {
    if (result.isOK) {
      final next = result.number + 1;
      _current = next;
      logger.fine(
        'Read up to $_stream@${next.value - 1}, listening for $next',
      );
    } else {
      logger.fine(
        _toMethod('Failed to read from $_stream@${_current}, listening for $_current', [
          _toObject('result', [
            'status: ${result.statusCode}',
            'reason: ${result.reasonPhrase}',
          ]),
        ]),
      );
    }
    // Notify when all actions are done
    if (controller.hasListener) {
      controller.add(result);
    }
  }

  Future<FeedResult> _nextFeed() => connection.getFeed(
        embed: true,
        stream: stream,
        number: current,
        master: _master,
        waitFor: waitFor,
        pageSize: _pageSize,
        direction: Direction.forward,
      );

  void _onFatal(Object error, StackTrace stackTrace) {
    _controller?.addError(error, stackTrace);
    _stopRead();
  }
}

/// User credentials required by event store endpoint
class UserCredentials {
  const UserCredentials({
    this.login,
    this.password,
  });

  static const defaultCredentials = UserCredentials(
    login: 'admin',
    password: 'changeit',
  );

  final String login;
  final String password;

  String get header => "Basic ${base64.encode(utf8.encode("$login:$password"))}";
}

/// Projection command enum
enum ProjectionCommand {
  /// Enable the specified projection.
  ///
  /// When enabling is complete status will be 'Running'
  enable,

  /// Disable the specified projection
  ///
  /// When disabling is complete status will be 'Stopped'
  disable,

  /// Reset the specified projection
  ///
  /// This is an unsafe operation. Any previously emitted
  /// events will be emitted again to the same streams and
  /// handled by their subscribers
  reset,

  /// Abort the specified projection.
  abort,
}

/// EventStore supported consumer strategies for use with persistent subscriptions.
enum ConsumerStrategy {
  /// Distribute events to each client in a
  /// round robin fashion.
  RoundRobin,

//  /// Distributes events to a single client until is
//  /// is full. Then round robin to the next client.
//  DispatchToSingle,
//
//  /// Distribute events of the same streamId to the
//  /// same client until it disconnects on a best efforts
//  /// basis. Designed to be used with indexes such as the
//  /// category projection.
//  Pinned,
}

/// Subscription actions when not accepting consumed events from a subscription
enum SubscriptionAction {
  /// Retry the message on next incoming consumption
  Retry,

//  /// Don't retry the message, park it until a request is sent to reply the parked messages
//  Park,
//
//  /// Discard the message for all consumers
//  Skip,
//
//  /// Stop the subscription for all consumers
//  Stop
}

/// Implements periodic fetch of events from event-store
class _EventStoreSubscriptionControllerImpl {
  _EventStoreSubscriptionControllerImpl(this.connection) : logger = connection._logger {
    _readQueue.catchError((e, stackTrace) {
      logger.severe(
        'Processing fetch requests failed with: $e',
        e,
        Trace.from(stackTrace),
      );
      return true;
    });
  }

  final Logger logger;
  final EventStoreConnection connection;

  int _pageSize;
  int get pageSize => _pageSize;

  String _stream;
  String get stream => _stream;

  String _group;
  String get group => _group;

  Duration _waitFor;
  Duration get waitFor => _waitFor;

  Duration _pullEvery;
  Duration get pullEvery => _pullEvery;

  EventNumber _number;
  EventNumber get number => _number;

  bool _accept;
  bool get accept => _accept;

  EventNumber _current;
  EventNumber get current => _current;

  ConsumerStrategy _strategy;
  ConsumerStrategy get strategy => _strategy;

  StreamController<SourceEvent> _controller;
  StreamController<SourceEvent> get controller => _controller;

  Timer _timer;

  bool _isCatchup;

  bool _isPaused = true;
  FeedResult _pendingFeed;
  ReadResult _pendingResult;

  /// Queue of [_SubscriptionRequest]s executed in FIFO manner.
  ///
  /// This queue ensures that each command is processed in order
  /// waiting for the previous request has completed. This
  /// is need because the [Timer] class will not block on
  /// await in it's callback method.
  final _readQueue = StreamRequestQueue<FeedResult>();

  Stream<SourceEvent> pull({
    @required String stream,
    EventNumber number = EventNumber.last,
    Duration waitFor = defaultWaitFor,
    Duration pullEvery = defaultPullEvery,
  }) {
    // Setup
    _accept = false;
    _stream = stream;
    _number = number;
    _current = number;
    _waitFor = waitFor;
    _pullEvery = pullEvery;

    // catchup before consuming from head of stream?
    _isCatchup = false == number.isLast;

    _controller?.close();
    _controller = StreamController<SourceEvent>(
      onPause: _pauseTimer,
      onCancel: _stopTimer,
      onListen: _startTimer,
      onResume: _startTimer,
    );
    _resume();

    return controller.stream;
  }

  void _resume() {
    _isPaused = false;
    if (_pendingResult != null) {
      _onResult(
        _pendingResult,
        _pendingFeed,
      );
      _pendingFeed = null;
      _pendingResult = null;
    }
  }

  Stream<SourceEvent> consume({
    @required String stream,
    @required String group,
    int pageSize = 20,
    bool accept = true,
    EventNumber number = EventNumber.last,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration pullEvery = defaultPullEvery,
  }) {
    // Setup
    _group = group;
    _stream = stream;
    _accept = accept;
    _number = number;
    _current = number;
    _strategy = strategy;
    _pageSize = pageSize;
    _pullEvery = pullEvery;

    // catchup before consuming from head of stream?
    _isCatchup = false == number.isLast;

    _controller?.close();
    _controller = StreamController<SourceEvent>(
      onPause: _pauseTimer,
      onCancel: _stopTimer,
      onListen: _startTimer,
      onResume: _startTimer,
    );
    _resume();

    return controller.stream;
  }

  void _startTimer() async {
    try {
      logger.fine(
        '${_isPaused ? 'Resumed' : 'Started'} '
        '${_strategy == null ? 'pull' : enumName(_strategy)} subscription on stream: $stream',
      );
      if (_isPaused) {
        _resume();
      } else if (_isCatchup) {
        await _catchup(controller);
        _isCatchup = false;
      }
      _timer?.cancel();
      _timer = Timer.periodic(
        pullEvery,
        (_) {
          // Timer will fire before previous read has completed
          if (_readQueue.isEmpty) {
            _readQueue.add(StreamRequest<FeedResult>(
              tag: '$stream: $stream, number: $current',
              execute: () async {
                final next = await _readNext();
                return queue.StreamResult(
                  value: next,
                  stop: next == null,
                );
              },
            ));
          }
        },
      );
      logger.fine(
        'Listen for events in subscription $name starting from number $_current',
      );
    } catch (error, stackTrace) {
      _onFatal(
        'Failed to start timer for subscription $name, error: $error',
        error,
        stackTrace,
      );
    }
  }

  void _onFatal(String message, Object error, StackTrace stackTrace) {
    _stopTimer();
    controller.addError(error, stackTrace);
  }

  void _pauseTimer() {
    _isPaused = true;

    logger.fine(
      'Paused ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer for $name',
    );
    _timer?.cancel();
    _timer = null;
  }

  void _stopTimer() {
    logger.fine(
      'Stop ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer for $name',
    );
    _timer?.cancel();
    _timer = null;
  }

  Future _catchup(StreamController<SourceEvent> controller) async {
    logger.fine(
      'Subscription $name catching up from number $_number',
    );

    FeedResult feed;
    var fetched = 0;
    do {
      feed = await _readNext();
      fetched = fetched + (feed?.atomFeed?.entries?.length ?? 0);
    } while (feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty));

    if (_number < _current) {
      // This should sum up for pull-subscriptions!
      // If it doesn't something is wrong!
      if (_strategy == null && (_number + fetched + (number.isNone ? 1 : 0)) != _current) {
        throw StateError('$fetched events fetched does not match number change $_number > $_current');
      }
      logger.fine(
        'Subscription $name caught up from $_number to $_current',
      );
    }
    return _current;
  }

  String get name => [stream, if (group != null) group].join('/');

  Future<FeedResult> _readNext() async {
    FeedResult feed;
    try {
      feed = await _nextFeed();
      if (!_isPaused && feed.isNotEmpty) {
        await _readEventsInFeed(feed);
      }
      return _isPaused ? null : feed;
    } catch (e, stackTrace) {
      // Only throw if running
      if (_timer != null && _timer.isActive) {
        _stopTimer();
        controller.addError(e, stackTrace);
        logger.network(
          'Failed to read next events for $name: $e: $stackTrace',
          e,
          stackTrace,
        );
      }
    }
    return feed;
  }

  Future<ReadResult> _readEventsInFeed(FeedResult feed) async {
    if (feed.isOK) {
      final result = await connection.readEventsInFeed(feed);
      if (result.isOK) {
        if (_isPaused) {
          _pendingFeed = feed;
          _pendingResult = result;
        } else if (result.isNotEmpty) {
          await _onResult(result, feed);
        }
      }
      return result;
    }
    return null;
  }

  Future _onResult(ReadResult result, FeedResult feed) async {
    final next = result.number + 1;
    logger.fine(
      'Subscription $name caught up from $_current to ${result.number}, listening for $next',
    );
    _current = next;

    if (accept) {
      await _acceptEvents(feed);
    }
    // Notify when all actions are done
    if (controller.hasListener) {
      result.events.forEach(
        controller.add,
      );
    }
  }

  Future<FeedResult> _nextFeed() {
    if (connection.isClosed) {
      return Future.value(FeedResult(
        stream: stream,
        number: current,
        reasonPhrase: 'Connection is closed',
        statusCode: HttpStatus.connectionClosedWithoutResponse,
      ));
    }
    return strategy == ConsumerStrategy.RoundRobin
        ? connection.getSubscriptionFeed(
            embed: true,
            group: group,
            stream: stream,
            number: current,
            consume: pageSize,
            strategy: strategy,
          )
        : connection.getFeed(
            embed: true,
            stream: stream,
            number: current,
            waitFor: waitFor,
            direction: Direction.forward,
          );
  }

  Future<SubscriptionResult> _acceptEvents(FeedResult feed) async {
    final answer = await connection.writeSubscriptionAckAll(feed);
    if (answer.isAccepted == false) {
      throw SubscriptionFailed(
        'Failed to accept events in for $name: '
        '${answer.statusCode} ${answer.reasonPhrase}',
      );
    }
    return answer;
  }
}

int toNextTimeout(int reconnects, Duration maxBackoffTime, {int exponent = 2}) {
  final wait = min(
    pow(exponent, reconnects++).toInt() + Random().nextInt(1000),
    maxBackoffTime.inMilliseconds,
  );
  return wait;
}

String _toMethod(String name, List<String> args) => '$name(\n  ${args.join(',\n  ')})';
String _toObject(String name, List<String> args) => '$name: {\n  ${args.join(',\n  ')}}';
