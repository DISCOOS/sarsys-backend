import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';
import 'package:sarsys_app_server/sarsys_app_server.dart';

import 'core.dart';

/// Base class for domain events
class DomainEvent extends Event {
  const DomainEvent({
    @required String uuid,
    @required String type,
    @required Map<String, dynamic> data,
  }) : super(
          uuid: uuid,
          type: type,
          data: data,
        );
}

// TODO: Rewrite into Bloc-pattern since Repository is functionally similar to Bloc
abstract class Repository<T extends AggregateRoot> {
  Repository({
    @required this.store,
    this.uuidFieldName = 'id',
  }) : logger = Logger("${typeOf<T>()}");

  final EventStore store;
  final Logger logger;
  final String uuidFieldName;

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};

  /// Cancelled when repository is disposed
  StreamSubscription<SourceEvent> _subscription;

  /// Build repository from local events
  Future build() async {
    await store.replay(this);
    _subscribe();
  }

  /// Must be called to prevent memory leaks
  void dispose() {
    _subscription?.cancel();
  }

  /// Get aggregate with given id.
  ///
  /// Will create a new aggregate if not found.
  T get(String uuid, {Map<String, dynamic> data = const {}}) =>
      _aggregates[uuid] ??
      _aggregates.putIfAbsent(
        uuid,
        () => create(uuid, data)..loadFromHistory(store.get(uuid).map(toDomainEvent)),
      );

  /// Get all aggregate roots.
  Iterable<T> getAll() => _aggregates.values.toList();

  /// Commit aggregate changes to local storage
  ///
  /// Returns true if changes was saved, false otherwise
  Iterable<Event> commit(T aggregate) => store.commit(aggregate);

  /// Commit all changes and return pending events
  Iterable<Event> commitAll() => _aggregates.values.map(store.commit).fold(
        <Event>[],
        (events, items) => <Event>[...events, ...items],
      );

  /// Push aggregate changes to remote storage
  ///
  /// Returns pushed events is saved, empty list otherwise
  Future<Iterable<Event>> push() => store.push(_aggregates.values);

  /// Validate data
  /// Throws [InvalidOperation] if [Event.data] does not contain [Repository.uuidFieldName]
  @mustCallSuper
  Map<String, dynamic> validate(Map<String, dynamic> data) {
    if (data.containsKey(uuidFieldName) == false) {
      throw InvalidOperation("Data must contain field $uuidFieldName");
    }
    return data;
  }

  /// Get domain event from event source
  DomainEvent toDomainEvent(Event event);

  /// Get aggregate uuid from event
  String toAggregateUuid(Event event) => event.data[uuidFieldName] as String;

  /// Create aggregate root with given id
  @protected
  T create(String uuid, Map<String, dynamic> data);

  /// Check if repository contains given aggregate root
  bool contains(String uuid) => _aggregates.containsKey(uuid);

  /// Subscribe to changes in stream
  void _subscribe() {
    _subscription = store.connection
        .subscribe(
          stream: store.stream,
          number: store.current,
        )
        .listen(
          _onEvent,
          onDone: _onDone,
          onError: _onError,
        );
  }

  void _onEvent(SourceEvent event) {
    try {
      if (event.number > store.current) {
        // Get and commit changes
        final aggregate = get(event.uuid, data: event.data);
        if (aggregate.isChanged == false) {
          aggregate.patch(event.data);
        }
        store.commit(aggregate);
      }
    } catch (e) {
      logger.severe("Failed to process ${event.type}{uuid: ${event.uuid}}, got $e");
    }
  }

  void _onDone() {
    logger.info("Subscription on '${store.stream}' closed");
  }

  void _onError(error) {
    logger.severe("Subscription on '${store.stream}' failed with: $error");
  }
}

/// Base class for [aggregate roots](https://martinfowler.com/bliki/DDD_Aggregate.html).
abstract class AggregateRoot {
  @mustCallSuper
  AggregateRoot(
    this.uuid,
    Map<String, dynamic> data, {
    this.uuidFieldName = 'id',
  }) : data = Map.from(data) {
    changed(created(Map.from(data)));
  }

  /// Not the same as [Event.uuid], which is unique for each [Event].
  final String uuid;

  /// Field name in [Event.data] for [AggregateRoot.uuid].
  final String uuidFieldName;

  /// Aggregate root data (weak schema)
  final Map<String, dynamic> data;

  /// Local uncommitted changes
  final _changes = <DomainEvent>[];

  /// Get changed not committed to store
  @protected
  Iterable<Event> getUncommittedChanges() => _changes;

  /// Check if uncommitted changes exists
  bool get isChanged => _changes.isNotEmpty;

  /// Load events from history
  @protected
  void loadFromHistory(Iterable<DomainEvent> events) {
    // Only load history if exist, this the event created during construction
    if (events.isNotEmpty) {
      _changes.clear();
    }
    events?.forEach((event) => _changed(process(event), false));
  }

  /// Patch aggregate root with given id and data
  AggregateRoot patch(Map<String, dynamic> data);

  /// Get uncommitted changes and clear internal cache
  Iterable<DomainEvent> commit() {
    final changes = _changes.toSet();
    _changes.clear();
    return changes;
  }

  /// Process domain event
  ///
  /// Throws [InvalidOperation] if value [uuidFieldName] in [Event.data] is not equal to [AggregateRoot.uuid]
  @protected
  DomainEvent process(DomainEvent event) {
    if (event.data[uuidFieldName] != uuid) {
      throw InvalidOperation("Aggregate has $uuid, event has ${event.uuid}");
    }
    data.addAll(event.data);
    return event;
  }

  /// Invoked from constructor
  @protected
  DomainEvent created(Map<String, dynamic> data);

  /// Register aggregate change
  @protected
  void changed(DomainEvent event) => _changed(event, true);

  void _changed(DomainEvent event, bool isNew) {
    data.addAll(event.data);
    if (isNew) {
      _changes.add(event);
    }
  }
}
