import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'core.dart';
import 'extension.dart';
import 'domain.dart';
import 'models/converters.dart';
import 'models/snapshot_model.dart';
import 'stream.dart';
import 'util.dart';

/// [AggregateRoot] snapshot storage class
class Storage {
  Storage(
    this.type, {
    this.prefix,
    this.keep = 20,
    this.automatic = true,
    this.threshold = 1000,
  }) : logger = Logger('Storage') {
    _eventSubscriptions.add(_saveQueue.onEvent().listen(
          (e) => _onQueueEvent('Save', e),
        ));
  }

  /// Create storage for given [AggregateRoot] type [T]
  static Storage fromType<T extends AggregateRoot>({
    String prefix,
    int keep = 20,
    int threshold = 1000,
    bool automatic = true,
  }) =>
      Storage(
        typeOf<T>(),
        keep: keep,
        prefix: prefix,
        automatic: automatic,
        threshold: threshold,
      );

  /// Logger instance
  final Logger logger;

  /// Get [AggregateRoot] type stored
  final Type type;

  /// File prefix
  final String prefix;

  /// Only save automatically if enabled
  bool automatic;

  /// Number of snapshot to keep.
  /// When exceeded [first] is
  /// deleted automatically.
  int keep;

  /// Maximum number events
  /// applied to repository before
  /// snapshot is saved automatically.
  int threshold;

  /// Check if storage is operational
  bool get isReady => _isReady();

  /// Check if storage is not operational
  @mustCallSuper
  bool get isNotReady => !_isReady();
  bool _isReady() => _states?.isOpen == true && _isDisposed == false;

  /// Check if storage is empty
  ///
  /// If [isReady] is [true], then [isNotEmpty] is always [false]
  bool get isNotEmpty => !isEmpty;

  /// Check if storage is empty.
  ///
  /// If [isReady] is [true], then [isEmpty] is always [true]
  bool get isEmpty => !isReady || _states.isEmpty;

  /// Get [SnapshotModel] from [uuid]
  Future<SnapshotModel> operator [](String uuid) => get(uuid);

  /// Get number of states
  int get length => isReady ? _states.length : 0;

  /// Get all (key,value)-pairs as unmodifiable map
  Future<Map<String, SnapshotModel>> get map async {
    final map = <String, SnapshotModel>{};
    if (isReady) {
      for (var uuid in _states.keys) {
        final state = await _states.get(uuid);
        map[uuid as String] = state.value;
      }
    }
    return map;
  }

  /// Get all uuids as unmodifiable list
  Iterable<String> get keys => List.unmodifiable(isReady ? _states?.keys : []);

  /// Get all values as unmodifiable list
  Future<Iterable<SnapshotModel>> get values async {
    final values = <SnapshotModel>[];
    if (isReady) {
      for (var uuid in _states.keys) {
        final state = await _states.get(uuid);
        values.add(state.value);
      }
    }
    return values;
  }

  /// Check if key exists
  bool contains(String uuid) => isReady ? _states.keys.contains(uuid) : false;

  /// Get [SnapshotModel] with the lowest event number
  String get first {
    return _sorted.isEmpty ? null : _sorted.keys.first;
  }

  /// Get current model
  SnapshotModel _last;

  /// Get [SnapshotModel] with the highest event number
  SnapshotModel get last {
    return _last;
  }

  void _setLast(SnapshotModel model) {
    if (_last == null || model.number.value > _last.number.value) {
      _last = model;
      _sort({
        model.uuid: model.number.value,
      });
    }
  }

  /// Get [EventNumber] of [SnapshotModel] with given [uuid]
  /// If SnapshotModel is not found [EventNumber.none] is
  /// returned
  EventNumber getNumber(String uuid) => _sorted.containsKey(uuid) ? EventNumber(_sorted[uuid]) : EventNumber.none;

  /// Map of uuids sorted on event number
  final LinkedHashMap<String, int> _sorted = LinkedHashMap();

  Iterable<String> _sort(
    Map<String, int> models,
  ) {
    if (models.keys.any((uuid) => !_sorted.containsKey(uuid))) {
      _sorted.addAll(models);
      return sortMapValues<String, int>(
        _sorted,
        compare: (n1, n2) => n1 - n2,
      ).keys;
    }
    return _sorted.keys;
  }

  LazyBox<StorageState> _states;

  /// Get storage filename
  String get filename => [prefix, type.toKebabCase()].where((s) => s != null).join('-');

  /// Validate given file.
  ///
  /// If box with same name as filename
  /// without extension exists,
  /// validate will return false.
  ///
  Future<bool> validate(File file, {bool allowEmpty = false}) async {
    try {
      final filename = basenameWithoutExtension(file.path);
      final box = await Hive.openBox<StorageState>(
        filename,
        path: file.parent.path,
      );
      final isValid = allowEmpty || box.keys.isNotEmpty;
      await box.close();
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// Reads [states] from storage.
  /// Returns keys in sorted order from first to last
  @visibleForOverriding
  Future<Iterable<String>> load({String path}) async {
    _states = await Hive.openLazyBox<StorageState>(
      filename,
      path: path,
    );
    SnapshotModel last;
    final models = <String, int>{};
    for (var uuid in keys) {
      final model = await get(uuid);
      models[model.uuid] = model.number.value;
      if (last == null || model.number.value > last.number.value) {
        last = model;
      }
    }
    _last = last;
    final suuids = _sort(
      models,
    );
    return List.from(suuids);
  }

  /// Unload [states] from memory
  @visibleForOverriding
  Future<Iterable<String>> unload({String path}) async {
    final keys = List<String>.from(_states.keys);
    await _states.close();
    return keys;
  }

  /// Get [SnapshotModel] from [uuid]
  Future<SnapshotModel> get(String uuid) async {
    if (contains(uuid)) {
      final state = await getState(uuid);
      return state.value;
    }
    return null;
  }

  /// Get [StorageState] from [uuid]
  Future<StorageState> getState(String uuid) =>
      isReady && _isNotNull(uuid) && contains(uuid) ? _states?.get(uuid) : null;
  bool _isNotNull(String uuid) => uuid != null;

  /// Get number of [save] requests waiting to be executed
  int get pressure {
    return _saveQueue.length;
  }

  /// Future returning when queues returns to idle
  Future get onIdle => _saveQueue.isIdle ? null : _saveQueue.onEvent().firstWhere((e) => e is StreamQueueIdle);

  /// Queue processing save in progress
  final StreamRequestQueue<SnapshotModel> _saveQueue = StreamRequestQueue();

  /// List of queue event subscriptions
  final List<StreamSubscription> _eventSubscriptions = [];

  /// Map of metrics
  final Map<String, DurationMetric> _metrics = {
    'save': DurationMetric.zero,
  };

  StreamRequest _checkSlowSave(StreamRequest request) {
    final metric = _metrics['save'].now(request.created);
    if (metric.duration.inMilliseconds > 50) {
      logger.warning(
        'SLOW SAVE: Request ${request.tag} took ${metric.duration.inMilliseconds} ms',
      );
    }
    _metrics['save'] = metric;
    return request;
  }

  /// Common queue event handler
  void _onQueueEvent(String queue, StreamEvent event) {
    switch (event.runtimeType) {
      case StreamRequestAdded:
        final request = (event as StreamRequestAdded).request;
        logger.fine(
          '$queue request added: ${request.tag} (${_toPressureString()})',
        );
        break;
      case StreamRequestCompleted:
        final request = _checkSlowSave(
          (event as StreamRequestCompleted).request,
        );
        logger.fine(
          '$queue request completed in '
          '${DateTime.now().difference(request.created).inMilliseconds} ms: '
          '${request.tag} (${_toPressureString()})',
        );
        break;
      case StreamQueueIdle:
        logger.fine('Save queue idle');
        break;
      case StreamRequestTimeout:
        final failed = event as StreamRequestTimeout;
        _onQueueError(
          failed.request,
          '$queue request timeout',
          StreamRequestTimeoutException(_saveQueue, failed.request),
        );
        break;
      case StreamRequestFailed:
        final failed = event as StreamRequestFailed;
        _onQueueError(
          failed.request,
          '$queue request failed',
          failed.error,
          failed.stackTrace,
        );
        break;
    }
  }

  void _onQueueError(StreamRequest request, String message, Object error, [StackTrace stackTrace]) {
    logger.network(
      '$message: ${request.tag} (${_toPressureString()})',
      error,
      stackTrace,
    );
  }

  String _toPressureString() => 'queue pressure: $pressure';

  /// Save [StorageState] for given
  /// [repo] if [Repository.number]
  /// is larger then [last].
  SnapshotModel save(Repository repo) {
    var model = repo.snapshot;
    if (isReady) {
      if (isEmpty || !repo.hasSnapshot || last.number.value < repo.number.value) {
        final candidate = toSnapshot(repo);
        final tag = 'snapshot ${candidate.uuid} ${candidate.isPartial ? '(partial) of' : 'of'} '
            '${candidate.type}@${candidate.number.value} '
            'with ${candidate.aggregates.length} aggregates';
        final key = '${candidate.number}';
        final added = _saveQueue.add(StreamRequest<SnapshotModel>(
          key: key,
          tag: tag,
          fail: true,
          execute: () => _save(
            repo,
            candidate,
            tag,
          ),
        ));
        // Prevent repeated adds
        if (added) {
          _setLast(candidate);
        }
        logger.fine(
          added
              ? 'Scheduled save: $tag (queue pressure: ${_saveQueue.length})'
              : 'Waiting on save already scheduled: $tag (queue pressure: ${_saveQueue.length})',
        );
        model = candidate;
      }
    }
    return model;
  }

  Future<StreamResult<SnapshotModel>> _save(Repository repo, SnapshotModel model, String tag) async {
    if (isReady) {
      await _states.put(
        model.uuid,
        StorageState(value: model),
      );
      logger.info(
        'Added $tag to storage',
      );
      await purge(repo);
      return StreamResult(
        tag: tag,
        value: model,
      );
    }
    return StreamResult.none(
      tag: tag,
    );
  }

  Future<Iterable<String>> purge(Repository repo) async {
    final deleted = <String>[];
    if (isReady) {
      // Always keep 1 snapshot
      final count = length - max<int>(keep ?? 1, 1);
      if (count > 0) {
        final delete = _sorted.keys.take(count);
        for (var uuid in delete) {
          if (contains(uuid)) {
            await _states.delete(
              first,
            );
            logger.info(
              'Deleted snapshot $first of '
              '${repo.runtimeType}@${_sorted[first]}',
            );
            _sorted.remove(first);
            deleted.add(uuid);
          }
        }
      }
    }
    return deleted;
  }

  /// Check if [Repository] is disposed
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Dispose storage
  ///
  /// After this point it
  /// can not used again.
  Future<void> dispose() async {
    _isDisposed = true;
    await _states.close();
    await Future.wait(_eventSubscriptions.map(
      (s) => s.cancel(),
    ));
    _eventSubscriptions.clear();
  }

  /// Get metadata for snapshot with given [uuid]
  Future<Map<String, dynamic>> toMeta({
    Type type,
    String uuid,
    EventNumber current,
    bool data = false,
    bool items = false,
  }) async {
    final snapshot = await get(uuid);
    final withSnapshot = snapshot != null;
    final withNumber = withSnapshot && current != null;
    return {
      if (withSnapshot) 'uuid': snapshot.uuid,
      if (withSnapshot) 'number': snapshot.number.value,
      'keep': keep,
      'automatic': automatic,
      if (withNumber) 'unsaved': current.value - snapshot.number.value,
      'threshold': threshold,
      if (withSnapshot && snapshot.isPartial) 'partial': {'missing': snapshot.missing},
      'metrics': {
        'save': _metrics['save'].toMeta(),
      },
      if (withSnapshot)
        'aggregates': {
          'count': snapshot.aggregates.length,
          if (items)
            'items': [
              ...snapshot.aggregates.values
                  .map((a) => {
                        'uuid': a.uuid,
                        if (type != null) 'type': '$type',
                        'number': a.number.value,
                        'created': <String, dynamic>{
                          'uuid': a.createdBy?.uuid,
                          'type': '${a.createdBy?.type}',
                          'timestamp': a.createdWhen.toIso8601String(),
                        },
                        'changed': <String, dynamic>{
                          'uuid': a.changedBy?.uuid,
                          'type': '${a.changedBy?.type}',
                          'timestamp': a.changedWhen.toIso8601String(),
                        },
                        if (data) 'data': a.data,
                      })
                  .toList(),
            ]
        },
    };
  }

  static int _typeId = 0;
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> init({
    bool Function(Object, StackTrace) onError,
  }) async {
    if (!_isInitialized) {
      Hive.registerAdapter(
        StorageStateJsonAdapter(
          onError: onError,
          typeId: ++_typeId,
          toJson: (model) => model.toJson(),
          fromJson: (json) => SnapshotModel.fromJson(json),
        ),
      );

      _isInitialized = true;
    }
  }
}

class StorageState {
  StorageState({
    @required this.value,
    this.error,
  });
  final Object error;
  final SnapshotModel value;

  bool get isError => error != null;
  EventNumber get number => EventNumber(value.number.value);

  @override
  String toString() {
    return '$runtimeType {number: $number, value: ${_toValueAsString()}}';
  }

  String _toValueAsString() => '${value?.runtimeType} ${value.uuid}';
}

class StorageStateJsonAdapter extends TypeAdapter<StorageState> {
  StorageStateJsonAdapter({
    this.typeId,
    this.toJson,
    this.onError,
    this.fromJson,
  });

  @override
  final typeId;

  final bool Function(Object, StackTrace) onError;

  final Map<String, dynamic> Function(SnapshotModel data) toJson;
  final SnapshotModel Function(Map<String, dynamic> data) fromJson;

  @override
  StorageState read(BinaryReader reader) {
    var error;
    SnapshotModel value;
    var json = reader.readMap();
    try {
      value = json['value'] != null ? fromJson(Map<String, dynamic>.from(json['value'] as Map)) : null;
    } on ArgumentError catch (e, stackTrace) {
      error = _handleError(e, stackTrace);
      if (onError == null) {
        rethrow;
      }
    } on Exception catch (e, stackTrace) {
      error = _handleError(e, stackTrace);
      if (onError == null) {
        rethrow;
      }
    }
    return StorageState(
      value: value,
      error: error?.toString(),
    );
  }

  Object _handleError(Object error, StackTrace stackTrace) {
    if (onError != null) {
      onError(error, stackTrace);
    }
    return error;
  }

  @override
  void write(BinaryWriter writer, StorageState state) {
    var value;
    var error;
    try {
      value = state.value != null ? toJson(state.value) : null;
    } on ArgumentError catch (e, stackTrace) {
      error = _handleError(e, stackTrace);
      if (onError == null) {
        rethrow;
      }
    } on Exception catch (e, stackTrace) {
      error = _handleError(e, stackTrace);
      if (onError == null) {
        rethrow;
      }
    }
    writer.writeMap({
      'value': value,
      'error': state.isError || error != null ? '${error ?? state.error}' : null,
    });
  }
}

class StorageException implements Exception {
  final String message;
  final StorageState state;
  final StackTrace stackTrace;
  StorageException(
    this.message, {
    this.state,
    StackTrace stackTrace,
  }) : stackTrace = StackTrace.current;
  @override
  String toString() {
    return '$runtimeType: {message: $message, state: $state, stackTrace: ${Trace.format(stackTrace)}}';
  }
}

class StorageNotReadyException extends StorageException {
  StorageNotReadyException(this.storage) : super('${storage.runtimeType} is not ready');
  final Storage storage;
}

class StorageIsDisposedException extends StorageException {
  StorageIsDisposedException(this.storage) : super('${storage.runtimeType} is disposed');
  final Storage storage;
}
