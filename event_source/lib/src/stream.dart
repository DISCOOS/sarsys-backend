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

  /// Check if queue is executing given [request]
  bool isCurrent(StreamRequest<T> request) {
    _checkState();
    return _current == request;
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
    final found = _requests.where((element) => element.key == key)
      ..toList()
      ..forEach(_requests.remove);

    return found.isNotEmpty;
  }

  /// Remove all pending [StreamRequest]s from queue.
  ///
  /// Returns a list of [StreamRequest]s.
  List<StreamRequest<T>> clear() {
    _checkState();
    return _requests
      ..toList()
      ..clear();
  }

  /// Process scheduled requests
  Future<void> _process() async {
    StreamResult<T> result;

    if (isIdle) {
      try {
        _isIdle = false;
        while (_hasNext) {
          if (isProcessing) {
            final request = await _queue.peek;
            if (isProcessing) {
              if (contains(request.key)) {
                _current = request;
                if (await _shouldExecute(request)) {
                  if (isProcessing && contains(request.key)) {
                    result = await _execute(request);
                    _last = result;
                    if (result.isStop) {
                      stop();
                    }
                  }
                }
              }
              if (isReady) {
                await _queue.next;
                _requests.remove(request);
              }
            }
          }
        }
      } catch (e, stackTrace) {
        _handleError(e, stackTrace);
      } finally {
        stop();
      }
    }
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
      if (result.isOK) {
        request.onResult?.complete(
          result.value,
        );
      } else if (result.isError) {
        _handleError(
          result.error,
          result.stackTrace,
          onResult: request.onResult,
        );
      }
      return result;
    } catch (error, stackTrace) {
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
    clear();
    stop();
  }

  /// Dispose queue. Can not be used afterwords
  ///
  /// The returned future completes with the result of calling
  /// `cancel` of the underlying stream.
  ///
  Future<void> dispose() async {
    _checkState();
    if (!_isDisposed) {
      clear();
      stop();
      _isDisposed = true;
      if (_requests.isNotEmpty) {
        await _queue.cancel(immediate: true);
      }
      _queue = null;
      _current = null;
      _dispatcher = null;
      if (_idleController.hasListener) {
        await _idleController.close();
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
    this.fallback,
    this.onResult,
  }) : _key = key;

  final Completer<T> onResult;
  final Future<T> Function() fallback;
  final Future<StreamResult<T>> Function() execute;

  String get key => _key ?? '$hashCode';
  final String _key;
}

@Immutable()
class StreamResult<T> {
  const StreamResult({
    this.value,
    this.error,
    bool stop,
    this.stackTrace,
  }) : _stop = stop;

  static StreamResult<T> none<T>() => StreamResult<T>();
  static StreamResult<T> stop<T>() => StreamResult<T>(stop: true);

  final T value;
  final bool _stop;
  final Object error;
  final StackTrace stackTrace;

  bool get isOK => value != null;
  bool get isError => error != null;

  bool get isNone => !isComplete;
  bool get isStop => _stop == true;
  bool get isComplete => !isStop && (isOK || isError);
}
