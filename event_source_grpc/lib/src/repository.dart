import 'dart:async';
import 'dart:io';

import 'package:event_source/event_source.dart';
import 'package:grpc/src/server/call.dart';
import 'package:logging/logging.dart';

import 'generated/repository.pbgrpc.dart';
import 'utils.dart';

class RepositoryGrpcService extends RepositoryServiceBase {
  RepositoryGrpcService(this.manager);
  final RepositoryManager manager;
  final logger = Logger('$RepositoryGrpcService');

  @override
  Future<GetRepoMetaResponse> getMeta(ServiceCall call, GetRepoMetaRequest request) async {
    final response = GetRepoMetaResponse()
      ..type = request.type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';
    final type = request.type;
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'getMeta',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Repository for aggregate $type not found';
    }
    final meta = await _toRepoMeta(
      repo,
      request.expand,
    );
    response.meta = toRepoMeta(
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

  Future<Map<String, dynamic>> _toRepoMeta(
    Repository repo,
    List<RepoExpandFields> expand,
  ) async {
    return await repo.toMeta(
      data: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_DATA,
      ),
      items: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_ITEMS,
      ),
      queue: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_QUEUE,
      ),
      metrics: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_METRICS,
      ),
      snapshot: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_SNAPSHOT,
      ),
      connection: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_CONN,
      ),
      subscriptions: withRepoField(
        expand,
        RepoExpandFields.REPO_EXPAND_FIELDS_SUBS,
      ),
    );
  }

  @override
  Future<RebuildRepoResponse> rebuild(
    ServiceCall call,
    RebuildRepoRequest request,
  ) async {
    final response = RebuildRepoResponse()
      ..type = request.type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';
    final type = request.type;
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'rebuild',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Repository for aggregate $type not found';
    }

    // Execute
    await repo.build(
      master: request.master,
    );

    final meta = await _toRepoMeta(
      repo,
      request.expand,
    );
    response.meta = toRepoMeta(
      meta,
      repo.store,
    );
    _log(
      'rebuild',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Future<RepairRepoResponse> repair(
    ServiceCall call,
    RepairRepoRequest request,
  ) async {
    final response = RepairRepoResponse()
      ..type = request.type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';
    final type = request.type;
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'repair',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Repository for aggregate $type not found';
    }

    // Execute
    final before = await repo.repair(
      master: request.master,
    );

    // Check result
    final after = await repo.analyze(
      master: request.master,
    );

    final meta = await _toRepoMeta(
      repo,
      request.expand,
    );
    response
      ..meta = toRepoMeta(
        meta,
        repo.store,
      )
      ..after = _toAnalysisMeta(after)
      ..before = _toAnalysisMeta(before);
    _log(
      'repair',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  AnalysisMeta _toAnalysisMeta(Map<String, AnalyzeResult> analysis) {
    final wrong = analysis.values.where((a) => a.isWrongStream).length;
    final multiple = analysis.values.where((a) => a.isMultipleAggregates).length;
    final meta = {
      'wrong': wrong,
      'multiple': multiple,
      'count': analysis.length,
      'summary': analysis.values.where((a) => a.isValid).map((a) => a.toSummaryText()).toList(),
    };
    return toAnalysisMeta(meta);
  }

  @override
  Future<CatchupRepoEventsResponse> catchupEvents(
    ServiceCall call,
    CatchupRepoEventsRequest request,
  ) async {
    final response = CatchupRepoEventsResponse()
      ..type = request.type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';
    final type = request.type;
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'catchupEvents',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Repository for aggregate $type not found';
    }
    final unknown = <String>[];
    final uuids = request.uuids;
    for (var uuid in uuids) {
      final aggregate = await _tryGet(type, uuid);
      if (aggregate == null) {
        unknown.add(uuid);
      }
    }

    if (unknown.isNotEmpty) {
      _notFound(
        'catchupEvents',
        'Aggregate $type $uuids not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Aggregate $type $uuids not found';
    }

    // Execute
    await repo.catchup(
      uuids: uuids,
      strict: false,
    );

    final meta = await _toRepoMeta(
      repo,
      request.expand,
    );
    response.meta = toRepoMeta(
      meta,
      repo.store,
    );
    _log(
      'catchupEvents',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  @override
  Future<ReplayRepoEventsResponse> replayEvents(
    ServiceCall call,
    ReplayRepoEventsRequest request,
  ) async {
    final response = ReplayRepoEventsResponse()
      ..type = request.type
      ..statusCode = HttpStatus.ok
      ..reasonPhrase = 'OK';
    final type = request.type;
    final repo = manager.getFromTypeName(type);
    if (repo == null) {
      _notFound(
        'replayData',
        'Repository for aggregate $type not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Repository for aggregate $type not found';
    }

    final unknown = <String>[];
    final uuids = request.uuids;
    for (var uuid in uuids) {
      final aggregate = await _tryGet(type, uuid);
      if (aggregate == null) {
        unknown.add(uuid);
      }
    }

    if (unknown.isNotEmpty) {
      _notFound(
        'catchupEvents',
        'Aggregate $type $uuids not found',
      );
      return response
        ..statusCode = HttpStatus.notFound
        ..reasonPhrase = 'Aggregate $type $uuids not found';
    }

    // Execute
    await repo.replay(
      uuids: uuids,
      strict: false,
    );

    // Return result
    final meta = await _toRepoMeta(
      repo,
      request.expand,
    );
    response.meta = toRepoMeta(
      meta,
      repo.store,
    );
    _log(
      'catchupEvents',
      response.statusCode,
      response.reasonPhrase,
    );
    return response;
  }

  FutureOr<AggregateRoot> _tryGet(String type, String uuid) async {
    final repo = manager.getFromTypeName(type);
    if (!repo.exists(uuid)) {
      await repo.catchup(
        master: true,
        uuids: [uuid],
      );
    }
    // Only get aggregate if is exists in storage!
    return repo.store.contains(uuid) ? repo.get(uuid) : null;
  }

  String _notFound(String method, String message) {
    return _log(
      method,
      HttpStatus.notFound,
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
