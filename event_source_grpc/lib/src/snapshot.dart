import 'dart:async';
import 'dart:io';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:event_source/event_source.dart';
import 'package:event_source_grpc/src/generated/file.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/src/server/call.dart';
import 'package:logging/logging.dart';
import 'package:stack_trace/stack_trace.dart';

import 'generated/snapshot.pbgrpc.dart';
import 'utils.dart';

class SnapshotGrpcService extends SnapshotServiceBase {
  SnapshotGrpcService(this.manager, this.dataPath);
  final String dataPath;
  final RepositoryManager manager;
  final logger = Logger('$SnapshotGrpcService');

  @override
  Future<GetSnapshotMetaResponse> getMeta(ServiceCall call, GetSnapshotMetaRequest request) async {
    final type = request.type;
    final response = GetSnapshotMetaResponse()
      ..type = type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';

    if (call.isTimedOut) {
      final reason = _timeout('getMeta');
      response
        ..reasonPhrase = reason
        ..statusCode = StatusCode.deadlineExceeded;
      call.sendTrailers(
        message: reason,
        status: StatusCode.deadlineExceeded,
      );
      return response;
    }
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'getMeta',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Snapshot for aggregate $type not found';
    }
    final snapshots = repo.store.snapshots;
    if (snapshots == null) {
      _badRequest(
        'getMeta',
        'Snapshots not activated for repository $type',
      );
      return response
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = 'Snapshots not activated for repository $type';
    }
    final meta = await _toSnapshotMeta(
      type,
      repo.snapshot?.uuid,
      snapshots,
      repo.number,
      request.expand,
    );
    response.meta = toSnapshotMeta(
      type,
      meta,
      repo.store,
    );
    _log(
      'getMeta',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  Future<Map<String, dynamic>> _toSnapshotMeta(
    String type,
    String uuid,
    Storage storage,
    EventNumber current,
    List<SnapshotExpandFields> expand,
  ) async {
    return await storage.toMeta(
      uuid,
      type: type,
      current: current,
      data: withSnapshotField(
        expand,
        SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_DATA,
      ),
      items: withSnapshotField(
        expand,
        SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ITEMS,
      ),
    );
  }

  @override
  Future<ConfigureSnapshotResponse> configure(
    ServiceCall call,
    ConfigureSnapshotRequest request,
  ) async {
    final type = request.type;
    final response = ConfigureSnapshotResponse()
      ..type = type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';

    if (call.isTimedOut) {
      final reason = _timeout('configure');
      response
        ..reasonPhrase = reason
        ..statusCode = StatusCode.deadlineExceeded;
      call.sendTrailers(
        message: reason,
        status: StatusCode.deadlineExceeded,
      );
      return response;
    }

    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'configure',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Snapshot for aggregate $type not found';
    }
    final snapshots = repo.store.snapshots;
    if (snapshots == null) {
      _badRequest(
        'configure',
        'Snapshots not activated for repository $type',
      );
      return response
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = 'Snapshots not activated for repository $type';
    }

    // Configure
    snapshots
      ..keep = request.keep
      ..automatic = request.automatic
      ..threshold = request.threshold;

    final uuid = repo.snapshot?.uuid;
    if (uuid == null) {
      response
        ..meta = SnapshotMeta()
        ..reasonPhrase = 'No snapshot'
        ..statusCode = HttpStatus.noContent;
    } else {
      final meta = await _toSnapshotMeta(
        type,
        repo.snapshot?.uuid,
        snapshots,
        repo.number,
        request.expand,
      );
      response.meta = toSnapshotMeta(
        type,
        meta,
        repo.store,
      );
    }
    _log(
      'configure',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Future<SaveSnapshotResponse> save(
    ServiceCall call,
    SaveSnapshotRequest request,
  ) async {
    final type = request.type;
    final force = request.force;
    final response = SaveSnapshotResponse()
      ..type = type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'Snapshot saved (force was $force)';

    if (call.isTimedOut) {
      final reason = _timeout('save');
      response
        ..reasonPhrase = reason
        ..statusCode = StatusCode.deadlineExceeded;
      call.sendTrailers(
        message: reason,
        status: StatusCode.deadlineExceeded,
      );
      return response;
    }

    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'save',
        'Snapshot for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Snapshot for aggregate $type not found';
    }
    final snapshots = repo.store.snapshots;
    if (snapshots == null) {
      _badRequest(
        'save',
        'Snapshots not activated for repository $type',
      );
      return response
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = 'Snapshots not activated for repository $type';
    }

    final prev = repo.snapshot?.uuid;
    final next = repo.save(force: force).uuid;
    if (prev == next) {
      response
        ..statusCode = HttpStatus.noContent
        ..reasonPhrase = 'Snapshot not saved (force was $force)';
    } else {
      await repo.store.snapshots.onIdle;
    }
    final meta = await _toSnapshotMeta(
      type,
      repo.snapshot?.uuid,
      snapshots,
      repo.number,
      request.expand,
    );
    response.meta = toSnapshotMeta(
      type,
      meta,
      repo.store,
    );
    _log(
      'save',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Stream<FileChunk> download(ServiceCall call, DownloadSnapshotRequest request) async* {
    final type = request.type;

    if (call.isTimedOut) {
      call.sendTrailers(
        message: _timeout('save'),
        status: StatusCode.deadlineExceeded,
      );
      return;
    }

    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      call.sendTrailers(
        message: _notFound(
          'download',
          'Snapshot for aggregate $type not found',
        ),
        status: StatusCode.notFound,
      );
      return;
    }

    final snapshots = repo.store.snapshots;
    if (snapshots == null) {
      call.sendTrailers(
        message: _badRequest(
          'download',
          'Snapshots not activated for repository $type',
        ),
        status: StatusCode.unavailable,
      );
      return;
    }

    final old = snapshots.automatic;
    try {
      // Prevent snapshots being saved during download
      snapshots.automatic = false;

      var progress = 0;
      final chunkSize = request.chunkSize;
      final file = File(_toHiveFilePath(snapshots, 'hive'));
      final fileSize = Int64(file.statSync().size);
      final reader = ChunkedStreamIterator(file.openRead());

      // Streaming the contents from disk
      while (true) {
        var data = await reader.read(chunkSize.toInt());
        if (data.isEmpty) {
          break;
        }
        yield FileChunk()
          ..content = data
          ..fileSize = fileSize
          ..chunkSize = chunkSize
          ..fileName = snapshots.filename;
        progress += data.length;
        _log(
          'download',
          HttpStatus.ok,
          'Downloading $type snapshots...${((progress / fileSize.toInt()) * 100).toStringAsFixed(0)}%',
        );
      }
    } finally {
      snapshots.automatic = old;
    }
    call.sendTrailers(
      message: _log(
        'download',
        HttpStatus.ok,
        'Downloading $type snapshots...DONE',
      ),
      status: StatusCode.ok,
    );
  }

  @override
  Future<UploadSnapshotResponse> upload(ServiceCall call, Stream<SnapshotChunk> request) async {
    final stream = request.asBroadcastStream();
    final first = await stream.first;
    final type = first.type;

    if (call.isTimedOut) {
      final reason = _timeout('upload');
      call.sendTrailers(
        message: reason,
        status: StatusCode.deadlineExceeded,
      );
      return UploadSnapshotResponse()
        ..type = type
        ..chunkSize = first.chunk.chunkSize
        ..reasonPhrase = reason
        ..statusCode = StatusCode.deadlineExceeded;
    }

    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'upload',
        'Repository for aggregate $type not found',
      );
      return UploadSnapshotResponse()
        ..type = type
        ..chunkSize = first.chunk.chunkSize
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Snapshot for aggregate $type not found';
    }
    final snapshots = repo.store.snapshots;
    if (snapshots == null) {
      _badRequest(
        'upload',
        'Snapshots not activated for repository $type',
      );
      return UploadSnapshotResponse()
        ..type = type
        ..chunkSize = first.chunk.chunkSize
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = 'Snapshots not activated for repository $type';
    }

    final response = await _onUpload(repo, first, stream);
    _log(
      'upload',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  Future<UploadSnapshotResponse> _onUpload(
    Repository repo,
    SnapshotChunk first,
    Stream<SnapshotChunk> stream,
  ) async {
    final type = first.type;
    final snapshots = repo.store.snapshots;

    // Prevent writes and
    // snapshots being
    // saved during upload
    final old = snapshots.automatic;
    snapshots.automatic = false;
    repo.lock();
    repo.store.pause();

    // Take backup of hive files
    final postfix = '${DateTime.now().millisecondsSinceEpoch}';
    final hivePath = _backupFile(snapshots, postfix, 'hive');
    _backupFile(snapshots, postfix, 'lock');

    try {
      // Wait for storage to become idle
      await snapshots.onIdle;

      // Prepare file for uploading
      final name = '${repo.aggregateType.toLowerCase()}-upload-${DateTime.now().millisecondsSinceEpoch}.hive';
      final path = '${Directory.systemTemp.path}/$name';
      final file = File(path);

      // Write first chunk
      var progress = _writeChunk(file, 0, first);
      await for (var next in stream) {
        if (next.type != type) {
          return UploadSnapshotResponse()
            ..type = type
            ..chunkSize = first.chunk.chunkSize
            ..statusCode = HttpStatus.badRequest
            ..reasonPhrase = _badRequest(
              '_onUpload',
              'aggregate $type expected (found ${next.type})',
            );
        }
        progress = _writeChunk(file, progress, next);
      }

      // Wait for storage to become idle
      await snapshots.onIdle;

      final isValid = await snapshots.validate(file);
      if (isValid) {
        // Overwrite snapshots file
        await file.copy(hivePath);
        file.deleteSync();
      } else {
        return UploadSnapshotResponse()
          ..type = type
          ..chunkSize = first.chunk.chunkSize
          ..statusCode = HttpStatus.badRequest
          ..reasonPhrase = _badRequest(
            '_onUpload',
            'Unable to load snapshot data: Invalid file',
          );
      }

      // Attempt to reload
      final reloaded = await _reload(repo);
      if (reloaded) {
        final meta = await _toSnapshotMeta(
          type,
          repo.snapshot?.uuid,
          snapshots,
          repo.number,
          [SnapshotExpandFields.SNAPSHOT_EXPAND_FIELDS_ALL],
        );
        return UploadSnapshotResponse()
          ..type = type
          ..reasonPhrase = 'Uploading $type snapshots...DONE'
          ..statusCode = HttpStatus.ok
          ..chunkSize = first.chunk.chunkSize
          ..meta = toSnapshotMeta(
            type,
            meta,
            repo.store,
          );
      }
      return _doRestore(
        first,
        repo,
        postfix,
      );
    } catch (error, stackTrace) {
      return _doRestore(
        first,
        repo,
        postfix,
        stackTrace,
      );
    } finally {
      snapshots.automatic = old;
      repo.store.resume();
      repo.lock();
    }
  }

  int _writeChunk(File file, int progress, SnapshotChunk part) {
    final content = part.chunk.content;
    progress += content.length;
    final fileSize = part.chunk.fileSize.toInt();
    file.writeAsBytesSync(
      content,
      mode: FileMode.append,
    );
    _log(
      '_writeChunk',
      HttpStatus.ok,
      'Uploading ${part.type} snapshots...${((progress / fileSize) * 100).toStringAsFixed(0)}%',
    );
    return progress;
  }

  Future<UploadSnapshotResponse> _doRestore(
    SnapshotChunk first,
    Repository repo,
    String postfix, [
    StackTrace stackTrace,
  ]) async {
    try {
      await _restore(
        repo,
        postfix,
      );
      return UploadSnapshotResponse()
        ..type = first.type
        ..chunkSize = first.chunk.chunkSize
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = _badRequest(
          '_doRestore',
          'Unable to load snapshot data',
        );
    } catch (error, stackTrace) {
      return UploadSnapshotResponse()
        ..type = first.type
        ..chunkSize = first.chunk.chunkSize
        ..statusCode = HttpStatus.badRequest
        ..reasonPhrase = _log(
          '_doRestore',
          HttpStatus.internalServerError,
          'Unable to restore from backup: $error',
          'Unable to restore from backup: $error',
          stackTrace == null ? Trace.current() : Trace.from(stackTrace),
        );
    }
  }

  Future<bool> _restore(Repository repo, String postfix) {
    if (!_restoreFile(repo.store.snapshots, postfix, 'hive')) {
      return Future.value(false);
    }
    _restoreFile(repo.store.snapshots, postfix, 'lock');
    return _reload(repo);
  }

  Future<bool> _reload(Repository repo) async {
    final snapshots = repo.store.snapshots;
    final path = _toHiveFilePath(snapshots, 'hive');
    final size = File(path).statSync().size;
    final snapshot = await repo.load(
      strict: false,
    );
    if (snapshot != null) {
      await repo.replay(
        strict: false,
      );
    }
    // Crash recovery has been
    // performed if file size has
    // changed (Hive changes it)
    return File(path).statSync().size == size;
  }

  String _toHiveFilePath(Storage snapshots, String extension) => '$dataPath/${snapshots.filename}.$extension';

  String _toBackupFilePath(Storage snapshots, String postfix, String extension) =>
      '${Directory.systemTemp.path}/${snapshots.filename}-$postfix.$extension.bck';

  String _backupFile(Storage snapshots, String postfix, String extension) {
    final hivePath = _toHiveFilePath(snapshots, extension);
    final hiveFile = File(hivePath);
    final backupPath = _toBackupFilePath(snapshots, postfix, extension);
    if (hiveFile.existsSync()) {
      hiveFile.copySync(backupPath);
    }
    return hivePath;
  }

  bool _restoreFile(Storage snapshots, String postfix, String extension) {
    final hivePath = _toHiveFilePath(snapshots, extension);
    final backupPath = _toBackupFilePath(snapshots, postfix, extension);
    final backupFile = File(backupPath);
    final exists = backupFile.existsSync();
    if (exists) {
      backupFile.copySync(hivePath);
      backupFile.deleteSync();
    }
    return exists;
  }

  String _timeout(String method) {
    return _log(
      method,
      HttpStatus.gatewayTimeout,
      'Gateway Timeout Error',
    );
  }

  String _notFound(String method, String message) {
    return _log(
      method,
      HttpStatus.notFound,
      message,
    );
  }

  String _badRequest(String method, String message) {
    return _log(
      method,
      HttpStatus.badRequest,
      message,
    );
  }

  String _log(String method, int statusCode, String reasonPhrase, [Object error, StackTrace stackTrace]) {
    final message = '$method $statusCode $reasonPhrase';
    if (statusCode > 500) {
      logger.severe(
        message,
        error,
        stackTrace,
      );
    } else {
      logger.info(
        '$method $statusCode $reasonPhrase',
        error,
        stackTrace,
      );
    }
    return message;
  }
}
