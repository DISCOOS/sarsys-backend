import 'dart:math';

import 'package:meta/meta.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:event_source/event_source.dart';
import 'package:event_source/src/models/converters.dart';

import 'models/snapshot_model.dart';

/// [AggregateRoot] snapshot storage class
class Storage {
  Storage(
    this.type, {
    this.keep = 20,
    this.automatic = true,
    this.threshold = 1000,
  }) : logger = Logger('Storage');

  /// Create storage for given [AggregateRoot] type [T]
  static Storage fromType<T extends AggregateRoot>({
    int keep = 20,
    int threshold = 1000,
    bool automatic = true,
  }) =>
      Storage(
        typeOf<T>(),
        keep: keep,
        automatic: automatic,
        threshold: threshold,
      );

  /// Logger instance
  final Logger logger;

  /// Get [AggregateRoot] type stored
  final Type type;

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
  SnapshotModel operator [](String uuid) => get(uuid);

  /// Get number of states
  int get length => isReady ? _states.length : 0;

  /// Get all (key,value)-pairs as unmodifiable map
  Map<String, SnapshotModel> get map =>
      Map.unmodifiable(isReady ? Map.fromIterables(keys, values) : <String, SnapshotModel>{});

  /// Get all uuids as unmodifiable list
  Iterable<String> get keys => List.unmodifiable(isReady ? _states?.keys : []);

  /// Get all values as unmodifiable list
  Iterable<SnapshotModel> get values =>
      List.unmodifiable(isReady ? _states.values.map((state) => state.value) : <SnapshotModel>[]);

  /// Check if key exists
  bool contains(String uuid) => isReady ? _states.keys.contains(uuid) : false;

  /// Get [SnapshotModel] with the lowest event number
  SnapshotModel get first {
    final models = _sort(
      (s1, s2) => s1.number.value - s2.number.value,
    );
    return models.isEmpty ? null : models.first;
  }

  /// Get [SnapshotModel] with the highest event number
  SnapshotModel get last {
    final models = _sort(
      (s1, s2) => s1.number.value - s2.number.value,
    );
    return models.isEmpty ? null : models.last;
  }

  Iterable<SnapshotModel> _sort(int Function(SnapshotModel a, SnapshotModel b) compare) {
    final sorted = values.toList();
    sorted.sort(
      compare,
    );
    return sorted;
  }

  Box<StorageState> _states;

  /// Get storage filename
  String get filename => type.toKebabCase();

  /// Reads [states] from storage
  @visibleForOverriding
  Future<Iterable<StorageState>> load() async {
    _states = await Hive.openBox<StorageState>(filename);
    // Get mapped states
    return _states.values;
  }

  /// Get [SnapshotModel] from [uuid]
  SnapshotModel get(String uuid) => getState(uuid)?.value;

  /// Get [StorageState] from [uuid]
  StorageState getState(String uuid) => isReady && _isNotNull(uuid) && contains(uuid) ? _states?.get(uuid) : null;
  bool _isNotNull(String uuid) => uuid != null;

  /// Add [StorageState] for given
  /// [repo] if [Repository.number]
  /// larger then [last.number].
  SnapshotModel add(Repository repo) {
    checkState();
    var model = repo.snapshot;
    if (isEmpty || last.number.value < repo.number.value) {
      model = toSnapshot(repo);
      _states.put(
        model.uuid,
        StorageState(value: model),
      );
      logger.info(
        'Added snapshot ${model.uuid} of '
        '${repo.runtimeType}@${model.number.value}',
      );
    }
    // Always keep 1 snapshot
    if (length > max(keep ?? 1, 1)) {
      final model = _states.get(first.uuid).value;
      _states.delete(first.uuid);
      logger.info(
        'Deleted snapshot ${model.uuid} of '
        '${repo.runtimeType}@${model.number.value}',
      );
    }
    return model;
  }

  /// Check if [Repository] is disposed
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Asserts that storage is operational.
  /// Should be called before methods is called.
  /// If not ready an [StorageNotReadyException] is thrown
  /// If disposed an [StorageIsDisposedException] is thrown
  @protected
  void checkState() {
    if (_states?.isOpen != true) {
      throw StorageNotReadyException(this);
    } else if (_isDisposed) {
      throw StorageIsDisposedException(this);
    }
  }

  /// Dispose storage
  ///
  /// After this point it
  /// can not used again.
  Future<void> dispose() async {
    _isDisposed = true;
    await _states.close();
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
  StorageException(this.message, {this.state, this.stackTrace});
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
