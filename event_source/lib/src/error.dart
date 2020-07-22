import 'package:meta/meta.dart';

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

/// Thrown when an required projection is not available
class ProjectionNotAvailable extends InvalidOperation {
  const ProjectionNotAvailable(String message) : super(message);
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
  const AggregateExists(String message) : super(message);
}

/// Thrown when an [Command] is attempted on an [EntityObject] not found
class EntityNotFound extends InvalidOperation {
  const EntityNotFound(String message) : super(message);
}

/// Thrown when an [Command.action] with [Action.create] is attempted on an existing [EntityObject]
class EntityExists extends InvalidOperation {
  const EntityExists(String message) : super(message);
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
  }) : super(message);
  final Map<String, dynamic> base;
  final List<Map<String, dynamic>> mine;
  final List<Map<String, dynamic>> yours;

  factory ConflictNotReconcilable.empty(String message) => ConflictNotReconcilable(
        message,
        base: const {},
        mine: const [],
        yours: const [],
      );

  @override
  String toString() {
    return '$runtimeType{local: $mine, remote: $yours}';
  }
}

/// Thrown when an write failed
class WriteFailed extends EventSourceException {
  const WriteFailed(String message) : super(message);
}

/// Thrown when catchup ended in mismatch between current number and number in remote event stream
class EventNumberMismatch extends WriteFailed implements Exception {
  EventNumberMismatch(String stream, EventNumber current, EventNumber actual, String message)
      : super('$message: stream $stream current event number ($current) not equal to actual ($actual)');
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
