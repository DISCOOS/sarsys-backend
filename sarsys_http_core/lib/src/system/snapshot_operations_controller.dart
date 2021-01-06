import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'controllers.dart';

/// A [ResourceController] for [SnapshotModel] operations requests on [Storage]
class SnapshotOperationsController extends SystemOperationsBaseController {
  SnapshotOperationsController(
    RepositoryManager manager, {
    @required String tag,
    @required SarSysConfig config,
    @required Map<String, dynamic> context,
  }) : super(
          manager,
          tag: tag,
          options: [
            'data',
            'items',
          ],
          actions: [
            'save',
            'configure',
          ],
          config: config,
          context: context,
          type: 'Snapshot',
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.get('type')
  Future<Response> getSnapshotsMeta(
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
      final snapshots = repository.store.snapshots;
      if (snapshots == null) {
        return Response.badRequest(
          body: 'Snapshots not activated',
        );
      }

      return Response.ok(
        await snapshots.toMeta(
          repository.snapshot?.uuid,
          type: repository.aggregateType,
          data: shouldExpand(expand, 'data'),
          items: shouldExpand(expand, 'items'),
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
      final repository = manager.getFromTypeName(type);
      if (repository == null) {
        return Response.notFound(
          body: 'Repository for type $type not found',
        );
      }
      final command = assertCommand(body);
      switch (command) {
        case 'save':
          return _doSave(
            repository,
            body,
            expand,
          );
        default:
          return Response.badRequest(
            body: "Command '$command' not found",
          );
      }
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Future<Response> _doSave(
    Repository repository,
    Map<String, dynamic> body,
    String expand,
  ) async {
    final snapshots = repository.store.snapshots;
    if (snapshots == null) {
      return Response.badRequest(
        body: 'Snapshots not activated',
      );
    }

    final automatic = body.elementAt<bool>(
      'params/automatic',
      defaultValue: snapshots.automatic,
    );
    final threshold = body.elementAt<int>(
      'params/threshold',
      defaultValue: snapshots.threshold,
    );
    final keep = body.elementAt<int>(
      'params/keep',
      defaultValue: snapshots.keep,
    );
    snapshots
      ..keep = keep
      ..automatic = automatic
      ..threshold = threshold;
    logger.info(
      'Snapshots configured: automatic: $automatic, keep: $keep, threshold, $threshold',
    );
    final prev = repository.snapshot?.uuid;
    final next = repository.save().uuid;
    await repository.store.snapshots.onIdle;
    return prev == next
        ? Response.noContent()
        : Response.ok(
            await snapshots.toMeta(
              next,
              current: repository.number,
              type: repository.aggregateType,
              data: shouldExpand(expand, 'data'),
              items: shouldExpand(expand, 'items'),
            ),
          );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {
        'force': APISchemaObject.boolean()..description = '[save] ]Control flag forcing save',
        'keep': APISchemaObject.integer()..description = '[configure] Number of snapshots to keep (oldest are deleted)',
        'threshold': APISchemaObject.integer()..description = '[configure] Snapshot threshold',
        'automatic': APISchemaObject.boolean()
          ..description = '[configure] Control flag for automatic snapshots when threshold is reached',
      };

  @override
  APISchemaObject documentMeta(APIDocumentContext context) {
    return APISchemaObject.object({
      'last': APISchemaObject.boolean()
        ..description = 'True if snapshot is the last saved'
        ..isReadOnly = true,
      'uuid': documentUUID()
        ..description = 'Globally unique Snapshot id'
        ..isReadOnly = true,
      'number': APISchemaObject.integer()
        ..description = 'Snapshot event number '
            '(or position in projection if using instance-streams)'
        ..isReadOnly = true,
      'timestamp': APISchemaObject.string()
        ..description = 'When snapshot was saved'
        ..format = 'date-time',
      'unsaved': APISchemaObject.integer()
        ..description = 'Number of unsaved events'
        ..isReadOnly = true,
      'partial': APISchemaObject.object({
        'missing': APISchemaObject.integer()
          ..description = 'Number of missing events in snapshot'
          ..isReadOnly = true,
      })
        ..description = 'Snapshot contains partial state if defined'
        ..isReadOnly = true,
      'config': APISchemaObject.object({
        'keep': APISchemaObject.integer()
          ..description = 'Number of snapshots to keep until deleting oldest'
          ..isReadOnly = true,
        'threshold': APISchemaObject.integer()
          ..description = 'Number of unsaved events before saving to next snapshot'
          ..isReadOnly = true,
        'automatic': APISchemaObject.integer()
          ..description = 'Control flag for automatic snapshots when threshold is reached'
          ..isReadOnly = true,
      })
        ..description = 'Snapshots configuration'
        ..isReadOnly = true,
      'metrics': APISchemaObject.object({
        'snapshots': APISchemaObject.integer()
          ..description = 'Number of snapshots'
          ..isReadOnly = true,
        'save': documentMetric('Save'),
      })
        ..description = 'Snapshot metrics'
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
}
