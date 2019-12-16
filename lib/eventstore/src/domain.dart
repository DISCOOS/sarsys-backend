import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sarsys_app_server/eventstore/eventstore.dart';

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
  });
  final EventStore store;
  final String uuidFieldName;

  /// Map of aggregate roots
  final Map<String, T> _aggregates = {};

  /// Build repository from local events
  Future build() async {
    return store.replay(this);
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
  /// Returns true if changes was saved, false otherwise
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
  Iterable<Event> commit() {
    final changes = _changes.toSet();
    _changes.clear();
    return changes;
  }

  /// Process domain event
  ///
  /// Throws [InvalidOperation] if [Event.uuid] is not equal to [AggregateRoot.uuid]
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
