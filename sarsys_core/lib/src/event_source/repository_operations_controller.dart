import 'package:sarsys_core/sarsys_core.dart';

import '../http/controllers.dart';

/// A [ResourceController] for [Repository] operations requests
@Deprecated("Use RepositoryGrpcServiceController in package 'event_source_grpc' instead")
class RepositoryOperationsController extends SystemOperationsBaseController {
  RepositoryOperationsController(
    RepositoryManager manager, {
    @required String tag,
    @required SarSysModuleConfig config,
    @required Map<String, dynamic> context,
  }) : super(
          manager,
          tag: tag,
          options: [
            'data',
            'queue',
            'items',
            'metrics',
            'snapshot',
            'connection',
            'subscriptions',
          ],
          actions: [
            'replay',
            'repair',
            'catchup',
            'rebuild',
          ],
          config: config,
          context: context,
          type: 'Repository',
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.get('type')
  Future<Response> getRepoMeta(
    @Bind.path('type') String type, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      return Response.ok(
        await repository.toMeta(
          data: shouldExpand(expand, 'data'),
          queue: shouldExpand(expand, 'queue'),
          items: shouldExpand(expand, 'items'),
          metrics: shouldExpand(expand, 'metrics'),
          snapshot: shouldExpand(expand, 'snapshot'),
          connection: shouldExpand(expand, 'connection'),
          subscriptions: shouldExpand(expand, 'subscriptions'),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.post('type')
  Future<Response> repoCommand(
    @Bind.path('type') String type,
    @Bind.body() Map<String, dynamic> body, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!shouldAccept()) {
        return requestedRangeNotSatisfiable();
      }
      final repo = manager.getFromTypeName(type);
      if (repo == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      var result = <String, dynamic>{};
      final command = assertCommand(body);
      switch (command) {
        case 'rebuild':
          await repo.build(
            context: request.toContext(logger),
          );
          break;
        case 'repair':
          result = await _doRepair(body, repo);
          break;
        case 'replay':
          await _doReplay(body, repo);
          break;
        case 'catchup':
          await _doCatchup(body, repo);
          break;
        default:
          return Response.badRequest(
            body: "Command '$command' not found",
          );
      }
      final meta = await repo.toMeta(
        data: shouldExpand(expand, 'data'),
        queue: shouldExpand(expand, 'queue'),
        items: shouldExpand(expand, 'items'),
        metrics: shouldExpand(expand, 'metrics'),
        snapshot: shouldExpand(expand, 'snapshot'),
        connection: shouldExpand(expand, 'connection'),
        subscriptions: shouldExpand(expand, 'subscriptions'),
      );
      return Response.ok(
        meta..addAll(result),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future _doCatchup(Map<String, dynamic> body, Repository repo) async {
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: <String>[],
    );
    await repo.catchup(
      uuids: uuids,
      strict: false,
    );
  }

  Future _doReplay(Map<String, dynamic> body, Repository repo) async {
    final uuids = body.listAt<String>(
      'params/uuids',
      defaultList: <String>[],
    );
    await repo.replay(
      uuids: uuids,
      strict: false,
      context: request.toContext(logger),
    );
  }

  Future<Map<String, dynamic>> _doRepair(Map<String, dynamic> body, Repository repo) async {
    final master = body.elementAt<bool>(
      'params/master',
      defaultValue: false,
    );
    final context = request.toContext(logger);
    final before = await repo.repair(
      master: master,
      context: context,
    );
    return {
      'before': _toAnalysisMeta(before),
      'after': before.values.any((a) => a.isInvalid)
          ? await repo.analyze(
              master: master,
              context: context,
            )
          : _toAnalysisMeta(before),
    };
  }

  Map<String, dynamic> _toAnalysisMeta(Map<String, AnalyzeResult> analysis) {
    final wrong = analysis.values.where((a) => a.isWrongStream).length;
    final multiple = analysis.values.where((a) => a.isMultipleAggregates).length;
    return {
      'wrong': wrong,
      'multiple': multiple,
      'count': analysis.length,
      'summary': analysis.values.where((a) => a.isValid).map((a) => a.toSummaryText()).toList(),
    };
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {
        'uuids': APISchemaObject.array(ofType: APIType.string)
          ..description = 'List of aggregate uuids which command applies to',
      };

  @override
  APISchemaObject documentMeta(APIDocumentContext context) {
    return documentRepositoryMeta(context);
  }
}
