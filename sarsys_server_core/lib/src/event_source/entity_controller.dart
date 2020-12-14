import 'package:sarsys_server_core/sarsys_server_core.dart';

/// A basic CRUD ResourceController for [AggregateRoot] entity requests
abstract class EntityController<S extends Command, T extends AggregateRoot> extends ResourceController
    with RequestValidatorMixin {
  EntityController(
    this.repository,
    this.entityType,
    this.aggregateField, {
    this.validation,
    this.tag,
    this.entityIdFieldName,
    this.readOnly = const [],
    this.validators = const [],
  });
  final String tag;
  final String entityType;
  final String aggregateField;
  final String entityIdFieldName;
  final Repository<S, T> repository;

  /// Get aggregate [Type]
  Type get aggregateType => typeOf<T>();

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final List<Validator> validators;

  @override
  FutureOr<RequestOrResponse> willProcessRequest(Request req) => repository.isReady
      ? req
      : serviceUnavailable(
          body: 'Repository ${repository.runtimeType} is unavailable: build pending',
        );

  /// Check if exist. Preform catchup if
  /// not found before checking again.
  Future<bool> exists(String uuid) async {
    if (!repository.exists(uuid)) {
      await repository.catchup(
        master: true,
        uuids: [uuid],
      );
    }
    return repository.exists(uuid);
  }

  //////////////////////////////////
  // Entity Operations
  //////////////////////////////////

  /// Add @Operation.get('uuid') to activate
  Future<Response> getAll(@Bind.path('uuid') String uuid) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      final array = aggregate.asEntityArray(
        aggregateField,
        entityIdFieldName: entityIdFieldName ?? aggregate.entityIdFieldName,
      );
      return okEntityPaged<T>(
        uuid,
        entityType,
        aggregate.number,
        aggregateField,
        array.toList(),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation.get('uuid', 'id') to activate
  Future<Response> getById(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      final array = aggregate.asEntityArray(
        aggregateField,
        entityIdFieldName: entityIdFieldName ?? aggregate.entityIdFieldName,
      );
      if (!array.contains(id)) {
        return Response.notFound(body: 'Entity $id not found');
      }
      return okEntityObject<T>(
        uuid,
        entityType,
        aggregate.number,
        aggregateField,
        array[id].data,
      );
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation.post('uuid') to active
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid does not exists');
      }
      final aggregate = repository.get(uuid);
      await repository.execute(onCreate(uuid, entityType, validate(entityType, data)));
      return Response.created(
        '${toLocation(request)}/${data[entityIdFieldName ?? aggregate.entityIdFieldName]}',
      );
    } on EntityExists catch (e) {
      return Response.conflict(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on CommandTimeout catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository $aggregateType was unable to process request ${e.request.tag}',
      );
    } on SocketException catch (e) {
      return serviceUnavailable(
        body: 'Eventstore unavailable: $e',
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onCreate(String uuid, String type, Map<String, dynamic> data) => throw UnimplementedError('Create not implemented');

  /// Add @Operation('PATCH', 'uuid', 'id') to active
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      data[entityIdFieldName ?? aggregate.entityIdFieldName] = id;
      final events = await repository.execute(
        onUpdate(uuid, entityType, validate(entityType, data, isPatch: true)),
      );
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on EntityExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        base: e.base,
        mine: e.mine,
        yours: e.yours,
      );
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on CommandTimeout catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository $aggregateType was unable to process request ${e.request.tag}',
      );
    } on SocketException catch (e) {
      return serviceUnavailable(
        body: 'Eventstore unavailable: $e',
      );
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onUpdate(String uuid, String type, Map<String, dynamic> data) => throw UnimplementedError('Update not implemented');

  /// Add @Operation('DELETE', 'uuid', 'id') to active
  Future<Response> delete(
    @Bind.path('uuid') String uuid,
    @Bind.path('id') String id, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      final entity = data ?? {};
      entity[entityIdFieldName ?? aggregate.entityIdFieldName] = id;
      final events = await repository.execute(onDelete(uuid, entityType, entity));
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on EntityNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on CommandTimeout catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository $aggregateType was unable to process request ${e.request.tag}',
      );
    } on SocketException catch (e) {
      return serviceUnavailable(
        body: 'Eventstore unavailable: $e',
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onDelete(String uuid, String type, Map<String, dynamic> data) => throw UnimplementedError('Remove not implemented');

  /// Report error to Sentry and
  /// return 500 with message as body
  Response toServerError(Object error, StackTrace stackTrace) => serverError(
        request,
        error,
        stackTrace,
        logger: logger,
      );

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  List<String> documentOperationTags(APIDocumentContext context, Operation operation) =>
      tag == null ? super.documentOperationTags(context, operation) : [tag];

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    String summary;
    switch (operation.method) {
      case 'GET':
        summary = operation.pathVariables.length < 2 ? 'Get all ${_toName()}s' : 'Get ${_toName()}';
        break;
      case 'POST':
        summary = 'Create ${_toName()}';
        break;
      case 'PATCH':
        summary = 'Update ${_toName()}';
        break;
      case 'DELETE':
        summary = 'Delete ${_toName()}';
        break;
    }
    return summary;
  }

  String _toName() => entityType.toDelimiterCase(' ');

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    var desc = '${documentOperationSummary(context, operation)}. ';
    switch (operation.method) {
      case 'POST':
        desc += 'The field [id] MUST BE unique for each $entityType. Use a '
            '[universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).';
        break;
      case 'PATCH':
        desc += 'Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.';
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          context.schema[entityType],
          description: 'New $entityType Request',
          required: true,
        );
        break;
      case 'PATCH':
        return APIRequestBody.schema(
          context.schema[entityType],
          description: 'Update $entityType Request. Only fields in request are updated.',
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = {
      '401': context.responses.getObject('401'),
      '403': context.responses.getObject('403'),
      '503': context.responses.getObject('503'),
    };
    switch (operation.method) {
      case 'GET':
        if (operation.pathVariables.length == 1) {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response.',
              documentEntityPageResponse(context, type: entityType),
            )
          });
        } else {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response',
              documentEntityResponse(context, type: entityType),
            ),
          });
        }
        break;
      case 'POST':
        responses.addAll({
          '201': context.responses.getObject('201'),
          '400': context.responses.getObject('400'),
          '409': context.responses.getObject('409'),
        });
        break;
      case 'PATCH':
        responses.addAll({
          '204': context.responses.getObject('204'),
          '400': context.responses.getObject('400'),
          '409': context.responses.getObject('409'),
        });
        break;
    }
    return responses;
  }

  @override
  Map<String, APIOperation> documentOperations(APIDocumentContext context, String route, APIPath path) {
    final operations = super.documentOperations(context, route, path);
    return operations.map((key, method) => MapEntry(
          key,
          APIOperation(
            '${method.id}${capitalize(entityType)}',
            method.responses,
            summary: method.summary,
            description: method.description,
            parameters: method.parameters,
            requestBody: method.requestBody,
            tags: method.tags,
          ),
        ));
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    _documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$name';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$name schema';
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> _documentSchemaObjects(APIDocumentContext context) => {
        entityType: documentEntityObject(context)..description = '$entityType Response',
      }..addAll(documentEntities(context));

  APISchemaObject documentEntityObject(APIDocumentContext context) => context.schema[entityType];

  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
}
