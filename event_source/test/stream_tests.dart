import 'dart:async';

import 'package:event_source/src/stream.dart';
import 'package:test/test.dart';

void main() async {
  test('StreamRequestQueue should add, execute and remove request', () async {
    // Arrange
    final queue = StreamRequestQueue();
    final completer = Completer();
    final command = () async {
      return StreamResult.none();
    };
    final request = StreamRequest(
      execute: command,
      onResult: completer,
    );

    // Act
    final added = queue.add(request);

    // Assert BEFORE execution
    expect(added, isTrue, reason: 'should add');
    expect(queue.isHead(request.key), isTrue, reason: 'should be head');
    expect(queue.contains(request.key), isTrue, reason: 'should contain');

    // Assert AFTER execution
    await queue.onEvent().where((event) => event is StreamQueueIdle).first;
    expect(request.onResult.isCompleted, isTrue, reason: 'should execute');
    expect(queue.isIdle, isTrue, reason: 'should be idle');
    expect(queue.length, 0, reason: 'should be empty');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');
    expect(queue.isProcessing, isFalse, reason: 'should not be processing');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should remove pending request and continue', () async {
    // Arrange
    final queue = StreamRequestQueue();
    final completer = Completer();
    final command = () async {
      return StreamResult.none();
    };
    final request = StreamRequest(
      execute: command,
      onResult: completer,
    );
    queue.add(request);

    // Act
    final removed = queue.remove(request.key);

    // Assert
    expect(removed, isTrue, reason: 'should remove');
    expect(queue.length, 0, reason: 'should be empty');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');
    expect(queue.isIdle, isFalse, reason: 'should be not idle');
    expect(queue.isProcessing, isTrue, reason: 'should not processing');
    expect(queue.isCurrent(request.key), isFalse, reason: 'should be current');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should clear all pending request and continue', () async {
    // Arrange
    final queue = StreamRequestQueue();
    final command = () async {
      return StreamResult.none();
    };

    final requests = List.generate(
      10,
      (index) => StreamRequest(
        execute: command,
        onResult: Completer(),
      ),
    );
    requests.forEach(queue.add);
    final first = requests.first;
    expect(await first.onResult.future, isNull, reason: 'should execute');

    // Act
    final removed = queue.clear();

    // Assert
    expect(removed.length, 9, reason: 'should remove 9');
    expect(queue.length, 0, reason: 'should be empty');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');
    expect(queue.isIdle, isFalse, reason: 'should be not idle');
    expect(queue.isProcessing, isTrue, reason: 'should not processing');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should clear all pending request and stop', () async {
    // Arrange
    final queue = StreamRequestQueue();

    final requests = List.generate(
      10,
      (index) => StreamRequest(
        key: '$index',
        execute: () async {
          // Simulate long running
          // command to test if this
          // hangs processing.
          return Future<StreamResult>.delayed(
            // First item has zero delay
            Duration(hours: index),
            () => StreamResult.none(),
          );
        },
        onResult: Completer(),
      ),
    );
    requests.forEach(queue.add);

    // Wait for first delayed command (index == 1)
    while (queue.current == null || queue.current.key != '1') {
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Cancel pending commands
    queue.cancel();

    // Assert
    expect(queue.current, isNotNull, reason: 'should have current');
    expect(queue.cancelled, 9, reason: 'should remove 9');
    expect(queue.length, 0, reason: 'should be empty');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');
    expect(queue.isIdle, isTrue, reason: 'should be be idle');
    expect(queue.isProcessing, isFalse, reason: 'should not be processing');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should stop processing requests', () async {
    // Arrange
    final queue = StreamRequestQueue();

    final requests = List.generate(
      10,
      (index) => StreamRequest(
        key: '$index',
        execute: () async {
          // Simulate long running
          // command to test if this
          // hangs processing.
          return Future<StreamResult>.delayed(
            // First item has zero delay
            Duration(hours: index),
            () => StreamResult.none(),
          );
        },
        onResult: Completer(),
      ),
    );
    requests.forEach(queue.add);

    // Wait for first delayed command (index == 1)
    while (queue.current == null || queue.current.key != '1') {
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Stop processing commands
    queue.stop();

    // Assert
    expect(queue.current, isNotNull, reason: 'should have current');
    expect(queue.length, 9, reason: 'should be 9 left');
    expect(queue.isNotEmpty, isTrue, reason: 'should not be empty');
    expect(queue.isIdle, isTrue, reason: 'should be idle');
    expect(queue.isProcessing, isFalse, reason: 'should not be processing');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should resume processing requests', () async {
    // Arrange
    final queue = StreamRequestQueue();
    final command = () async {
      return StreamResult.none();
    };

    final requests = List.generate(
      10,
      (index) => StreamRequest(
        execute: command,
        onResult: Completer(),
      ),
    );
    requests.forEach(queue.add);

    // Wait for first command to be processed before stopping
    final first = requests.first;
    expect(await first.onResult.future, isNull, reason: 'should execute');
    queue.stop();

    // Act
    final started = queue.start();

    // Wait for queue to empty
    while (queue.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 10));
    }

    // Assert
    expect(started, isTrue, reason: 'should have resumed processing');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');

    // Cleanup
    queue.cancel();
  });

  test('StreamRequestQueue should throw StreamRequestTimeouts', () async {
    // Arrange
    var errors = 0;
    final onError = (Object e, StackTrace stackTrace) {
      errors++;
      return /*Don't stop*/ false;
    };
    final queue = StreamRequestQueue()..catchError(onError);
    final requests = List.generate(
      10,
      (index) => StreamRequest(
        fail: true,
        execute: () => Future.delayed(
          Duration(milliseconds: 2),
        ),
        onResult: Completer(),
        timeout: const Duration(milliseconds: 1),
      ),
    );

    // Act
    requests.forEach(queue.add);

    // Assert
    for (var request in requests) {
      await expectLater(
        request.onResult.future,
        throwsA(isA<StreamRequestTimeoutException>()),
        reason: 'should throw',
      );
    }
    expect(errors, 10, reason: 'should fail 10 times');
    expect(
      await queue.onEvent().where((e) => e is StreamQueueIdle).first,
      isNotNull,
    );
    expect(queue.isIdle, isTrue, reason: 'should be idle');
    expect(queue.isEmpty, isTrue, reason: 'should be empty');
    expect(queue.current, isNull, reason: 'should not have current');
    expect(queue.isProcessing, isFalse, reason: 'should not be processing');
    expect(queue.processed, 10, reason: 'should have processed 10 requests');
    expect(queue.timeouts, 10, reason: 'should have timed out 10 times');
    expect(queue.failures, 0, reason: 'should have failed zero times');

    // Cleanup
    queue.cancel();
  });
}
