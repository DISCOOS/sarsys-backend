import 'dart:async';

import 'package:event_source/event_source.dart';
import 'package:meta/meta.dart';
import 'package:async/async.dart';

class StreamRequestQueue<T> {
  StreamRequestQueue();

  Type get type => typeOf<T>();

  /// List of scheduled [StreamRequest]s.
  ///
  /// Used to track and dequeue requests.
  final _requests = <StreamRequest<T>>[];

  /// List of peeked [StreamRequest]s.
  ///
  /// Used to track and dequeue requests.
  final _scheduled = <StreamRequest<T>>{};

  /// Stream of [StreamEvent]s
  final StreamController<StreamEvent> _onEventController = StreamController.broadcast();

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

  /// Get stream of [StreamEvent]s.
  Stream<StreamEvent> onEvent() => _onEventController.stream;

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

  /// Get [StreamRequest] from given [key].
  ///Returns [null] if not found.
  StreamRequest<T> elementAt(String key) {
    return contains(key) ? _requests[indexOf(key)] : null;
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
    if (!exists) {
      _requests.add(request);
      _dispatcher.add(request);
      _onEventController.add(StreamRequestAdded(
        request,
      ));
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
    found.forEach(_scheduled.remove);
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
              if (contains(request.key)) {
                _current = request;
                if (await _shouldExecute(request)) {
                  if (isProcessing && contains(request.key)) {
                    _last = await _execute(request);
                  }
                }
                _current = null;
              }
            }
            // If skipped
            await _pop(request);
          }
        }
      } catch (e, stackTrace) {
        _handleError(e, stackTrace);
      }
      stop();
    }
  }

  Future _pop(StreamRequest request) {
    if (_scheduled.remove(request) && !_isDisposed) {
      _requests.remove(request);
      return _queue.next;
    }
    return Future.value();
  }

  Future<StreamRequest> _next() async {
    var next = await _peek();
    // Loop until valid request is found
    while (next != null && (next.isTimedOut || !contains(next.key))) {
      if (contains(next.key)) {
        _onEventController.add(StreamRequestTimeout(
          next,
        ));
        await _pop(next);
        _timeouts++;
        if (next.fail) {
          _handleError(
            StreamRequestTimeoutException(this, next),
            StackTrace.current,
            request: next,
          );
        } else if (next.onResult?.isCompleted == false) {
          next.onResult?.complete(
            await _onFallback(next),
          );
        }
      }
      // Peek for next request if exists
      next = await _peek();
    }
    return next;
  }

  Future<StreamRequest> _peek() async {
    final next = _hasNext ? await _queue.peek : null;
    if (next != null) {
      _scheduled.add(next);
    }
    return next;
  }

  Future<T> _onFallback(StreamRequest<T> request) => request.fallback == null ? Future<T>.value() : request.fallback();

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
      _last = await request.execute();
      return _onComplete(
        request,
        _last,
      );
    } catch (error, stackTrace) {
      _failed++;
      _handleError(
        error,
        stackTrace,
        request: request,
      );
      final result = StreamResult(
        value: await _onFallback(request),
      );
      _onEventController.add(StreamRequestCompleted(
        request,
        result,
      ));
      return result;
    }
  }

  Future<StreamResult<T>> _onComplete(
    StreamRequest<T> request,
    StreamResult<T> result,
  ) async {
    await _pop(request);
    _onEventController.add(StreamRequestCompleted(
      request,
      result,
    ));
    if (result.isStop) {
      stop();
    } else if (result.isError) {
      _failed++;
      _handleError(
        result.error,
        result.stackTrace,
        request: request,
      );
    } else if (request.onResult?.isCompleted == false) {
      request.onResult?.complete(
        result.value,
      );
    }
    return result;
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
    if (request.onResult?.isCompleted == false) {
      _completed++;
      request.onResult?.complete(
        await _onFallback(request),
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
    StreamRequest<T> request,
  }) {
    _pop(request);
    if (_onError != null) {
      final shouldStop = _onError(
        error,
        stackTrace,
      );
      if (shouldStop) {
        stop();
      }
    }
    if (request != null) {
      if (request.onResult?.isCompleted == false) {
        request.onResult.completeError(
          error,
          stackTrace,
        );
      }
      _onEventController.add(StreamRequestFailed(
        request,
        error,
        stackTrace,
      ));
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
      _onEventController.add(StreamQueueIdle());
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
      if (_onEventController.hasListener) {
        await _onEventController.close();
      }
    }
  }

  void _checkState() {
    assert(!_isDisposed, '$runtimeType is disposed');
  }

  @override
  String toString() => '$runtimeType{\n'
      '  isIdle: $_isIdle,\n'
      '  pending: ${_requests.length},\n'
      '  failed: $_failed,\n'
      '  timeouts: $_timeouts,\n'
      '  cancelled: $_cancelled,\n'
      '  completed: $_completed,\n'
      '  isDisposed: $_isDisposed\n}';
}

abstract class StreamEvent {}

@Immutable()
class StreamRequestAdded extends StreamEvent {
  StreamRequestAdded(this.request);
  final StreamRequest request;
}

@Immutable()
class StreamRequestTimeout extends StreamEvent {
  StreamRequestTimeout(this.request);
  final StreamRequest request;
}

@Immutable()
class StreamRequestFailed extends StreamEvent {
  StreamRequestFailed(this.request, this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
  final StreamRequest request;
}

@Immutable()
class StreamRequestCompleted extends StreamEvent {
  StreamRequestCompleted(this.request, this.result);
  final StreamRequest request;
  final StreamResult result;
}

@Immutable()
class StreamQueueIdle extends StreamEvent {
  StreamQueueIdle();
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

  @override
  String toString() => '$runtimeType{tag: $tag}';
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

  static StreamResult<T> none<T>({String tag}) => StreamResult<T>(tag: tag);
  static StreamResult<T> stop<T>({String tag}) => StreamResult<T>(tag: tag, stop: true);

  final T value;
  final Object tag;
  final bool _stop;
  final Object error;
  final StackTrace stackTrace;

  bool get isStop => _stop;
  bool get isComplete => !isStop;
  bool get isError => error != null;
}

class StreamRequestTimeoutException implements Exception {
  StreamRequestTimeoutException(this.queue, this.request);
  final StreamRequest request;
  final StreamRequestQueue queue;

  @override
  String toString() => '$runtimeType{\n'
      '  queue: $queue,\n '
      '  request: $request\n}';
}
