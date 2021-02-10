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
        _context = Context(Logger(
          'EventStore[${toCanonical([prefix, aggregate])}][${connection.port}]',
        ));

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

  /// Get [Context] instance for runtime analysis
  Context get context => _context;

  Context _context;
  Context _useContext(Context context) {
    if (_context == null || context == _context) {
      return _context;
    }
    return _context = _context.join(context);
  }

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

  /// Get [Event] position in [canonicalStream]
  int toPosition(Event event) {
    final offset = _snapshot?.number?.position ?? 0;
    final position = _events.keys.toList().indexOf(event.uuid);
    return position > -1 ? offset + position + 1 : -1;
  }

  /// Get event metadata as json
  Map<String, dynamic> toJsonEvent(
    Event event, {
    bool patches = false,
  }) {
    return <String, dynamic>{
      'uuid': event?.uuid,
      'type': '${event?.type}',
      'number': '${event?.number}',
      'remote': '${event?.remote}',
      'position': '${toPosition(event)}',
      'timestamp': event?.created?.toIso8601String(),
      if (patches) 'patches': event?.patches,
    };
  }

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

  /// Get number of last event in stream
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
  EventNumber last({String stream, String uuid}) {
    return _toNumber(stream, uuid, (events) => events.last.number);
  }

  /// Get number of first event in store
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
  EventNumber first({String stream, String uuid}) {
    return _toNumber(stream, uuid, (events) => events.first.number);
  }

  EventNumber _toNumber(
    String stream,
    String uuid,
    EventNumber Function(Iterable<SourceEvent>) lookup,
  ) {
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
            return lookup(_aggregates[uuid]);
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
    final first = _snapshot.isPartial
        // Start from position of event in first partial snapshot
        ? EventNumber(_snapshot.tail)
        // Start from position of last event in snapshot
        : _snapshot.number.toPosition();
    // Adjust for each aggregate snapshot event
    return first + _events.keys.length - _snapshot.aggregates.length;
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
    Context context,
    bool strict = true,
    bool master = false,
    List<String> uuids = const [],
  }) async {
    var count = 0;
    final startTime = DateTime.now();

    // Sanity checks
    _assertState();
    _assertRepo(repo);

    context = _useContext(context);

    try {
      // Stop subscriptions
      // from catching up
      pause();

      bus.replayStarted<T>();

      // Reset to
      await reset(
        repo,
        uuids: uuids,
        strict: strict,
        // Always replay from last snapshot if not given
        suuid: suuid ?? snapshots?.last?.uuid,
      );

      // Check state after reset
      final isPartial = repo.hasSnapshot && repo.snapshot.isPartial;
      final snapshot = repo.hasSnapshot ? (repo.snapshot.isPartial ? '(partial snapshot) ' : '(snapshot) ') : '';
      if (isPartial) {
        uuids += repo.snapshot.aggregates.keys.toList();
      }

      context.info(
        "Replay events on ${uuids.isEmpty ? 'all' : uuids.length} ${repo.aggregateType}s $snapshot",
        category: 'EventStore.replay',
      );

      // Catchup on instance streams first?
      if (uuids.isNotEmpty && useInstanceStreams) {
        for (var uuid in uuids) {
          if (_isDisposed) break;
          final tic = DateTime.now();
          final offset = repo.hasSnapshot
              // Start from next event in
              // instance stream after
              // event stored in snapshot
              ? (repo.snapshot.aggregates[uuid]?.number?.toNumber() ?? EventNumber.none) + 1
              : EventNumber.first;

          final stream = toInstanceStream(uuid);
          final events = await _catchup(
            repo,
            offset: offset,
            strict: strict,
            stream: stream,
            context: context,
          );
          context.info(
            "Replayed $events events from stream '$stream' with offset ${offset.value} $snapshot"
            'in ${DateTime.now().difference(tic).inMilliseconds} ms',
            category: 'EventStore.replay',
          );
          count += events;
        }
      }

      var streams = uuids.length;

      if (!_isDisposed && uuids.isEmpty) {
        final tic = DateTime.now();

        final offset = repo.hasSnapshot
            ? repo.snapshot.isPartial
                // Start from position of event in first partial snapshot
                ? EventNumber(repo.snapshot.tail) + 1
                // Start from position of last event in snapshot
                : repo.snapshot.number.toPosition() + 1
            // Start from first event in canonical stream
            : EventNumber.first;

        // Fetch all events from canonical stream
        final events = await _catchup(
          repo,
          strict: strict,
          master: master,
          offset: offset,
          context: context,
          stream: canonicalStream,
        );
        context.info(
          "Replayed $events events from stream '${canonicalStream}' with offset ${offset.value} $snapshot"
          'in ${DateTime.now().difference(tic).inMilliseconds} ms',
          category: 'EventStore.replay',
        );

        streams += 1;
        count += events;
      }
      if ((isPartial || uuids.isNotEmpty) && useInstanceStreams) {
        context.info(
          'Replayed $count events from $streams streams $snapshot'
          'in ${DateTime.now().difference(startTime).inMilliseconds} ms',
          category: 'EventStore.replay',
        );
      }

      return count;
    } finally {
      bus.replayEnded<T>();
      resume();
    }
  }

  /// Reset repository to remote state.
  /// This remove will all local changes.
  Future<Map<String, EventNumber>> reset(
    Repository repo, {
    String suuid,
    Context context,
    bool strict = true,
    List<String> uuids = const [],
  }) async {
    final numbers = <String, EventNumber>{};
    final hasSnapshot = await repo.reset(
      uuids: uuids,
      suuid: suuid,
      context: context,
    );
    context = _useContext(context);
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
    Context context,
    bool strict = true,
    List<String> uuids = const [],
  }) {
    final numbers = <String, EventNumber>{};
    if (repo.hasSnapshot && _snapshot?.uuid != repo.snapshot.uuid) {
      _snapshot = repo.snapshot;
      final existing = _snapshot.aggregates.keys.toList();
      final keep = uuids.isNotEmpty ? uuids : repo.snapshot.aggregates.keys;
      final base = existing..retainWhere((uuid) => keep.contains(uuid));
      context = _useContext(context);
      // Purge events in store
      // first to ensure that
      // subscription offsets
      // are calculated
      // correctly later on
      _purge(
        repo,
        base,
        numbers,
        remote: false,
        strict: strict,
      );
      repo.purge(
        uuids: uuids,
        context: context,
      );
    }
    return numbers;
  }

  int _purge(
    Repository repo,
    Iterable<String> base,
    Map<String, EventNumber> numbers, {
    @required bool remote,
    @required bool strict,
  }) {
    var count = 0;
    final snapshot = repo.snapshot;
    for (var uuid in base) {
      final stream = toInstanceStream(uuid);
      // Remove events before
      // ignore: prefer_collection_literals
      final events = _aggregates[uuid] ?? LinkedHashSet<SourceEvent>();
      if (snapshot != null) {
        final aggregate = snapshot.aggregates[uuid];
        final first = aggregate?.number?.toNumber();
        if (first != null) {
          // Remove all events before snapshot?
          final before = events.where((e) => e.number < first).toList();
          before.forEach((e) {
            if (_events.remove(e.uuid) != null) {
              count++;
            }
            events.remove(e);
          });
          if (events.isEmpty) {
            final e = aggregate.deletedBy ?? aggregate.changedBy;
            events.add(SourceEvent(
              data: e.data,
              type: e.type,
              uuid: e.uuid,
              local: e.local,
              streamId: stream,
              number: e.number,
              created: e.created,
            ));
            _events[e.uuid] = uuid;
          }
        }
      }

      // Ensure list of events exists
      _aggregates[uuid] = events;

      final offset = _toStreamOffset(
        repo,
        stream: stream,
      );
      numbers[uuid] = offset;
    }
    return count;
  }

  /// Tainted aggregates.
  Map<String, Object> get tainted => Map.unmodifiable(_tainted);
  final _tainted = <String, dynamic>{};

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
  void taint(
    Repository repo,
    String uuid, {
    @required Object reason,
    Context context,
  }) {
    _assertRepo(repo);
    _tainted[uuid] = reason is ContextEvent ? reason.toJson() : toJsonSafe(reason);
    (context ?? _context).error(
      'Tainted ${repo.aggregateType} $uuid',
      error: _tainted[uuid],
      stackTrace: StackTrace.current,
      category: 'EventStore.taint',
    );
  }

  bool untaint(String uuid) {
    return _tainted.remove(uuid) != null;
  }

  /// Cordoned aggregates.
  Map<String, Object> get cordoned => Map.unmodifiable(_cordoned);
  final _cordoned = <String, dynamic>{};

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
  void cordon(
    Repository repo,
    String uuid, {
    @required Object reason,
    Context context,
  }) {
    _assertRepo(repo);
    _tainted.remove(uuid);
    _cordoned[uuid] = reason is ContextEvent ? reason.toJson() : toJsonSafe(reason);

    (context ?? _context).error(
      'Cordoned ${repo.aggregateType} $uuid',
      category: 'EventStore.cordon',
      error: _cordoned[uuid],
      stackTrace: StackTrace.current,
    );
  }

  bool uncordon(String uuid) {
    return _cordoned.remove(uuid) != null;
  }

  /// Analyze repository state for errors.
  ///
  /// Returns list of [AnalyzeResult] per aggregate.
  ///
  /// If errors was found, result should be passed to [repair]
  ///
  Future<Map<String, AnalyzeResult>> analyze(
    Repository repo, {
    Context context,
    bool master = false,
  }) async {
    _assertRepo(repo);
    context = _useContext(context);
    const pageSize = 5;
    final tic = DateTime.now();
    final analysis = <String, AnalyzeResult>{};
    for (var uuid in _aggregates.keys) {
      final stream = toInstanceStream(uuid);

      // Read page of events
      final result = await connection.readEvents(
        embed: true,
        stream: stream,
        master: master,
        pageSize: pageSize,
      );

      if (!_isDisposed) {
        analysis[uuid] = _onAnalyze(
          result,
          repo,
          uuid,
          pageSize,
        );

        context.log(
          analysis[uuid].isValid ? ContextLevel.debug : ContextLevel.warning,
          'Analyzed ${result.events.length} events: '
          '${analysis[uuid].toSummaryText()}',
          category: 'EventStore.analyse',
        );
      }

      if (_isDisposed) break;
    }

    final wrong = analysis.values.where((a) => a.isWrongStream).length;
    final multiple = analysis.values.where((a) => a.isMultipleAggregates).length;
    final invalid = wrong > 0 || multiple > 0;
    final message = 'Analyzed ${analysis.length} aggregates '
        'in ${DateTime.now().difference(tic).inMilliseconds} ms';
    if (invalid) {
      context.warning(
        Context.toObject(message, [
          'has $wrong aggregates with wrong stream',
          'has $multiple streams with multiple aggregates',
        ]),
        data: {
          'aggregate': '${repo.aggregateType}',
          'repository': '${repo.runtimeType}',
        },
        category: 'EventStore.analyse',
      );
    } else {
      context.info(
        message,
        category: 'EventStore.analyse',
      );
    }

    return analysis;
  }

  AnalyzeResult _onAnalyze(ReadResult result, Repository repo, String uuid, int pageSize) {
    if (result.isOK) {
      // Group events by aggregate uuid
      final eventsPerAggregate = groupBy<SourceEvent, String>(
        result.events,
        (event) => repo.toAggregateUuid(event),
      );
      return AnalyzeResult(
        uuid,
        result.stream,
        events: eventsPerAggregate,
        count: result.events.length,
        statusCode: result.statusCode,
        reasonPhrase: result.reasonPhrase,
        streams: Map.from(
          eventsPerAggregate.map((uuid, _) => MapEntry(uuid, toInstanceStream(uuid))),
        ),
      );
    }
    return AnalyzeResult(
      uuid,
      result.stream,
      statusCode: result.statusCode,
      reasonPhrase: result.reasonPhrase,
    );
  }

  /// Reorder aggregates with streams
  void reorder(Iterable<String> uuids) {
    final unknown = _aggregates.keys.where((uuid) => !uuids.contains(uuid)).toList();
    if (unknown.isNotEmpty) {
      throw AggregateNotFound('Aggregates not found: $unknown');
    }
    final next = LinkedHashMap<String, LinkedHashSet<SourceEvent>>(); // ignore: prefer_collection_literals
    for (var uuid in uuids) {
      next[uuid] = _aggregates[uuid];
    }
    _aggregates.clear();
    _aggregates.addAll(next);
    _context.info(
      'Reordered ${uuids.length} aggregate streams',
      data: {
        'uuids': '$uuids',
      },
      category: 'EventStore.reorder',
    );
  }

  Future<int> _readAllEvents(
    String stream, {
    Context context,
    @required bool master,
    @required EventNumber offset,
    @required void Function(ReadResult) onResult,
    int pageSize = 20,
  }) async {
    var count = 0;
    final events = connection.readEventsAsStream(
      stream: stream,
      number: offset,
      master: master,
      pageSize: pageSize,
    );

    // Process results as they arrive
    final completer = Completer();
    final subscription = events.listen(
      (result) {
        if (!isDisposed) {
          try {
            onResult(result);
            if (result.isOK) {
              count += result.events.length;
            }
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      // Handle errors from connection
      onError: (Object error, StackTrace stackTrace) {
        completer.completeError(error, stackTrace);
        context.error(
          'Failed to process events from $stream@$offset',
          data: {'cause': 'unknown'}..addAll(toDebugData(stream)),
          error: error,
          stackTrace: stackTrace,
          category: 'EventStore._readAllEvents',
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
            // Do not fail! Error handling
            // will skip events automatically
            strict: false,
            createNew: false,
          )
          ?.headEvent;
      if (head != null) {
        return head.number;
      }
    }
    return last(stream: stream);
  }

  /// Catch up with streams.
  /// If [useInstanceStreams] is
  /// true, use [uuids] to only
  /// catchup to instance streams
  /// for given [AggregateRoot.uuid].
  ///
  Future<int> catchup(
    Repository repo, {
    Context context,
    bool strict = true,
    bool master = false,
    List<String> uuids = const [],
  }) async {
    try {
      var count = 0;
      final streams = _toStreams(uuids);

      context = _useContext(context);
      context.info(
        "Catchup events on ${uuids.isEmpty ? 'all' : uuids.length} ${repo.aggregateType}s",
        category: 'EventStore.catchup',
      );

      // Stop subscriptions
      // from catching up
      pause();

      // Catchup to given streams
      for (var stream in streams) {
        final previous = last(stream: stream);
        final offset = _toStreamOffset(repo, stream: stream);
        final events = await _catchup(
          repo,
          offset: offset,
          stream: stream,
          strict: strict,
          master: master,
          context: context,
        );
        if (_isDisposed) break;
        final next = last(stream: stream);
        if (events > 0) {
          context.info(
            'Caught up $events events from $stream@$offset to $stream@$next',
            category: 'EventStore.catchup',
            data: {
              'number.previous': '$previous',
              'number.offset': '$offset',
              'number.next': '$next',
            },
          );
        } else {
          context.info(
            'Local stream $stream is at same event number as remote stream ($previous)',
            category: 'EventStore.catchup',
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
    Context context,
    @required bool strict,
    @required String stream,
    @required EventNumber offset,
    bool master = false,
  }) {
    if (isDisposed) {
      return Future.value(0);
    }
    assert(context != null, 'context must be given');
    assert(isPaused, 'subscriptions must be paused');

    final uuid = toAggregateUuid(stream);
    context.debug(
      'Catchup on events from $stream@$offset',
      data: {
        'stream.id': '$stream',
        'aggregate.uuid': '$uuid',
        'stream.number.offset': '$offset',
        'stream.number.current': '${last(stream: stream)}',
      },
      category: 'EventStore._catchUp',
    );

    return _readAllEvents(
      stream,
      master: master,
      offset: offset,
      context: context,
      onResult: (result) => _onRead(
        context,
        result,
        repo,
        strict: strict,
      ),
    );
  }

  void _onRead(
    Context context,
    ReadResult result,
    Repository repo, {
    @required bool strict,
  }) {
    if (result.isOK) {
      context = _useContext(context);
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

      // Free up memory
      snapshotWhen(repo);
    }
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
    final remote = last(stream: stream);
    final offset = first(uuid: uuid);
    var previous = remote;

    final sourced = _aggregates.putIfAbsent(
      uuid,
      () => LinkedHashSet<SourceEvent>(),
    );

    // Only apply events with event
    // number equal to or higher than first
    // event in store for each stream. This
    // prevents events being added again
    // during replay that was purged earlier
    // on save.
    //
    for (var event in events.where((e) => e.number >= offset)) {
      if (strict) {
        // Only check local events (remote
        // events are guaranteed to always have
        // monotone increasing event numbers)
        //
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
          //
          if (event.number <= remote) {
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
          if (prev.local) {
            // Workaround for LinkedHashSet
            // will not change when equal
            // event is added (equality is
            // made on type and uuid only)
            prev.created = event.created;
            prev.remote = true;
          }
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

  /// Get unmodifiable list of events for given [AggregateRoot.uuid]
  Iterable<SourceEvent> get(String uuid) => List.unmodifiable(_aggregates[uuid] ?? {});

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
  /// If [allowUpdates] is false, all subscriptions are
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
    Context context,
    bool allowUpdates = true,
    String uuidFieldName = 'uuid',
  }) async {
    _assertState();
    if (changes.isEmpty) {
      return [];
    }
    context = _useContext(context);

    final stream = toInstanceStream(uuid);
    final offset = last(stream: stream);
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
      context.debug(
        'Wrote ${result.events.length} to $stream@${result.expected}',
        data: {
          'stream.id': '$stream',
          'stream.number.expected': '$version',
          'stream.number.actual': '${result.actual}',
          'aggregate.uuid': '$uuid',
          'aggregate.written.count': '${changes.length}',
          'event.number.first': '${changes.first.type}@${changes.first.number}',
          'event.number.last': '${changes.last.type}@${changes.last.number}',
          'response.statusCode': '${result.statusCode}',
          'response.reasonPhrase': '${result.reasonPhrase}'
        },
        category: 'EventStore.writeEvents',
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
          context,
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
    final number = last(stream: stream) ?? EventNumber.none;
    return number.isNone ? ExpectedVersion.none : ExpectedVersion.from(number);
  }

  /// Subscription controller for each repository
  /// subscribing to events from [canonicalStream]
  /// TODO: Really not needed as there is a 1-to-1 relationship between repo and store
  final _controllers = <Type, EventStoreSubscriptionController>{};

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
    _assertRepo(repo);

    // Dispose current subscription if exists
    _controllers[repo.runtimeType]?.cancel();

    // Get existing or create new
    final controller = _subscribe(
      // _context.append(context ?? _context),
      _controllers[repo.runtimeType] ??
          EventStoreSubscriptionController(
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
    _assertRepo(repository);

    // Dispose current subscription if exists
    _controllers[repository.runtimeType]?.cancel();

    // Get existing or create new
    final controller = _subscribe(
      // _context.append(context ?? _context),
      _controllers[repository.runtimeType] ??
          EventStoreSubscriptionController(
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

  EventStoreSubscriptionController _subscribe(
    EventStoreSubscriptionController controller,
    Repository repo, {
    int consume = 20,
    bool competing = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) {
    assert(context != null, 'context must be given');
    // Get next event in stream
    final number = repo.store._toStreamOffset(
      repo,
      stream: canonicalStream,
    );
    return competing
        ? controller.compete(
            repo,
            number: number,
            consume: consume,
            strategy: strategy,
            stream: canonicalStream,
            group: '${repo.aggregateType}',
          )
        : controller.subscribe(
            repo,
            number: number,
            stream: canonicalStream,
          );
  }

  /// Handle event from subscriptions
  void _onSubscriptionEvent(Context context, Repository repo, SourceEvent event) {
    // In case paused after events
    // are sent from controller
    if (_shouldSkipEvents) {
      context.debug(
        'Skipping ${event.type}@${event.number} ',
        category: 'EventStore._onSubscriptionEvent',
        data: {
          'reason': isPaused ? Context.toObject('is paused', ['count: $_paused']) : 'is disposed',
        },
      );
      return;
    }

    final uuid = repo.toAggregateUuid(event);
    final actual = last(uuid: uuid);
    final stream = toInstanceStream(uuid);

    try {
      // Event is already applied to aggregate?
      // Since catchup is performed on get, this
      // test must be applied before event is added
      // to eventstore.
      final isApplied = repo.isApplied(event);

      // IMPORTANT: Add to eventstore before
      // applying to repository! This ensures
      // that the local event added to an
      // aggregate during construction is
      // overwritten with the remote event
      // actual received here.
      _updateAll(
        uuid,
        repo.uuidFieldName,
        [event],
        // Bubble up exceptions
        strict: true,
      );

      context.debug(
        isApplied
            ? 'Apply ${event.type}@${event.number} to ${repo.aggregateType} ${uuid}'
            : 'Replace ${event.type}@${event.number} in ${repo.aggregateType} ${uuid}',
        data: {
          'aggregate.uuid': '$uuid',
          'aggregate.stream': '$stream',
          'event.uuid': '${event.uuid}',
          'event.number': '${event.number}',
          'event.remote': '${event.remote}',
          'event.sourced': '${_isSourced(uuid, event)}',
          'store.aggregate.number': '$actual',
        },
        category: 'EventStore._onSubscriptionEvent',
      );

      // Do not apply when subscriptions are suspended
      final allowAnyUpdates = !isPaused;

      // Do not apply event on aggregate
      // if an transaction exists for it
      final allowTrxUpdates = !repo.inTransaction(uuid);

      if (isApplied || allowAnyUpdates && allowTrxUpdates) {
        // Get domain event before applying it
        // This ensures that event contains
        // previous equals head before it
        // is applied.
        final domainEvent = repo.toDomainEvent(event);

        // Catch up with stream
        final aggregate = repo.get(uuid, context: context);

        if (isApplied) {
          // Field 'created' is not stable until it is
          // written to EventStore. This method  will
          // apply event to aggregate which in turn
          // calls method _setModifiers in AggregateRoot,
          // overwriting fields _createdBy and _changedBy
          // ensuring that the local 'created' value is
          // replaced with the stable value.
          aggregate.apply(domainEvent);
        }

        // Publish remotely created events.
        // Handlers can determine events with
        // local origin with field 'local'.
        // Deleted data is found in field 'previous'.
        publish([domainEvent]);

        context.debug(
          'Handled ${event.type}@${event.number} in ${repo.aggregateType} ${uuid}',
          data: {
            'event.type': '${event.type}',
            'event.uuid': '${event.uuid}',
            'event.number': '${event.number}',
            'event.remote': '${event.remote}',
            'event.sourced': '${_isSourced(uuid, event)}',
            'event.applied': '$isApplied',
            'event.patches': '${event?.patches?.length}',
            'event.previous': '${domainEvent?.previous?.length}',
            'aggregate.uuid': '$uuid',
            'aggregate.stream': '$stream',
            'aggregate.number': '${aggregate.number}',
            'aggregate.applied': '${aggregate?.applied?.length}',
            'aggregate.skipped': '${aggregate?.skipped?.length}',
            'aggregate.tainted': '${repo.store.isTainted(uuid)}',
            'aggregate.cordoned': '${repo.store.isCordoned(uuid)}',
            'aggregate.modification': '${aggregate.modifications}',
            'aggregate.snapshot.number': '${aggregate.snapshot?.number}',
          },
          category: 'EventStore._onSubscriptionEvent',
        );
      }
    } finally {
      snapshotWhen(repo);
    }
  }

  bool _isSourced(String uuid, SourceEvent event) {
    return _aggregates.containsKey(uuid) && _aggregates[uuid].contains(event);
  }

  /// Handle subscription completed
  void _onSubscriptionDone(Context context, Repository repo) {
    context.debug(
      '${repo.runtimeType}: subscription closed',
      category: 'EventStore._onSubscriptionDone',
    );
    if (!_isDisposed) {
      _controllers[repo.runtimeType].reconnect();
    }
  }

  /// Handle subscription errors
  void _onSubscriptionError(Context context, Repository repository, Object error, StackTrace stackTrace) {
    _onFatal(
      context,
      '${repository.runtimeType} subscription failed',
      error,
      stackTrace,
    );
    if (!_isDisposed) {
      _controllers[repository.runtimeType].reconnect();
    }
  }

  void _onFatal(Context context, String message, Object error, StackTrace stackTrace) {
    context.error(
      message,
      error: error,
      stackTrace: stackTrace,
      category: 'EventStore._onFatal',
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

  /// Assert that this this [EventStore] is managed by [repo]
  void _assertRepo(Repository repo) {
    if (repo.store != this) {
      throw InvalidOperation('This $this is not managed by ${repo.runtimeType}');
    }
  }

  /// Assert that current event number for [stream] is caught up with last known event
  void _assertCurrentVersion(Context context, String stream, EventNumber actual, {String reason = 'Catch up failed'}) {
    final number = last(stream: stream);
    if (number != actual) {
      final stackTrace = StackTrace.current;
      final error = EventNumberMismatch(
        stream: stream,
        actual: actual,
        message: reason,
        current: last(stream: stream),
      );
      context.error(
        error.message,
        data: toDebugData(stream),
        error: error,
        stackTrace: stackTrace,
        category: 'EventStore._assertCurrentVersion',
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
    if (context.isLoggable(ContextLevel.debug)) {
      final trace = Trace.current(1);
      final callee = trace.frames.first;
      context.debug(
        Context.toObject('Paused $runtimeType', [
          'paused: $_paused',
          'callee: ${callee}',
        ]),
        category: 'EventStore.pause',
      );
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
                  controller.repo,
                  consume: controller.consume,
                  strategy: controller.strategy,
                  maxBackoffTime: controller.maxBackoffTime,
                );
              } else {
                controller = subscribe(
                  controller.repo,
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
    if (context.isLoggable(ContextLevel.debug)) {
      final trace = Trace.current(1);
      final callee = trace.frames.first;
      context.debug(
        Context.toObject('Resumed $runtimeType', [
          'paused: $_paused',
          'callee: ${callee}',
        ]),
        category: 'EventStore.resume',
      );
    }
    return numbers;
  }

  bool _shouldRestart(EventStoreSubscriptionController controller) {
    final number = controller.current;
    final actual = last();
    final diff = actual.value - number.value;
    if (diff > 0) {
      context.debug(
        'Subscription on ${controller.repo.aggregateType} is behind '
        '(last: $number, actual: $actual, diff: $diff) > restarting',
        category: 'EventStore._shouldRestart',
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
    } on ClientException catch (error, stackTrace) {
      _context.error(
        'Failed to dispose one or more subscriptions with error: $error',
        error: error,
        stackTrace: stackTrace,
        category: 'EventStore.dispose',
      );
    }

    _controllers.clear();
    if (_streamController?.hasListener == true && _streamController?.isClosed == false) {
      // See https://github.com/dart-lang/sdk/issues/19095#issuecomment-108436560
      // ignore: unawaited_futures
      _streamController.close();
    }
  }

  Map<String, String> toDebugData([String stream]) {
    final uuid = _aggregates.keys.firstWhere(
      (uuid) => toInstanceStream(uuid) == stream,
      orElse: () => 'not found',
    );
    return {
      'aggregate.uuid': '$uuid',
      'aggregate.stream': '$stream',
      'aggregate.stream.canonical': '$canonicalStream',
      'aggregate.tainted': '${isTainted(uuid)}',
      'aggregate.cordoned': '${isCordoned(uuid)}',
      'store.events.count': '${_events.length}',
      'store.aggregates.count': '${_aggregates.length}',
    };
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
  bool hasSubscription(Repository repository) => _controllers[repository.runtimeType]?.isOK != false;

  /// Get [EventStoreSubscriptionController] for given [repository]
  EventStoreSubscriptionController getSubscription(Repository repository) => _controllers[repository.runtimeType];
}

class AnalyzeResult {
  AnalyzeResult(
    this.uuid,
    this.stream, {
    @required this.statusCode,
    @required this.reasonPhrase,
    this.events,
    this.streams,
    this.count = 0,
  });

  /// Total number of [SourceEvent]s in [events]
  final int count;

  /// AggregateRoot.uuid] expected to be found in [stream]
  final String uuid;

  /// Stream analyzed
  final String stream;

  final int statusCode;
  final String reasonPhrase;

  /// Current stream for each [AggregateRoot.uuid] found in [stream]
  final Map<String, String> streams;

  /// Events found for each [AggregateRoot.uuid]
  final Map<String, List<SourceEvent>> events;

  bool get isInvalid => !isValid;
  bool get isNotFound => streams == null;
  bool get isEmpty => !isNotFound && streams.isEmpty;
  bool get isValid => !isEmpty && uuid == streams.keys.firstOrNull;
  bool get isWrongStream => isInvalid && !isEmpty && streams.length == 1;
  bool get isMultipleAggregates => isInvalid && !isEmpty && streams.length > 1;

  String toSummaryText() {
    if (isValid) {
      return '$stream is valid';
    }
    if (isNotFound) {
      return '$stream not found';
    }
    if (isEmpty) {
      return '$stream is empty';
    }
    if (isWrongStream) {
      return '$stream does not contains $uuid';
    }
    if (isWrongStream) {
      return '$stream contains ${streams.length} aggregates';
    }
    return '$stream is invalid: $statusCode $reasonPhrase';
  }
}

/// Class for handling a subscription with automatic reconnection on failures
class EventStoreSubscriptionController<T extends Repository> {
  EventStoreSubscriptionController({
    @required this.onEvent,
    @required this.onDone,
    @required this.onError,
    this.maxBackoffTime = const Duration(seconds: 10),
  });

  final void Function(Context context, T repository) onDone;
  final void Function(Context context, T repository, SourceEvent event) onEvent;
  final void Function(Context context, T repository, Object error, StackTrace stackTrace) onError;

  /// Maximum backoff duration between reconnect attempts
  final Duration maxBackoffTime;

  /// [SourceEventHandler] instance
  SourceEventHandler _handler;

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
  T get repo => _repo;
  T _repo;

  /// [Context] instance
  Context get context => _repo.store.context;

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
    T repo, {
    @required String stream,
    EventNumber number = EventNumber.first,
  }) {
    _reset();

    _repo = repo;
    _offset = number;

    // Handle events from stream
    _listen(repo.store.connection.subscribe(
      stream: stream,
      number: number,
    ));

    context.debug(
      '${repo.runtimeType} > Subscribed to $stream@$number',
      category: 'EventStoreSubscriptionController.subscribe',
    );
    return this;
  }

  /// Compete for events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  EventStoreSubscriptionController<T> compete(
    T repo, {
    @required String stream,
    @required String group,
    int consume = 20,
    EventNumber number = EventNumber.first,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) {
    _reset();

    _repo = repo;
    _group = group;
    _offset = number;
    _competing = true;
    _consume = consume;
    _strategy = strategy;

    // Handle events from stream
    _listen(repo.store.connection.compete(
      stream: stream,
      group: group,
      number: number,
      consume: consume,
      strategy: strategy,
    ));

    context.debug(
      '${repo.runtimeType} > Competing from $stream@$number',
      category: 'EventStoreSubscriptionController.compete',
    );
    return this;
  }

  void _reset() {
    cancel();
    _timer?.cancel();
    _handler?.cancel();
    _group = null;
    _processed = 0;
    _consume = null;
    _strategy = null;
    _isCancelled = false;
  }

  void _listen(Stream<SourceEvent> events) async {
    assert(
      _handler?.isCancelled != false,
      'Handler must be cancelled',
    );

    _handler = SourceEventHandler(context);
    _handler.listen(
      _repo,
      events,
      onEvent: (SourceEvent event) {
        _alive(_repo, event);
        onEvent(context, _repo, event);
      },
      onPause: () => _timer?.cancel(),
      onDone: () => onDone(context, _repo),
      onFatal: (event) {
        // Was unable to handle error
        cancel();
      },
      onError: (error, StackTrace stackTrace) => onError(
        context,
        _repo,
        error,
        stackTrace,
      ),
    );
  }

  Future _retry() async {
    try {
      _timer.cancel();
      _timer = null;
      context.info(
        '${_repo.runtimeType}: SubscriptionController is '
        'reconnecting to stream ${repo.store.canonicalStream}, attempt: $reconnects',
        category: 'EventStoreSubscriptionController._retry',
      );
      await _restart();
    } catch (e, stackTrace) {
      context.error(
        'Failed to reconnect: $e: $stackTrace',
        error: e,
        stackTrace: stackTrace,
        category: 'EventStoreSubscriptionController._retry',
      );
    }
  }

  Future _restart() async {
    await _handler?.cancel();
    if (_competing) {
      final controller = await _repo.store.compete(
        _repo,
        consume: _consume,
        strategy: _strategy,
        maxBackoffTime: maxBackoffTime,
      );
      _handler = controller._handler;
    } else {
      final controller = await repo.store.subscribe(
        _repo,
        maxBackoffTime: maxBackoffTime,
      );
      _handler = controller._handler;
    }
  }

  int toNextReconnectMillis() {
    final wait = toNextTimeout(reconnects++, maxBackoffTime);
    context.info(
      'Wait ${wait}ms before reconnecting (attempt: $reconnects)',
      category: 'EventStoreSubscriptionController.toNextReconnectMillis',
    );
    return wait;
  }

  void reconnect() async {
    if (!_repo.store.connection.isClosed) {
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
      context.info(
        '${repository.runtimeType} reconnected to '
        "'${connection.host}:${connection.port}' after ${reconnects} attempts",
        category: 'EventStoreSubscriptionController._alive',
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

    _repo = null;
    _isCancelled = true;

    return _handler?.cancel();
  }

  bool get isOK => !_isCancelled;
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;
}

class SourceEventHandler {
  SourceEventHandler(this.context);

  final Context context;

  void Function() _onPause;
  void Function() _onResume;
  void Function(SourceEvent event) _onFatal;

  /// Underlying stream subscription
  StreamSubscription<SourceEvent> _subscription;

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
    Stream<SourceEvent> stream, {
    @required Function(SourceEvent event) onEvent,
    void Function() onDone,
    void Function() onPause,
    void Function() onResume,
    void Function(SourceEvent event) onFatal,
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
    Function(SourceEvent event) onEvent,
    SourceEvent event,
    Repository repo,
  ) async {
    try {
      onEvent(event);
    } catch (error) {
      final uuid = repo.toAggregateUuid(event);
      if (SourceEventErrorHandler.isHandling(error)) {
        // Use internal error handler
        repo.get(uuid, strict: false);
        return;
      }
      rethrow;
    }
  }
}

class SourceEventErrorHandler {
  SourceEventErrorHandler(
    this.context, {
    void Function(SourceEvent event) onFatal,
  }) : _onFatal = onFatal;

  factory SourceEventErrorHandler.fromRepo(
    Repository repo, {
    Context context,
  }) =>
      SourceEventErrorHandler(context ?? repo.context);

  factory SourceEventErrorHandler.fromHandler(
    SourceEventHandler handler,
  ) =>
      SourceEventErrorHandler(
        handler.context,
        onFatal: handler._onFatal,
      );

  final Context context;
  final void Function(SourceEvent) _onFatal;

  bool handle(
    SourceEvent event, {
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
    SourceEvent event, {
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
      cause: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      data: {
        'error.number.delta': '${error.delta}',
        'error.number.actual': '${error.actual}',
        'error.number.expected': '${error.expected}',
      },
      error: 'Failed to apply ${event.type}@${event.number} on ${repo.aggregateType} $uuid',
    );
  }

  void handleEventNumberNotStrictMonotone(
    SourceEvent event, {
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
      cause: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      data: {
        'mode': '${error.mode}',
        'error.number.delta': '${error.delta}',
        'error.number.actual': '${error.actual}',
        'error.number.expected': '${error.expected}',
      },
      error: 'Failed to apply ${event.type}@${event.number} on ${repo.aggregateType} $uuid',
    );
  }

  void handleJsonPatchError(
    SourceEvent event, {
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
      cause: error,
      aggregate: aggregate,
      stackTrace: Trace.from(stackTrace),
      error: 'Failed to apply ${event.type}@${event.number} on ${repo.aggregateType} ${aggregate.uuid}',
    );
  }

  void handleFatal(
    SourceEvent event, {
    @required Object error,
    @required Repository repo,
    String message,
    StackTrace stackTrace,
    Map<String, String> data,
  }) {
    final store = repo.store;
    final uuid = repo.toAggregateUuid(event);
    final aggregate = repo.get(
      uuid,
      strict: false,
      createNew: false,
    );

    final reason = context.error(
      message,
      data: {'resolution': 'cordon ${repo.aggregateType} $uuid'}
        ..addAll(data)
        ..addAll(toDebugData(event, repo, aggregate)),
      category: 'SourceEventErrorHandler._handle',
      error: error,
      stackTrace: stackTrace,
    );

    store.cordon(
      repo,
      uuid,
      reason: reason,
      context: context,
    );

    if (_onFatal != null) {
      _onFatal(event);
    }
  }

  void _handle(
    SourceEvent event, {
    @required bool skip,
    @required bool fatal,
    @required Object cause,
    @required Object error,
    @required Repository repo,
    @required Trace stackTrace,
    @required AggregateRoot aggregate,
    Map<String, String> data = const {},
  }) {
    final store = repo.store;
    final uuid = aggregate.uuid;

    var reason = cause;

    // Apply it safely by skip patching?
    if (skip) {
      _onSkip(event, repo, aggregate);
      reason = context.error(
        '$cause',
        error: error,
        stackTrace: stackTrace,
        category: 'SourceEventErrorHandler._handle',
        data: {'resolution': 'event skipped'}..addAll(data)..addAll(toDebugData(event, repo, aggregate)),
      );
    }

    // Should skip event only?
    if (store.isCordoned(uuid)) {
      return;
    }

    if (fatal || store.isTainted(uuid)) {
      store.cordon(
        repo,
        uuid,
        reason: reason,
        context: context,
      );
    } else {
      store.taint(
        repo,
        uuid,
        reason: reason,
        context: context,
      );
    }
  }

  void _onSkip(SourceEvent event, Repository repo, AggregateRoot aggregate) {
    aggregate.apply(
      repo.toDomainEvent(
        event,
        strict: false,
      ),
      skip: true,
    );
  }

  static bool isHandling(Object error) => error is JsonPatchError || error is EventNumberNotStrictMonotone;

  Map<String, String> toDebugData(SourceEvent event, Repository repo, AggregateRoot aggregate) {
    final uuid = aggregate?.uuid;
    return {
      'event.type': '${event.type}',
      'event.uuid': '${event.uuid}',
      'event.number': '${event.number}',
      'event.sourced': '${repo.store.containsEvent(event)}',
      'event.stream.instance': '${event.streamId}',
      'event.stream.canonical': '${repo.store.canonicalStream}',
      'event.patches': '${event.patches.map((p) => '$p').toList()}',
      'aggregate.type': '${repo.aggregateType}',
      'aggregate.uuid': '$uuid',
      'aggregate.stream': '${repo.store.toInstanceStream(uuid)}',
      'aggregate.tainted': '${repo.store.isTainted(uuid)}',
      'aggregate.cordoned': '${repo.store.isCordoned(uuid)}',
      'aggregate.contained': '${repo.contains(uuid)}',
      'aggregate.number.head': '${aggregate?.headEvent?.number}',
      'aggregate.number.base': '${aggregate?.baseEvent?.number}',
      'aggregate.number.actual': '${aggregate?.number}',
      'aggregate.number.stored': '${repo.store.last(uuid: uuid)}',
      'aggregate.modifications': '${aggregate?.modifications}',
      'aggregate.applied.count': '${aggregate?.applied?.length}',
      'aggregate.pending.count': '${aggregate?.getLocalEvents()?.length}',
      'repository.ready': '${repo.isReady}',
      'repository.count.exists': '${repo.count(deleted: false)}',
      'repository.count.contains': '${repo.count(deleted: true)}',
      'repository.snapshot.number': '${repo.snapshot?.number}',
      if (repo.snapshot == null)
        'repository.snapshot.aggregate.number': 'null'
      else
        'repository.snapshot.aggregate.number': '${repo.snapshot.aggregates[uuid]?.number}',
      'store.connection': '${repo.store.connection.host}:${repo.store.connection.port}',
      'store.events.count': '${repo.store.length}',
      'store.number.instance': '${repo.store.last(uuid: aggregate.uuid)}',
      'store.number.canonical': '${repo.store.last()}',
    };
  }
}

// TODO: Add delete operation to EventStoreConnection

/// EventStore HTTP connection class
@sealed
class EventStoreConnection {
  EventStoreConnection({
    this.scheme = 'http',
    this.host = '127.0.0.1',
    this.port = 2113,
    this.pageSize = 20,
    this.requireMaster = false,
    this.enforceAddress = true,
    this.credentials = UserCredentials.defaultCredentials,
    Duration connectionTimeout = const Duration(seconds: 5),
  })  : _logger = Logger('EventStoreConnection[port:$port]'),
        client = IOClient(
          HttpClient()..connectionTimeout = connectionTimeout,
        );

  final int port;
  final String host;
  final int pageSize;
  final String scheme;
  final Client client;
  final bool requireMaster;
  final bool enforceAddress;
  final UserCredentials credentials;

  final Logger _logger;

  String get baseUrl => '$scheme://$host:$port';
  String get masterUrl => _masterUrl;
  String _masterUrl;

  String toURL(
    String uri, {
    bool master = false,
  }) =>
      '${(master ?? requireMaster) ? (masterUrl ?? baseUrl) : baseUrl}/$uri';

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
    final url = toURL(
      'streams/$stream${_toFeedUri(
        embed: embed,
        number: actual,
        direction: direction,
        pageSize: pageSize ?? this.pageSize,
      )}',
      master: master ?? requireMaster,
    );
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
    try {
      final masterUrl = _setMasterUrl(response);
      _logger.fine(
        'Redirect read to master $masterUrl',
      );
      final redirected = await client.get(
        masterUrl,
        headers: headers,
      );
      if (redirected.statusCode != 200) {
        _logger.warning(
          'Redirect read from master $masterUrl '
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

  String _setMasterUrl(Response response) {
    final location = response.headers['location'];
    final uri = Uri.parse(location);
    _masterUrl = '${uri.scheme}://${uri.host}:${uri.port}';
    return location;
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
    int pageSize = 20,
    bool embed = false,
    bool master = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    final result = await getFeed(
      embed: embed,
      stream: stream,
      number: number,
      master: master,
      pageSize: pageSize,
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
    Duration waitFor = defaultWaitFor,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
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
    bool master = false,
    EventNumber number = EventNumber.first,
    Direction direction = Direction.forward,
  }) async {
    // Get Initial atom feed
    var feed = await getFeed(
      embed: embed,
      stream: stream,
      number: number,
      master: master,
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
    final url = toURL(
      'streams/$stream',
      master: requireMaster,
    );
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
    try {
      final masterUrl = _setMasterUrl(response);
      _logger.fine(
        'Redirect write to master $masterUrl',
      );
      final redirected = await client.post(
        masterUrl,
        headers: headers,
        body: body,
      );
      if (redirected.statusCode != 201) {
        _logger.warning(
          'Redirect write to master $masterUrl '
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
      final metric = _metrics['read'].next(tic);
      if (metric.last.inMilliseconds > limit) {
        _logger.warning(
          'SLOW READ: Reading ${feed.atomFeed.entries.length} '
          'from ${feed.stream}@${feed.number} in direction ${enumName(feed.direction)} '
          'took ${metric.last.inMilliseconds} ms',
        );
      }
      _metrics['read'] = metric;
    }
    return feed;
  }

  WriteResult _checkSlowWrite(WriteResult write, DateTime tic, int limit) {
    if (write?.isCreated == true) {
      final metric = _metrics['write'].next(tic);
      if (metric.last.inMilliseconds > limit) {
        _logger.warning(
          'SLOW WRITE: Writing ${write.events.length} events '
          'to ${write.stream} took ${metric.last.inMilliseconds} ms',
        );
      }
      _metrics['write'] = metric;
    }
    return write;
  }

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
    final url = _mapUrlTo(
      toURL('subscriptions/$stream/$group'),
    );
    _logger.fine('createSubscription: PUT $url');
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
    var url = _mapUrlTo(
      toURL('subscriptions/$stream/$group/$count'),
    );
    if (embed) {
      url = '$url?embed=body';
    }
    _logger.finer('_getSubscriptionGroup: GET $url');
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
    final url = toURL('subscriptions/$stream/$group/$answer?ids=$ids$nackAction');
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
    final url = toURL('projection/$name/command/${enumName(command)}');
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
      toURL('projection/$name'),
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
    return 'EventStoreConnection{url: $baseUrl, pageSize: $pageSize}';
  }

  String _mapUrlTo(String url) {
    if (enforceAddress) {
      var uri = Uri.parse(url);
      final host = uri.host;
      if (uri.hasPort) {
        final next = url.replaceFirst('${uri.scheme}://$host:${uri.port}', '$baseUrl');
        return next;
      }
      return url.replaceFirst('$host', '$baseUrl');
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
        Context.toMethod('Failed to read from $_stream@${_current}, listening for $_current', [
          Context.toObject('result', [
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
      logger.network(
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

  /// Get canonical stream name
  String get canonicalStream => [stream, if (group != null) group].join('/');

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
        '${_strategy == null ? 'pull' : enumName(_strategy)} subscription at $canonicalStream@$_current',
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
        'Listen for events from $canonicalStream@$_current',
      );
    } catch (error, stackTrace) {
      _onFatal(
        'Failed to start timer for subscription at $canonicalStream@$_current, error: $error',
        error,
        stackTrace,
      );
    }
  }

  void _onFatal(String message, Object error, StackTrace stackTrace) {
    _stopTimer();
    logger.network(message, error, stackTrace);
    controller.addError(error, stackTrace);
  }

  void _pauseTimer() {
    _isPaused = true;
    logger.fine(
      'Pausing ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer at $canonicalStream@$_current',
    );
    _timer?.cancel();
    _timer = null;
  }

  void _stopTimer() {
    logger.fine(
      'Stopping ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer at $canonicalStream@$_current',
    );
    _timer?.cancel();
    _timer = null;
  }

  Future _catchup(StreamController<SourceEvent> controller) async {
    logger.fine(
      'Subscription is catching up from $canonicalStream@$_number',
    );

    FeedResult feed;
    var fetched = 0;
    do {
      feed = await _readNext();
      fetched += (feed?.atomFeed?.entries?.length ?? 0);
    } while (_shouldReadNext(feed));

    if (_isPaused) {
      logger.fine(
        'Paused ${_strategy == null ? 'pull' : enumName(_strategy)} subscription at $canonicalStream@$_current',
      );
    } else {
      if (_number < _current) {
        // This should sum up for pull-subscriptions!
        // If it doesn't something is wrong!
        if (_strategy == null && (_number + fetched + (number.isNone ? 1 : 0)) != _current) {
          throw StateError(
            '$fetched events fetched from $canonicalStream@$_number does not match current $_current',
          );
        }
        logger.fine(
          'Subscription caught up from $canonicalStream @$_number to $_current',
        );
      }
    }
    return _current;
  }

  bool _shouldReadNext(FeedResult feed) => feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty);

  Future<FeedResult> _readNext() async {
    FeedResult feed;
    try {
      feed = await _nextFeed();
      if (!_isPaused && feed.isNotEmpty) {
        await _readEventsInFeed(feed);
      }
      return _isPaused ? null : feed;
    } catch (error, stackTrace) {
      // Only throw if running
      if (_timer != null && _timer.isActive) {
        _onFatal(
          'Failed to read $pageSize next events from $canonicalStream@$_current: error: $error',
          error,
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
      'Subscription $canonicalStream caught up from $_current to ${result.number}, listening for $next',
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
        'Failed to accept ${feed.atomFeed.entries.length} events at $canonicalStream@$_current: '
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
