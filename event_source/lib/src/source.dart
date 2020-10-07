import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:json_patch/json_patch.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';

import 'bus.dart';
import 'core.dart';
import 'error.dart';
import 'extension.dart';
import 'domain.dart';
import 'models/AtomFeed.dart';
import 'models/AtomItem.dart';
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
    @required this.snapshots,
    @required this.aggregate,
    @required this.connection,
    this.prefix,
    this.useInstanceStreams = true,
  }) : logger = Logger('EventStore[${toCanonical([prefix, aggregate])}][${connection.port}]') {
    _current[canonicalStream] = EventNumber.none;
  }

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

  /// Check if store is empty
  bool get isEmpty => _store.isEmpty;

  /// Check if store is not empty
  bool get isNotEmpty => _store.isNotEmpty;

  /// Current event numbers mapped to associated stream
  final Map<String, EventNumber> _current = {};

  /// Get all events
  Map<String, Set<SourceEvent>> get events => Map.from(_store);

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
  final LinkedHashMap<String, LinkedHashSet<SourceEvent>> _store = LinkedHashMap<String, LinkedHashSet<SourceEvent>>();

  /// Get [Storage] instance
  final Storage snapshots;

  /// Current event number for [canonicalStream]
  ///
  /// If [AggregateRoot.uuid] is given, the aggregate
  /// instance stream number is returned. This numbers
  /// is the same as for the [canonicalStream] if
  /// [useInstanceStreams] is false.
  ///
  /// If [stream] is given, this takes precedence and
  /// returns the event number for this stream.
  ///
  /// If stream does not exist, [EventNumber.none] is returned.
  ///
  EventNumber current({String stream, String uuid}) =>
      (useInstanceStreams && (stream != null || uuid != null)
          ? _current[stream ?? toInstanceStream(uuid)]
          : _current[canonicalStream]) ??
      EventNumber.none;

  /// Replay events from stream to given repository.
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  Future<int> replay<T extends AggregateRoot>(
    Repository<Command, T> repository, {
    bool master = false,
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    try {
      // Stop subscriptions
      // from catching up
      pause();

      bus.replayStarted<T>();

      // Clear current state to
      final offset = _reset(repository);

      // Fetch all events
      final count = await _catchUp(
        repository,
        master: master,
        number: offset,
      );
      final snapshot = repository.hasSnapshot ? ' (snapshot)' : '';
      logger.info(
        "Replayed $count events from stream '${canonicalStream}' with offset ${offset.value} $snapshot",
      );
      return count;
    } finally {
      bus.replayEnded<T>();
      resume();
    }
  }

  EventNumber _reset(Repository repository) {
    _store.clear();
    _current.clear();
    final snapshot = repository.snapshot;
    if (snapshot == null) {
      _current[canonicalStream] = EventNumber.none;
    } else {
      _current[canonicalStream] = EventNumber(snapshot.number.value);
      if (useInstanceStreams) {
        snapshot.aggregates.values.forEach((a) {
          _updateAll(a.uuid, <SourceEvent>[]);
          final stream = toInstanceStream(a.uuid);
          _current[stream] = EventNumber(a.number.value);
        });
      }
    }
    final offset = _assertCanonicalStreamOffset(
      repository,
    );
    return repository.hasSnapshot ? offset + 1 : offset;
  }

  EventNumber _assertCanonicalStreamOffset(Repository repository) {
    final offset = _current[canonicalStream].isNone ? EventNumber.first : _current[canonicalStream];
    if (offset.value < 0) {
      throw StateError(
        'Canonical stream $canonicalStream for '
        'repository ${repository.runtimeType} is negative.'
        '',
      );
    }
    return offset;
  }

  /// Catch up with stream
  Future<int> catchUp(
    Repository repository, {
    bool master = false,
  }) async {
    final previous = _assertCanonicalStreamOffset(repository);
    final next = previous + 1;
    final count = await _catchUp(
      repository,
      number: next,
      master: master,
    );
    final actual = current();
    if (count > 0) {
      logger.info(
        'Caught up from event $previous to $actual with $count events from remote stream $canonicalStream',
      );
    } else {
      logger.info(
        'Local stream $canonicalStream is at same event number as remote stream ($previous)',
      );
    }
    return count;
  }

  /// Catch up with stream from given number
  Future<int> _catchUp(
    Repository repo, {
    EventNumber number,
    bool master = false,
  }) async {
    try {
      var count = 0;

      // Stop subscriptions
      // from catching up
      pause();

      // Lower bound is last known event number in stream
      final head = EventNumber(
        max(number.value, current().value),
      );
      if (head > number) {
        logger.fine(
          "_catchUp: 'number': $number < current number "
          "for $canonicalStream: ${current()}: 'number' changed to $head",
        );
      }

      final stream = await connection.readEventsAsStream(
        stream: canonicalStream,
        number: head,
        master: master,
      );

      // Process results as they arrive
      stream.listen((result) {
        if (result.isOK) {
          // Group events by aggregate uuid
          final eventsPerAggregate = groupBy<SourceEvent, String>(
            result.events,
            (event) => repo.toAggregateUuid(event),
          );

          // Hydrate store with events
          eventsPerAggregate.forEach(
            (uuid, events) {
              final domainEvents = _applyAll(
                repo,
                uuid,
                events,
              );
              // Publish remotely created events.
              // Handlers can determine events with
              // local origin using the local field
              // in each Event
              _publishAll(domainEvents);
            },
          );

          count += result.events.length;
        }
      });

      await stream.length;
      return count;
    } finally {
      snapshotWhen(repo);
      resume();
    }
  }

  /// Save a snapshot when locally
  /// stored events exceed
  /// [snapshots.threshold]
  void snapshotWhen(Repository repo) {
    if (snapshots?.threshold is num) {
      final last = snapshots.last?.number?.value ?? EventNumber.first.value;
      if (repo.number.value - last >= snapshots.threshold) {
        repo.save();
      }
    }
  }

  void _updateAll(String uuid, Iterable<SourceEvent> events) {
    if (useInstanceStreams) {
      final stream = toInstanceStream(uuid);
      final offset = current(stream: stream);
      // Event numbers in instance streams SHOULD ALWAYS
      // be sorted in an ordered monotone incrementing
      // manner. This check ensures that if and only if
      // the assumption is violated, an InvalidOperation
      // exception is thrown. This ensures that previous
      // next states can be calculated safely without any
      // risk of applying patches out-of-order, removing the
      // need to store these states in each event.
      events.fold(
        offset,
        (previous, next) => _assertMonotone(stream, previous, next),
      );
    }
    _store.update(
      uuid,
      (current) => current..addAll(events),
      ifAbsent: () => LinkedHashSet.of(events),
    );
  }

  Iterable<DomainEvent> _applyAll(
    Repository repository,
    String uuid,
    List<SourceEvent> events,
  ) {
    _updateAll(uuid, events);
    final exists = repository.contains(uuid);
    final aggregate = repository.get(uuid);

    final domainEvents = events.map(
      repository.toDomainEvent,
    );
    if (exists) {
      domainEvents.forEach(aggregate.apply);
    }
    // Commit remote changes
    aggregate.commit();

    // Catch up with last event in stream
    _setEventNumber(aggregate, events);

    return domainEvents;
  }

  /// Get events for given [AggregateRoot.uuid]
  Iterable<Event> get(String uuid) => List.from(_store[uuid] ?? []);

  /// Commit applied events to aggregate.
  Iterable<DomainEvent> _commit(
    AggregateRoot aggregate,
    Iterable<DomainEvent> changes,
  ) {
    _assertState();
    final events = aggregate.commit(
      changes: changes,
    );

    // Do not save events during replay
    if (bus.isReplaying == false && events.isNotEmpty) {
      _updateAll(
        aggregate.uuid,
        _toSourceEvents(
          events: events,
          uuidFieldName: aggregate.uuidFieldName,
          stream: toInstanceStream(aggregate.uuid),
        ),
      );

      _setEventNumber(aggregate, changes);

      // Publish locally created events.
      // Handlers can determine events with
      // local origin using the local field
      // in each Event
      _publishAll(events);
    }
    return events;
  }

  /// Set event number for given [aggregate]
  ///
  /// If source [events] are given, event
  /// numbers are validated to be monotone
  /// increasing
  ///
  void _setEventNumber(
    AggregateRoot aggregate,
    Iterable<Event> events,
  ) {
    final stream = toInstanceStream(aggregate.uuid);
    if (_current.containsKey(stream)) {
      _current[stream] += events.length;
    } else {
      _current[stream] = EventNumber.none + events.length;
    }

    // Update canonical stream?
    if (useInstanceStreams) {
      if (_current.containsKey(canonicalStream)) {
        _current[canonicalStream] += events.length;
      } else {
        _current[canonicalStream] = EventNumber.none + events.length;
      }
    }
  }

  /// Publish events to [bus] and [asStream]
  void _publishAll(Iterable<DomainEvent> events) {
    // Notify later but before next Future
    events.forEach(bus.publish);
    _streamController ??= StreamController.broadcast();
    events.forEach(_streamController.add);
  }

  /// Get name of aggregate instance stream for [AggregateRoot.uuid].
  String toInstanceStream(String uuid) {
    if (useInstanceStreams) {
      final index = _store.keys.toList().indexOf(uuid);
      return '${toCanonical([prefix, aggregate])}-${index < 0 ? _store.length : index}';
    }
    return canonicalStream;
  }

  /// Push given [changes] in [aggregate] to appropriate instance stream.
  ///
  /// If [snapshot] is given, this state is pushed and result
  /// applied to [aggregate] if push succeeded.
  ///
  /// Throws an [WrongExpectedEventVersion] if current event number
  /// aggregate instance stream for [aggregate] stored locally is not
  /// equal to the last event number in aggregate instance stream.
  /// This failure is recoverable when the store has caught up with
  /// all events in [canonicalStream].
  ///
  /// Throws an [WriteFailed] for all other failures. This failure
  /// is not recoverable.
  Future<Iterable<DomainEvent>> push(AggregateRoot aggregate) async {
    _assertState();
    if (aggregate.isChanged == false) {
      return [];
    }
    final stream = toInstanceStream(aggregate.uuid);
    final changes = aggregate.getUncommittedChanges();
    final version = toExpectedVersion(stream);
    final result = await connection.writeEvents(
      stream: stream,
      version: version,
      events: changes.map((e) => e.toEvent(aggregate.uuidFieldName)),
    );
    if (result.isCreated) {
      // Commit all changes
      // after successful write
      _commit(aggregate, changes);
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
  ExpectedVersion toExpectedVersion(String stream) => (_current[stream] ?? EventNumber.none).isNone
      ? ExpectedVersion.none
      : ExpectedVersion.from(
          _current[stream],
        );

  /// Subscription controller for each repository
  /// subscribing to events from [canonicalStream]
  final _controllers = <Type, SubscriptionController>{};

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
  Future compete(
    Repository repository, {
    int consume = 20,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repository);

    // Dispose current subscription if exists
    await _controllers[repository.runtimeType]?.cancel();

    // Get existing or create new
    final controller = await _subscribe(
      _controllers[repository.runtimeType] ??
          SubscriptionController(
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
  }

  /// Subscribe given [repo] to receive changes from [canonicalStream]
  ///
  /// Throws an [InvalidOperation] if [Repository.store] is not this [EventStore]
  /// Throws an [InvalidOperation] if [Repository] is already subscribing to events
  Future subscribe(
    Repository repo, {
    Duration maxBackoffTime = const Duration(seconds: 10),
  }) async {
    // Sanity checks
    _assertState();
    _assertRepository(repo);

    // Dispose current subscription if exists
    await _controllers[repo.runtimeType]?.cancel();

    // Get existing or create new
    final controller = await _subscribe(
      _controllers[repo.runtimeType] ??
          SubscriptionController(
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
  }

  Future<SubscriptionController> _subscribe(
    SubscriptionController controller,
    Repository repository, {
    int consume = 20,
    bool competing = false,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    final number = current();
    return competing
        ? controller.compete(
            repository,
            stream: canonicalStream,
            group: '${repository.aggregateType}',
            number: number,
            consume: consume,
            strategy: strategy,
          )
        : controller.subscribe(
            repository,
            number: number,
            stream: canonicalStream,
          );
  }

  final seen = <SourceEvent>[];

  /// Handle event from subscriptions
  void _onSubscriptionEvent(Repository repo, SourceEvent event) {
    final uuid = repo.toAggregateUuid(event);
    final stream = toInstanceStream(uuid);
    final actual = current(uuid: uuid);

    seen.add(event);

    // Allow update of existing event
    if (event.number >= actual) {
      try {
        // Only catchup if repository have no
        // pending changes. If updated before
        // write-op is completed, a concurrent
        // write will happened and information
        // will be lost. Repository should therefore
        // call pause before processing is started
        // and only call resume when ALL changes
        // have been processed.
        if (repo.isProcessing) {
          throw StateError(
            'Subscription events not allowed when processing changes',
          );
        } else if (repo.isChanged) {
          throw StateError(
            'Subscription events not allowed when repository contains changes',
          );
        }

        _controllers[repo.runtimeType]?.connected(repo, connection);

        // Event is applied to aggregate?
        final isApplied = _isApplied(uuid, event, repo);

        if (isApplied) {
          _onUpdate(uuid, stream, event, repo);
        } else {
          _onApply(uuid, stream, event, repo);
        }

        // micro-optimization to
        // minimize string interpolations
        if (logger.level <= Level.FINE) {
          final aggregate = repo.get(uuid);
          final applied = aggregate.applied.where((e) => e.uuid == event.uuid).firstOrNull;
          logger.fine(
            '_onSubscriptionEvent(${repo.runtimeType}, ${event.runtimeType}){\n'
            '  event.type: ${event.type}, \n'
            '  event.uuid: ${event.uuid}, \n'
            '  event.number: ${event.number}, \n'
            '  event.sourced: ${_isSourced(uuid, event)}, \n'
            '  event.applied: $isApplied, \n'
            '  aggregate.uuid: ${aggregate.uuid}, \n'
            '  aggregate.stream: $stream, \n'
            '  aggregate.applied.patches: ${applied?.patches}, \n'
            '  aggregate.applied.changed: ${applied?.changed}, \n'
            '  aggregate.applied.previous: ${applied?.previous}, \n'
            '  repository: ${repo.runtimeType}, \n'
            '  repository.isEmpty: $isEmpty, \n'
            '  repository.numbers: $_current\n'
            '  repository.numbers.instance: $actual\n'
            '  isInstanceStream: $useInstanceStreams, \n'
            '}',
          );
        }
      } on JsonPatchError catch (e, stackTrace) {
        logger.network(
          'Failed to apply patches from aggregate stream ${canonicalStream}{\n'
          '  error: $e, \n'
          '  connection: ${repo.store.connection.host}:${repo.store.connection.port}, \n'
          '  event.type: ${event.type}, \n'
          '  event.uuid: ${event.uuid}, \n'
          '  event.number: ${event.number}, \n'
          '  repository: ${repo.runtimeType}, \n'
          '  repository.isEmpty: $isEmpty, \n'
          '  repository.numbers: $_current\n'
          '  isInstanceStream: $useInstanceStreams, \n'
          '  subscription.seen: ${repo.store.seen}, \n'
          '  store.events.count: ${repo.store.events.values.fold(0, (count, events) => count + events.length)}, \n'
          '  store.events.items: ${repo.store.events.values}, \n'
          '}\n'
          'stacktrace: $stackTrace',
          e,
          stackTrace,
        );
      } catch (e, stackTrace) {
        _onFatal(event, stream, e, stackTrace);
      } finally {
        snapshotWhen(repo);
      }
    }
  }

  void _onFatal(SourceEvent event, String stream, Object error, StackTrace stackTrace) {
    logger.network(
      'Failed to process $event for $stream, \n'
      'error: $error with stacktrace: $stackTrace',
      error,
      stackTrace,
    );
    _streamController.addError(
      RepositoryError('Failed to process $event for $stream with error: $error'),
    );
  }

  bool _isSourced(String uuid, SourceEvent event) => _store.containsKey(uuid) && _store[uuid].contains(event);
  bool _isApplied(String uuid, SourceEvent event, Repository repo) =>
      repo.contains(uuid) && repo.get(uuid).isApplied(event);

  void _onUpdate(
    String uuid,
    String stream,
    SourceEvent event,
    Repository repository,
  ) {
    logger.fine('_onUpdate(${event.type}(uuid: ${event.uuid}, number:${event.number}, remote:${event.remote}))');

    // Catch up with stream
    final aggregate = repository.get(uuid);

    // Sanity check
    if (aggregate.isChanged) {
      throw InvalidOperation(
        'Remote event $event modified ${aggregate.runtimeType} ${aggregate.uuid}',
      );
    }

    // Apply event with stable created date?
    final applied = aggregate.getApplied(event.uuid);
    if (applied == null) {
      throw InvalidOperation(
        'Remote event $event not seen by ${aggregate.runtimeType} ${aggregate.uuid}',
      );
    }
    final domainEvent = repository.toDomainEvent(event);
    aggregate.apply(domainEvent);

    // Publish remotely created events.
    // Handlers can determine events with
    // remote origin using the local field
    // in each Event
    _publishAll([domainEvent]);
  }

  void _onApply(
    String uuid,
    String stream,
    SourceEvent event,
    Repository repository,
  ) {
    logger.fine('_onApply(${event.type}(uuid: ${event.uuid}, number:${event.number}, remote:${event.remote}))');

    // IMPORTANT: append to store before applying to repository
    // This ensures that the event added to an aggregate during
    // construction is overwritten with the remote actual
    // received here.
    _updateAll(uuid, [event]);

    // Catch up with stream
    final aggregate = repository.get(uuid);
    final domainEvent = repository.toDomainEvent(event);
    if (!aggregate.isApplied(event)) {
      aggregate.apply(domainEvent);
    }
    // Sanity check
    if (aggregate.isChanged) {
      throw InvalidOperation(
        'Remote event $event modified ${aggregate.runtimeType} ${aggregate.uuid}',
      );
    }

    _setEventNumber(aggregate, [event]);

    // Publish remotely created events.
    // Handlers can determine events with
    // local origin using the local field
    // in each Event
    _publishAll([domainEvent]);
  }

  /// Handle subscription completed
  void _onSubscriptionDone(Repository repository) {
    logger.fine('${repository.runtimeType}: subscription closed');
    if (!_isDisposed) {
      _controllers[repository.runtimeType].reconnect(
        repository,
      );
    }
  }

  /// Handle subscription errors
  void _onSubscriptionError(Repository repository, Object error, StackTrace stackTrace) {
    _fatal(
      repository,
      error,
      stackTrace,
    );
    if (!_isDisposed) {
      _controllers[repository.runtimeType].reconnect(
        repository,
      );
    }
  }

  void _fatal(Repository repository, Object error, StackTrace stackTrace) {
    logger.network(
      '${repository.runtimeType}: subscription failed with: $error. stacktrace: $stackTrace',
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
  void _assertRepository(Repository<Command, AggregateRoot> repository) {
    if (repository.store != this) {
      throw InvalidOperation('This $this is not managed by ${repository.runtimeType}');
    }
  }

  /// Assert that current event number for [stream] is caught up with last known event
  void _assertCurrentVersion(String stream, EventNumber actual, {String reason = 'Catch up failed'}) {
    if (_current[stream] != actual) {
      final e = EventNumberMismatch(
        stream: stream,
        actual: actual,
        message: reason,
        numbers: _current,
        current: _current[stream],
      );
      logger.severe('${e.message}, debug: ${toDebugString(stream)}');
      throw e;
    }
  }

  EventNumber _assertMonotone(String stream, EventNumber previous, SourceEvent next) {
    if (previous.value > next.number.value) {
      final message = 'EventNumber not monotone increasing, current: $previous, '
          'next: ${next.number} in event ${next.type} with uuid: ${next.uuid}';
      final error = InvalidOperation('$message, debug: ${toDebugString(stream)}');
      logger.severe(error.message, error, StackTrace.current);
      throw error;
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
  void pause() {
    _assertState();
    if (!isPaused) {
      _controllers.values.forEach(
        (controller) => controller.pause(),
      );
    }
    _paused++;
    logger.fine('pause($_paused)');
  }

  /// Resume all subscriptions
  void resume() {
    if (isPaused) {
      _paused--;
      if (!isPaused) {
        _controllers.values.forEach(
          (controller) => controller.resume(),
        );
      }
    }
    logger.fine('resume($_paused)');
  }

  /// Clear events in store and close connection
  Future dispose() async {
    _isDisposed = true;
    _store.clear();

    try {
      await Future.wait(
        _controllers.values.map((c) => c.cancel()),
      );
    } on ClientException catch (e, stackTrace) {
      logger.network('Failed to dispose one or more subscriptions: error: $e, stacktrace: $stackTrace', e, stackTrace);
    }

    _controllers.clear();
    if (_streamController?.hasListener == true && _streamController?.isClosed == false) {
      // See https://github.com/dart-lang/sdk/issues/19095#issuecomment-108436560
      // ignore: unawaited_futures
      _streamController.close();
    }
  }

  String toDebugString([String stream]) {
    final uuid = _store.keys.firstWhere(
      (uuid) => toInstanceStream(uuid) == stream,
      orElse: () => 'not found',
    );
    return '$runtimeType: {\n'
        'aggregate.uuid: $uuid,\n'
        'store.stream: $stream,\n'
        'store.canonicalStream: $canonicalStream},\n'
        'store.count: ${_store.length},\n'
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
}

/// Class for handling a subscription with automatic reconnection on failures
class SubscriptionController<T extends Repository> {
  SubscriptionController({
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

  /// Cancelled when store is disposed
  StreamSubscription<SourceEvent> _subscription;

  /// Reconnect count. Uses in exponential backoff calculation
  int reconnects = 0;

  /// Reference for cancelling in [cancel]
  Timer _timer;

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
  Future<SubscriptionController<T>> subscribe(
    T repository, {
    @required String stream,
    EventNumber number = EventNumber.first,
  }) async {
    await _subscription?.cancel();

    _competing = false;
    _group = null;
    _consume = null;
    _strategy = null;
    _subscription = repository.store.connection
        .subscribe(
          stream: stream,
          number: number,
        )
        .listen(
          (event) => onEvent(repository, event),
          onDone: () => onDone(repository),
          onError: (error, stackTrace) => onError(
            repository,
            error,
            stackTrace,
          ),
        );
    logger.fine('${repository.runtimeType} > Subscribed to $stream@$number');
    return this;
  }

  /// Compete for events from given stream.
  ///
  /// Cancels previous subscriptions if exists
  Future<SubscriptionController<T>> compete(
    T repository, {
    @required String stream,
    @required String group,
    int consume = 20,
    EventNumber number = EventNumber.first,
    ConsumerStrategy strategy = ConsumerStrategy.RoundRobin,
  }) async {
    await _subscription?.cancel();
    _competing = true;
    _group = group;
    _consume = consume;
    _strategy = strategy;
    _subscription = repository.store.connection
        .compete(
          stream: stream,
          group: group,
          number: number,
          consume: consume,
          strategy: strategy,
        )
        .listen(
          (event) => onEvent(repository, event),
          onDone: () => onDone(repository),
          onError: (error, StackTrace stackTrace) => onError(
            repository,
            error,
            stackTrace,
          ),
        );
    logger.fine('${repository.runtimeType} > Competing from $stream@$number');
    return this;
  }

  int toNextReconnectMillis() {
    final wait = toNextTimeout(reconnects++, maxBackoffTime);
    logger.info('Wait ${wait}ms before reconnecting (attempt: $reconnects)');
    return wait;
  }

  void reconnect(T repository) async {
    if (!repository.store.connection.isClosed) {
      // Wait for current timer to complete
      _timer ??= Timer(
        Duration(milliseconds: toNextReconnectMillis()),
        () => _retry(repository),
      );
    }
  }

  Future _retry(T repository) async {
    try {
      _timer.cancel();
      _timer = null;
      logger.info(
        '${repository.runtimeType}: SubscriptionController is '
        'reconnecting to stream ${repository.store.canonicalStream}, attempt: $reconnects',
      );
      await _subscription?.cancel();
      if (_competing) {
        _subscription = await repository.store.compete(
          repository,
          consume: _consume,
          strategy: _strategy,
          maxBackoffTime: maxBackoffTime,
        );
      } else {
        _subscription = await repository.store.subscribe(
          repository,
          maxBackoffTime: maxBackoffTime,
        );
      }
    } catch (e, stackTrace) {
      logger.network('Failed to reconnect: $e: $stackTrace', e, stackTrace);
    }
  }

  void connected(T repository, EventStoreConnection connection) {
    if (reconnects > 0) {
      logger.info(
        '${repository.runtimeType} reconnected to '
        "'${connection.host}:${connection.port}' after ${reconnects} attempts",
      );
      reconnects = 0;
    }
  }

  bool get isPaused => _subscription?.isPaused == true;

  void pause() {
    _subscription?.pause();
  }

  void resume() {
    _subscription?.resume();
  }

  Future cancel() {
    _timer?.cancel();
    return _subscription?.cancel();
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
              Map<String, dynamic>.from(json.decode(response.body)),
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

    var next;
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

    return FeedResult.from(
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

  Future<WriteResult> writeEvents({
    @required String stream,
    @required Iterable<Event> events,
    ExpectedVersion version = ExpectedVersion.any,
  }) async {
    _assertState();
    final sourced = <SourceEvent>[];
    final data = events.map(
      (event) => {
        'data': event.data,
        'eventType': event.type,
        'eventId': _toSourceEvent(
          event,
          stream: stream,
          events: sourced,
          number: version.toNumber(),
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
      return WriteResult.from(
        stream: stream,
        events: sourced,
        version: version,
        response: response,
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
      return WriteResult.from(
        stream: stream,
        events: sourced,
        version: version,
        response: redirected,
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

  String _toStreamUri(String stream) => '$host:$port/streams/$stream';

  String _toSourceEvent(
    Event event, {
    @required String stream,
    @required EventNumber number,
    @required List<SourceEvent> events,
  }) {
    events.add(SourceEvent(
      streamId: stream,
      number: number + events.length + 1,
      created: event.created,
      type: event.type,
      data: event.data,
      uuid: event.uuid,
      local: event.local,
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

    var controller = _SubscriptionController(
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

    var controller = _SubscriptionController(
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
            ? 'Started reading events from $stream@$_number in direction $_direction'
            : 'Resumed reading events from $stream@$_current in direction $_direction',
      );
      _resume();

      FeedResult feed;
      do {
        if (!_isPaused) {
          // null on pause
          feed = await _readNext();
        }
      } while (feed != null && feed.isOK && !(feed.headOfStream || feed.isEmpty));

      _stopRead();
    } catch (e, stackTrace) {
      _fatal(
        'Failed to read stream $_stream@$_number in direction $_direction, error: $e',
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
    if (!_isPaused && feed.isNotEmpty) {
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

  Future _readEventsInFeed(FeedResult feed) async {
    if (feed.isOK) {
      final result = await connection.readEventsInFeed(feed);
      if (result.isOK) {
        if (_isPaused) {
          _pendingResume = result;
        } else if (result.isNotEmpty) {
          _onResult(result);
        }
      } else {
        _fatal(
          'Failed to read events from $_stream@$_current: ${result.statusCode} ${result.reasonPhrase}',
          StackTrace.current,
        );
      }
      return result;
    }
    _fatal(
      'Failed to read feed from $_stream@$_current: ${feed.statusCode} ${feed.reasonPhrase}',
      StackTrace.current,
    );
    return feed;
  }

  void _onResult(ReadResult result) {
    final next = result.number + 1;
    _current = next;
    // Notify when all actions are done
    controller.add(result);

    logger.fine(
      'Read up to $_stream@${next.value - 1}, listening for $next',
    );
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

  void _fatal(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
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
class _SubscriptionController {
  _SubscriptionController(this.connection) : logger = connection._logger {
    _requestQueue.catchError((e, stackTrace) {
      logger.severe(
        'Processing request ${_requestQueue.current} failed with: $e',
        e,
        stackTrace,
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
  final _requestQueue = StreamRequestQueue<FeedResult>();

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
      onListen: _startTimer,
      onPause: _pauseTimer,
      onResume: _startTimer,
      onCancel: _stopTimer,
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
      onListen: _startTimer,
      onResume: _startTimer,
      onPause: _stopTimer,
      onCancel: _stopTimer,
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
          if (_requestQueue.isEmpty) {
            _requestQueue.add(StreamRequest<FeedResult>(
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
    } catch (e, stackTrace) {
      _fatal(
        'Failed to start timer for subscription $name, error: $e',
        stackTrace,
      );
    }
  }

  void _fatal(String message, StackTrace stackTrace) {
    _stopTimer();
    controller.addError(e, stackTrace);
  }

  void _pauseTimer() {
    _isPaused = true;

    logger.fine('Paused ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer for $name');
    _timer?.cancel();
    _timer = null;
  }

  void _stopTimer() {
    logger.fine('Stop ${_strategy == null ? 'pull' : enumName(_strategy)} subscription timer for $name');
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

    if (number < _current) {
      // This should sum up for pull-subscriptions!
      // Ff it doesn't something is wrong!
      if (_strategy == null && number + fetched != _current) {
        throw StateError(
          '$fetched events fetched does not match number change $number > $_current',
        );
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
    result.events.forEach(
      controller.add,
    );
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
