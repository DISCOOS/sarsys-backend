import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'controllers.dart';

/// A [ResourceController] for [Repository] operations requests
class RepositoryOperationsController extends SystemOperationsBaseController {
  RepositoryOperationsController(
    RepositoryManager manager, {
    @required String tag,
    @required SarSysConfig config,
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
            'rebuild',
            'replay',
            'catchup',
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
    return APISchemaObject.object({
      'type': APISchemaObject.string()
        ..description = 'Aggregate Type'
        ..isReadOnly = true,
      'count': APISchemaObject.integer()
        ..description = 'Number of aggregates'
        ..isReadOnly = true,
      'queue': _documentQueue(),
      'snapshot': _documentSnapshot(context),
      'connection': _documentConnection(context),
      'subscriptions': _documentSubscriptions(context),
    });
  }

  APISchemaObject _documentQueue() {
    return APISchemaObject.object({
      'pressure': APISchemaObject.object({
        'push': APISchemaObject.integer()
          ..description = 'Number of pending pushes'
          ..isReadOnly = true,
        'command': APISchemaObject.integer()
          ..description = 'Number of pending commands'
          ..isReadOnly = true,
        'total': APISchemaObject.integer()
          ..description = 'Total pressure'
          ..isReadOnly = true,
        'maximum': APISchemaObject.integer()
          ..description = 'Maximum allowed pressure'
          ..isReadOnly = true,
        'exceeded': APISchemaObject.boolean()
          ..description = 'True if maximum pressure is exceeded'
          ..isReadOnly = true,
      })
        ..description = 'Queue pressure data'
        ..isReadOnly = true,
      'status': APISchemaObject.object({
        'idle': APISchemaObject.boolean()
          ..description = 'True if queue is idle'
          ..isReadOnly = true,
        'ready': APISchemaObject.boolean()
          ..description = 'True if queue is ready to process requests'
          ..isReadOnly = true,
        'disposed': APISchemaObject.boolean()
          ..description = 'True if queue is disposed'
          ..isReadOnly = true,
      })
        ..description = 'Queue status'
        ..isReadOnly = true,
    })
      ..description = 'Queue metadata'
      ..isReadOnly = true;
  }

  APISchemaObject _documentSnapshot(APIDocumentContext context) {
    return APISchemaObject.object({
      'uuid': documentUUID()
        ..description = 'Globally unique Snapshot id'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Snapshot event number '
            '(or position in projection if using instance-streams)'
        ..isReadOnly = true,
      'keep': APISchemaObject.integer()
        ..description = 'Number of snapshots to keep until deleting oldest'
        ..isReadOnly = true,
      'unsaved': APISchemaObject.integer()
        ..description = 'Number of unsaved events'
        ..isReadOnly = true,
      'threshold': APISchemaObject.integer()
        ..description = 'Number of unsaved events before saving to next snapshot'
        ..isReadOnly = true,
      'automatic': APISchemaObject.integer()
        ..description = 'Control flag for automatic snapshots when threshold is reached'
        ..isReadOnly = true,
      'partial': APISchemaObject.object({
        'missing': APISchemaObject.integer()
          ..description = 'Number of missing events in snapshot'
          ..isReadOnly = true,
      })
        ..description = 'Snapshot contains partial state if defined'
        ..isReadOnly = true,
      'aggregates': APISchemaObject.object({
        'count': APISchemaObject.integer()
          ..description = 'Total number aggregates in snapshot'
          ..isReadOnly = true,
        'items': APISchemaObject.array(
          ofSchema: _documentAggregate(context),
        )..description = 'Array of skipped events',
      }),
    })
      ..description = 'Queue pressure data'
      ..isReadOnly = true;
  }

  APISchemaObject _documentAggregate(APIDocumentContext context) {
    return APISchemaObject.object({
      'uuid': documentUUID()
        ..description = 'Globally unique aggregate id'
        ..isReadOnly = true,
      'type': APISchemaObject.string()
        ..description = 'Aggregate Type'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Current event number'
        ..isReadOnly = true,
      'created': documentEvent(context)
        ..description = 'Created by given event'
        ..isReadOnly = true,
      'changed': documentEvent(context)
        ..description = 'Last changed by given event'
        ..isReadOnly = true,
      'data': APISchemaObject.freeForm()
        ..description = 'Map of JSON-Patch compliant values'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentConnection(APIDocumentContext context) {
    return APISchemaObject.object({
      'metrics': APISchemaObject.object({
        'read': documentMetric('Read'),
        'write': documentMetric('Write'),
      })
        ..description = 'Connection metrics'
        ..isReadOnly = true,
    });
  }

  APISchemaObject _documentSubscriptions(APIDocumentContext context) {
    return APISchemaObject.object({
      'catchup': APISchemaObject.object({
        'isAutomatic': APISchemaObject.boolean()
          ..description = 'True if automatic catchup is activated'
          ..isReadOnly = true,
        'exists': APISchemaObject.boolean()
          ..description = 'True if subscription exists'
          ..isReadOnly = true,
        'last': documentEvent(context)
          ..description = 'Last event processed'
          ..isReadOnly = true,
        'status': APISchemaObject.object({
          'isPaused': APISchemaObject.boolean()
            ..description = 'True if subscription is paused'
            ..isReadOnly = true,
          'isCancelled': APISchemaObject.boolean()
            ..description = 'True if subscription is cancelled'
            ..isReadOnly = true,
          'isCompeting': APISchemaObject.boolean()
            ..description = 'True if subscription is competing (pulling when false)'
            ..isReadOnly = true,
        })
          ..description = 'Catchup subscription status'
          ..isReadOnly = true,
        'metrics': APISchemaObject.object({
          'processed': APISchemaObject.integer()
            ..description = 'Number of events processed'
            ..isReadOnly = true,
          'reconnects': APISchemaObject.integer()
            ..description = 'Number of reconnections'
            ..isReadOnly = true,
        })
          ..description = 'Catchup subscription statistics'
          ..isReadOnly = true
      })
        ..description = 'Catchup subscription'
        ..isReadOnly = true,
      'push': APISchemaObject.object({
        'exists': APISchemaObject.boolean()
          ..description = 'True if subscription exists'
          ..isReadOnly = true,
        'isPaused': APISchemaObject.boolean()
          ..description = 'True if subscription is paused'
          ..isReadOnly = true,
      })
        ..description = 'Request queue subscription status'
        ..isReadOnly = true,
    });
  }
}
