import 'dart:async';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:event_source/event_source.dart';

import 'core.dart';

/// Base class for failures
abstract class EventSourceException implements Exception {
  const EventSourceException(this.message);
  final String message;

  @override
  String toString() {
    return '$runtimeType{message: $message}';
  }
}

/// Thrown when an invalid operation is attempted
class InvalidOperation extends EventSourceException {
  const InvalidOperation(String message) : super(message);
}

/// Thrown when an invalid operation is attempted
class EventNumberNotStrictMonotone extends InvalidOperation {
  const EventNumberNotStrictMonotone({
    @required String message,
    @required this.uuid,
    @required this.event,
    @required this.expected,
    @required this.uuidFieldName,
  }) : super(message);

  /// Aggregate uuid
  final String uuid;
  final Event event;
  final String uuidFieldName;
  final EventNumber expected;
  EventNumber get actual => event.number;
  int get delta => actual.value - expected.value;
}

/// Thrown when an invalid operation is attempted
class CommandTimeout extends EventSourceException implements TimeoutException {
  const CommandTimeout(String message, this.command, this.duration) : super(message);
  final Command command;
  @override
  final Duration duration;
}

/// Thrown when an required projection is not available
class ProjectionNotAvailable extends InvalidOperation {
  const ProjectionNotAvailable(String message) : super(message);
}

/// Thrown when an error has occurred
class RepositoryError extends Error {
  RepositoryError(this.error, [this.stackTrace]) : super();
  final Object error;

  @override
  final StackTrace stackTrace;

  @override
  String toString() {
    return '$runtimeType{error: $error, stackTrace: ${stackTrace == null ? null : Trace.format(stackTrace)}}';
  }
}

/// Thrown when an maximum pressure in repository is exceeded
class RepositoryMaxPressureExceeded extends InvalidOperation {
  const RepositoryMaxPressureExceeded(
    String message,
    this.uuid,
    this.repository,
  ) : super(message);
  final String uuid;
  final Repository repository;

  @override
  String get message {
    return '${repository.runtimeType}: '
        '${super.message}: Pressure exceeded maximum: ${repository.maxPushPressure}';
  }
}

/// Thrown when an required repository is not available
class RepositoryNotAvailable extends InvalidOperation {
  const RepositoryNotAvailable(String message) : super(message);
}

/// Thrown when an uuid is null
class UUIDIsNull extends InvalidOperation {
  const UUIDIsNull(String message) : super(message);
}

/// Thrown when an [Command] is attempted on an [AggregateRoot] not found
class AggregateNotFound extends InvalidOperation {
  const AggregateNotFound(String message) : super(message);
}

/// Thrown when an [Command.action] with [Action.create] is attempted on an existing [AggregateRoot]
class AggregateExists extends InvalidOperation {
  const AggregateExists(String message, this.aggregate) : super(message);
  final AggregateRoot aggregate;
}

/// Thrown when an [Command] is attempted on an [EntityObject] not found
class EntityNotFound extends InvalidOperation {
  const EntityNotFound(String message) : super(message);
}

/// Thrown when an [Command.action] with [Action.create] is attempted on an existing [EntityObject]
class EntityExists extends InvalidOperation {
  const EntityExists(String message, this.entity) : super(message);
  final EntityObject entity;
}

/// Thrown when multiple push operations are invoked without waiting for
/// the result of each push. This prevents partial writes and commits
/// which will result in inconsistent local data or an [EventNumberMismatch]
/// being thrown by [EventStoreConnection.writeEvents]. Use a [Transaction]
/// if you want to execute multiple commands before pushing data.
class ConcurrentWriteOperation extends InvalidOperation {
  const ConcurrentWriteOperation(String message, this.transaction) : super(message);
  final Transaction transaction;

  @override
  String toString() {
    return '$runtimeType{message: $message,\n'
        'seqnum: ${transaction.seqnum},\n'
        'startedBy: ${transaction.startedBy},\n'
        'startedAt: ${Trace.format(transaction.startedAt)}}';
  }
}

/// Thrown when writing events and 'ES-ExpectedVersion' differs from 'ES-CurrentVersion'
class WrongExpectedEventVersion extends InvalidOperation {
  const WrongExpectedEventVersion(
    String message, {
    @required this.stream,
    @required this.expected,
    @required this.actual,
  }) : super(message);
  final String stream;
  final EventNumber actual;
  final ExpectedVersion expected;

  @override
  String toString() {
    return '$runtimeType{stream: $stream, expected: ${expected.value}, actual: ${actual.value}, message: $message}';
  }
}

/// Thrown when automatic merge resolution is not possible
class ConflictNotReconcilable extends InvalidOperation {
  const ConflictNotReconcilable(
    String message, {
    @required this.base,
    @required this.mine,
    @required this.yours,
    @required this.conflicts,
  }) : super(message);
  final List<String> conflicts;
  final Map<String, dynamic> base;
  final List<Map<String, dynamic>> mine;
  final List<Map<String, dynamic>> yours;

  factory ConflictNotReconcilable.empty(String message) => ConflictNotReconcilable(
        message,
        base: const {},
        mine: const [],
        yours: const [],
        conflicts: const [],
      );

  @override
  String toString() {
    return '$runtimeType{message: $message, local: $mine, remote: $yours}';
  }
}

/// Thrown when an write failed
class WriteFailed extends EventSourceException {
  const WriteFailed(String message) : super(message);
}

/// Thrown when catchup ended in mismatch between current number and number in remote event stream
class EventNumberMismatch extends WriteFailed implements Exception {
  EventNumberMismatch({
    String stream,
    String message,
    EventNumber actual,
    EventNumber current,
  }) : super(
          '$message: stream $stream current event number ($current) not equal to actual ($actual)',
        );
}

/// Thrown when [MergeStrategy] fails to reconcile [WrongExpectedEventVersion] after maximum number of attempts
class EventVersionReconciliationFailed extends WriteFailed {
  const EventVersionReconciliationFailed(WrongExpectedEventVersion cause, int attempts)
      : super('Failed to reconcile $cause after $attempts attempts');
}

/// Thrown when more then one [AggregateRoot] has changes concurrently
class MultipleAggregatesWithChanges extends WriteFailed {
  const MultipleAggregatesWithChanges(String message) : super(message);
}

/// Thrown when an stream [AtomFeed] operation failed
class FeedFailed extends EventSourceException {
  const FeedFailed(String message) : super(message);
}

/// Thrown when an stream [Event] subscription failed
class SubscriptionFailed extends EventSourceException {
  const SubscriptionFailed(String message) : super(message);
}
