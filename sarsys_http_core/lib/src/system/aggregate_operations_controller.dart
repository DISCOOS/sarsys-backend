import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'controllers.dart';

/// A [ResourceController] for [AggregateRoot] operations requests
class AggregateOperationsController extends SystemOperationsBaseController {
  AggregateOperationsController(
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
            'replay',
            'catchup',
            'replace',
          ],
          config: config,
          context: context,
          type: 'Aggregate',
        );

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  @Scope(['roles:admin'])
  @Operation.get('type', 'uuid')
  Future<Response> getAggregateMeta(
    @Bind.path('type') String type,
    @Bind.path('uuid') String uuid, {
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
      if (!repository.contains(uuid)) {
        Response.notFound(
          body: 'Aggregate ${repository.aggregateType} $uuid not found',
        );
      }
      final aggregate = repository.get(uuid);
      final trx = repository.inTransaction(uuid) ? repository.get(uuid) : null;
      final data = shouldExpand(expand, 'data');
      final items = shouldExpand(expand, 'items');
      return Response.ok(
        aggregate.toMeta(
          data: data,
          items: items,
        )..addAll({'transaction': trx?.toMeta(data: data, items: items) ?? {}}),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @Scope(['roles:admin'])
  @Operation.post('type', 'uuid')
  Future<Response> aggregateCommand(
    @Bind.path('uuid') String uuid,
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
      if (!repository.contains(uuid)) {
        Response.notFound(
          body: 'Aggregate ${repository.aggregateType} $uuid not found',
        );
      }
      final command = assertCommand(body);
      final expandData = shouldExpand(expand, 'data');
      final expandItems = shouldExpand(expand, 'items');

      switch (command) {
        case 'replay':
          return _doReplay(
            repository,
            uuid,
            expandData,
            expandItems,
          );
        case 'catchup':
          return _doCatchup(
            repository,
            uuid,
            expandData,
            expandItems,
          );
        case 'replace':
          return _doReplace(
            body,
            repository,
            uuid,
            expandData,
            expandItems,
          );
      }
      return Response.badRequest(
        body: "Command '$command' not found",
      );
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository was unable to process request ${e.request.tag}',
      );
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  Response _doReplace(
      Map<String, dynamic> body,
      Repository<Command<DomainEvent>, AggregateRoot<DomainEvent, DomainEvent>> repository,
      String uuid,
      bool expandData,
      bool expandItems) {
    final data = body.mapAt<String, dynamic>(
      'params/data',
    );
    final patches = body.listAt<Map<String, dynamic>>(
      'params/patches',
    );
    final old = repository.replace(
      uuid,
      data: data,
      patches: patches,
    );
    return Response.ok(
      old.toMeta(
        data: expandData,
        items: expandItems,
      ),
    );
  }

  Future<Response> _doCatchup(Repository<Command<DomainEvent>, AggregateRoot<DomainEvent, DomainEvent>> repository,
      String uuid, bool expandData, bool expandItems) async {
    await repository.catchup(
      uuids: [uuid],
    );
    return Response.ok(
      repository.get(uuid).toMeta(
            data: expandData,
            items: expandItems,
          ),
    );
  }

  Future<Response> _doReplay(Repository<Command<DomainEvent>, AggregateRoot<DomainEvent, DomainEvent>> repository,
      String uuid, bool expandData, bool expandItems) async {
    await repository.replay(
      uuids: [uuid],
    );
    return Response.ok(
      repository.get(uuid).toMeta(
            data: expandData,
            items: expandItems,
          ),
    );
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  Map<String, APISchemaObject> documentCommandParams(APIDocumentContext context) => {
        'data': APISchemaObject.freeForm()..description = 'Map of JSON-compliant values',
        'patches': APISchemaObject.array(
          ofSchema: APISchemaObject.freeForm()..description = 'Map of JSON-Patch compliant values',
        )
      };

  @override
  APISchemaObject documentMeta(APIDocumentContext context) => APISchemaObject.object({
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
        'modifications': APISchemaObject.integer()
          ..description = 'Total number of modifications'
          ..isReadOnly = true,
        'applied': APISchemaObject.object({
          'count': APISchemaObject.integer()
            ..description = 'Total number of applied events'
            ..isReadOnly = true,
          'items': APISchemaObject.array(
            ofSchema: documentEvent(context),
          )..description = 'Array of skipped events',
        }),
        'skipped': APISchemaObject.object({
          'count': APISchemaObject.integer()
            ..description = 'Total number of skipped events'
            ..isReadOnly = true,
          'items': APISchemaObject.array(
            ofSchema: documentEvent(context),
          )..description = 'Array of skipped events',
        }),
        'pending': APISchemaObject.object({
          'count': APISchemaObject.integer()
            ..description = 'Total number of local events pending push'
            ..isReadOnly = true,
          'items': APISchemaObject.array(
            ofSchema: documentEvent(context),
          )..description = 'Array of local events pending push',
        }),
        'data': APISchemaObject.freeForm()
          ..description = 'Map of JSON-Patch compliant values'
          ..isReadOnly = true,
      });
}
