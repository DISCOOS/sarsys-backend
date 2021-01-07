import 'dart:async';

import 'package:meta/meta.dart';
import 'package:aqueduct/aqueduct.dart';
import 'package:event_source/event_source.dart';

abstract class PolicyUtils {
  static const int defaultTimeout = 10000;

  /// Wait for given rule result from stream of results
  static Future<Iterable<Event>> waitForRuleResult<T extends Event>(
    Repository repository, {
    int count = 1,
    bool fail = true,
    Duration timeout = const Duration(
      milliseconds: defaultTimeout,
    ),
    Logger logger,
  }) async {
    final events = <Event>[];
    try {
      await repository.onRuleResult
          .where(
            (event) {
              events.add(event);
              return event is T;
            },
          )
          .take(count)
          .last
          .timeout(timeout);
    } on TimeoutException catch (e, stackTrace) {
      if (fail) {
        final message = 'Waiting for (${typeOf<T>()} x $count) timed out after $timeout';
        logger?.severe('$message: $e: $stackTrace');
        throw message;
      }
    }
    return events;
  }

  /// Wait for given rule result from stream of results
  static Future<Iterable<Event>> waitForRuleResults(
    Repository repository, {
    @required Map<Type, int> expected,
    bool fail = true,
    Duration timeout = const Duration(
      milliseconds: defaultTimeout,
    ),
    Logger logger,
  }) async {
    final events = <Event>[];
    final actual = <Type, int>{};
    try {
      final count = expected.values.fold<int>(0, (count, expect) => count + expect);
      await repository.onRuleResult
          // Match expected events
          .where(
            (event) {
              events.add(event);
              final take = expected.containsKey(event.runtimeType);
              if (take) {
                actual.update(
                  event.runtimeType,
                  (count) => ++count,
                  ifAbsent: () => 1,
                );
              }
              return take;
            },
          )
          // Match against expected event number
          .take(count)
          // Complete when last event is received
          .last
          // Fail on time
          .timeout(timeout);
    } on TimeoutException catch (e, stackTrace) {
      if (fail) {
        final message = 'Waiting for $expected timed out after $timeout. Actual was: $actual, Seen: $events';
        logger?.severe('$message: $e: $stackTrace');
        throw message;
      }
    }
    return events;
  }
}
