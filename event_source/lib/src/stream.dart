import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';

class StreamRequestQueue<T> {
  StreamRequestQueue();

  Type get type => typeOf<T>();

  /// List of [StreamRequest.key]s.
  ///
  /// Used to track and dequeue requests.
  final _requests = <StreamRequest<T>>[];

  /// Stream of last [StreamResult] processed before stopping
  final StreamController<StreamResult<T>> _idleController = StreamController.broadcast();

  /// Stream of [StreamRequest] timeouts
  final StreamController<StreamRequest<T>> _timeoutController = StreamController.broadcast();

  /// Stream of completed [StreamResult]
  final StreamController<StreamResult<T>> _completeController = StreamController.broadcast();

  /// Get number of processed [StreamRequest]s from creation
  int get processed => _timeouts + _failed + _cancelled + _completed;

  /// Get number of timeouts from creation
  int get timeouts => _timeouts;
  int _timeouts = 0;

  /// Get number of cancelled [StreamRequest] from creation
  int get cancelled => _cancelled;
  int _cancelled = 0;

  /// Get number of failed [StreamRequest] from creation
  int get failed => _failed;
  int _failed = 0;

  /// Get number of completed [StreamRequest] from creation
  int get completed => _completed;
  int _completed = 0;

  StreamQueue<StreamRequest<T>> _queue;
  StreamController<StreamRequest<T>> _dispatcher;

  /// Set Error callback.
  ///
  /// Use it to decide if queue should stop
  /// processing [StreamRequest]s until
  /// next time [process] is called based
  /// on [error].
  ///
  void catchError(bool Function(Object, StackTrace) onError) => _onError = onError;
  bool Function(Object, StackTrace) _onError;

  /// Get number of pending [StreamRequest];
  int get length => _requests.length;

  /// Check if queue is empty
  bool get isEmpty => _requests.isEmpty;

  /// Check if queue is ready for processing
  bool get isReady => !(_isDisposed || _queue == null);

  /// Check if queue is disposed
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Check if queue is not empty
  bool get isNotEmpty => _requests.isNotEmpty;

  /// Flag indicating that [process] should be called
  bool get isIdle => _isIdle || !isReady;
  bool _isIdle = true;

  /// Get stream of last [StreamResult]
  /// processed before stopping.
  Stream<StreamResult<T>> onIdle() => _idleController.stream;

  /// Get stream of [StreamRequest] timeouts.
  Stream<StreamRequest<T>> onTimeout() => _timeoutController.stream;

  /// Get stream of completed [StreamResult] .
  Stream<StreamResult<T>> onComplete() => _completeController.stream;

  /// Flag indicating that queue is [process]ing requests
  bool get isProcessing => isReady && !isIdle;

  /// Check if a [StreamRequest] with given [key] is queued
  bool contains(String key) {
    _checkState();
    return _requests.any((element) => element.key == key);
  }

  /// Returns the index of [StreamRequest] with given [key].
  int indexOf(String key) {
    _checkState();
    return _requests.indexWhere((element) => element.key == key);
  }

  /// Check if [StreamRequest] with given [key] is at head of queue
  bool isHead(String key) {
    _checkState();
    return _requests.isEmpty ? false : _requests.first.key == key;
  }

  /// Check if queue is executing [StreamRequest] with given [key]
  bool isCurrent(String key) {
    _checkState();
    return _current?.key == key;
  }

  /// Schedule singleton [request] for execution.
  /// This will cancel current requests.
  bool only(StreamRequest<T> request) {
    cancel();
    return add(request);
  }

  /// Schedule [request] for execution
  bool add(StreamRequest<T> request) {
    _checkState();
    _prepare();

    // Duplicates not allowed
    final exists = contains(request.key);
    if (!contains(request.key)) {
      _requests.add(request);
      _dispatcher.add(request);
    }

    // Start processing events
    // until isIdle is true.
    // If already processing
    // (not idle), the method
    // will do nothing
    _process();

    return !exists;
  }

  /// Remove [StreamRequest] with given [key] from queue.
  bool remove(String key) {
    _checkState();
    if (_current?.key == key) {
      return false;
    }
    final found = _requests.where((element) => element.key == key).toList();
    found.forEach(_requests.remove);
    _cancelled += found.length;
    return found.isNotEmpty;
  }

  /// Remove all pending [StreamRequest]s from queue.
  ///
  /// Returns a list of [StreamRequest]s.
  List<StreamRequest<T>> clear() {
    _checkState();
    final removed = _requests.toList();
    _cancelled += removed.length;
    _requests.clear();
    return removed;
  }

  /// Process scheduled requests
  Future<void> _process() async {
    if (isIdle) {
      try {
        _isIdle = false;
        while (_hasNext) {
          if (isProcessing) {
            final request = await _next();
            if (isProcessing) {
              _current = request;
              if (await _shouldExecute(request)) {
                if (isProcessing && contains(request.key)) {
                  _last = await _execute(request);
                }
              }
              _current = null;
            }
          }
        }
      } catch (e, stackTrace) {
        _handleError(e, stackTrace);
      } finally {
        await stop();
      }
    }
  }

  Future<StreamRequest> _pop() => _queue.next;

  Future<StreamRequest> _next() async {
    var next = await _queue.peek;
    while (next.isTimedOut || !contains(next.key)) {
      if (contains(next.key)) {
        _timeoutController.add(next);
        _requests.remove(next);
        _timeouts++;
        if (next.fail) {
          _handleError(
            StreamRequestTimeout(this, next),
            StackTrace.current,
            onResult: next.onResult,
          );
        } else if (next.fallback != null) {
          next.onResult?.complete(
            next.fallback(),
          );
        }
      }
      // Consume and peek next
      await _queue.next;
      next = await _queue.peek;
    }
    return next;
  }

  /// Prepare queue for requests
  void _prepare() {
    if (_dispatcher == null) {
      _dispatcher = StreamController();
      _queue = StreamQueue(
        _dispatcher.stream,
      );
    }
  }

  /// Get request currently processing
  StreamRequest<T> get current => _current;
  StreamRequest<T> _current;

  StreamResult<T> _last;

  /// Execute given [request]
  Future<StreamResult<T>> _execute(StreamRequest<T> request) async {
    try {
      final result = await request.execute();
      if (result.isStop) {
        await stop();
      } else {
        _requests.remove(request);
        _completeController.add(result);
        if (result.isError) {
          _failed++;
          _handleError(
            result.error,
            result.stackTrace,
            onResult: request.onResult,
          );
        } else {
          request.onResult?.complete(
            result.value,
          );
        }
        if (isReady) {
          await _pop();
        }
      }
      return result;
    } catch (error, stackTrace) {
      _failed++;
      _handleError(
        error,
        stackTrace,
        onResult: request.onResult,
      );
      return StreamResult(
        value: await request.fallback(),
      );
    }
  }

  /// Should only process next
  /// request if [isProcessing],
  /// if queue contains more
  /// requests.
  ///
  bool get _hasNext => isProcessing && _requests.isNotEmpty;

  Future<bool> _shouldExecute(StreamRequest<T> request) async {
    if (isProcessing && _requests.contains(request)) {
      return true;
    }
    if (request.onResult?.isCompleted == false && request.fallback != null) {
      _completed++;
      request.onResult?.complete(
        await request.fallback(),
      );
    }
    return false;
  }

  /// Error handler.
  /// Will complete [onResult]
  /// with given [error] and
  /// forward to [_onError]
  /// for analysis if queue
  /// should return to [isIdle]
  /// state.
  ///
  void _handleError(
    Object error,
    StackTrace stackTrace, {
    Completer<T> onResult,
  }) {
    if (onResult?.isCompleted == false) {
      onResult.completeError(
        error,
        stackTrace,
      );
    }
    if (_onError != null) {
      final shouldStop = _onError(
        error,
        stackTrace,
      );
      if (shouldStop) {
        stop();
      }
    }
  }

  /// Start processing requests.
  ///
  bool start() {
    _checkState();
    if (isIdle) {
      _process();
    }
    return isProcessing;
  }

  /// Stop processing requests.
  void stop() {
    if (isProcessing) {
      _isIdle = true;
      // Notify listeners
      _idleController?.add(_last);
    }
  }

  /// Clear all pending requests
  /// and stop processing events.
  ///
  void cancel() async {
    _checkState();
    _cancelled += clear().length;
    stop();
  }

  /// Dispose queue. Can not be used afterwords
  ///
  /// The returned future completes with the result of calling
  /// `cancel` of the underlying stream.
  ///
  Future<void> dispose() async {
    _checkState();
    _cancelled += clear().length;
    if (!_isDisposed) {
      clear();
      stop();
      _isDisposed = true;
      if (_requests.isNotEmpty && _queue != null) {
        await _queue.cancel(immediate: true);
      }
      _queue = null;
      _current = null;
      _dispatcher = null;
      if (_idleController.hasListener) {
        await _idleController.close();
      }
      if (_timeoutController.hasListener) {
        await _timeoutController.close();
      }
      if (_completeController.hasListener) {
        await _completeController.close();
      }
    }
  }

  void _checkState() {
    assert(!_isDisposed, '$runtimeType is disposed');
  }
}

@Immutable()
class StreamRequest<T> {
  StreamRequest({
    @required this.execute,
    String key,
    this.tag,
    this.timeout,
    this.fallback,
    this.onResult,
    this.fail = false,
  }) : _key = key;

  final bool fail;
  final Object tag;
  final Duration timeout;
  final Completer<T> onResult;
  final Future<T> Function() fallback;
  final DateTime created = DateTime.now();
  final Future<StreamResult<T>> Function() execute;

  bool get isTimedOut => timeout != null && DateTime.now().difference(created) > timeout;

  Object get key => _key ?? '${super.hashCode}';
  final Object _key;

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StreamRequest && runtimeType == other.runtimeType && key == other.key;
}

@Immutable()
class StreamResult<T> {
  StreamResult({
    this.tag,
    bool stop,
    this.value,
    this.error,
    this.stackTrace,
  }) : _stop = stop ?? false;

  static StreamResult<T> none<T>() => StreamResult<T>();
  static StreamResult<T> stop<T>() => StreamResult<T>(stop: true);

  final T value;
  final Object tag;
  final bool _stop;
  final Object error;
  final StackTrace stackTrace;

  bool get isStop => _stop;
  bool get isComplete => !isStop;
  bool get isError => error != null;
}

class StreamRequestTimeout implements Exception {
  StreamRequestTimeout(this.queue, this.request);
  final StreamRequest request;
  final StreamRequestQueue queue;
}
