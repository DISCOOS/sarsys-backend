import 'package:sarsys_core/sarsys_core.dart';
import 'package:collection_x/collection_x.dart';

/// A basic CRUD ResourceController for [AggregateRoot] value requests
abstract class ValueController<S extends Command, T extends AggregateRoot> extends ResourceController
    with RequestValidatorMixin {
  ValueController(
    this.repository,
    this.valueType,
    this.aggregateField, {
    this.tag,
    this.validation,
    this.readOnly = const [],
    this.validators = const [],
  });
  final String tag;
  final String valueType;
  final String aggregateField;
  final Repository<S, T> repository;

  /// Get aggregate [Type]
  Type get aggregateType => typeOf<T>();

  @override
  Logger get logger => Logger('$runtimeType');

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
  Future<Response> get(
    @Bind.path('uuid') String uuid,
  ) async {
    return await getValue(uuid, aggregateField);
  }

  /// Add @Operation.get('uuid') to activate
  Future<Response> getPaged(
    @Bind.path('uuid') String uuid, {
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
  }) async {
    return await getValuePaged(
      uuid,
      aggregateField,
      offset: offset,
      limit: limit,
    );
  }

  /// Get value in [AggregateRoot] with given [uuid]
  Future<Response> getValue<V>(
    String uuid,
    String aggregateField, {
    dynamic Function(V value) map,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      final value = aggregate.data.elementAt(aggregateField);
      if (value == null) {
        return Response.notFound(
          body: 'Value $aggregateField not found',
        );
      }
      return okValueObject<T>(
        uuid,
        valueType,
        aggregate.number,
        aggregateField,
        data: map == null ? value : map(value as V),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Get value in [AggregateRoot] with given [uuid]
  Future<Response> getValuePaged<V>(
    String uuid,
    String aggregateField, {
    int offset,
    int limit,
    Iterable Function(V value) map,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = repository.get(uuid);
      final list = aggregate.data.elementAt<V>(aggregateField);
      if (list == null) {
        return Response.notFound(
          body: 'Value $aggregateField not found',
        );
      }
      final entities = map == null ? list as Iterable : map(list).toList();
      return okValuePaged<T>(
        uuid,
        valueType,
        aggregate.number,
        aggregateField,
        entities.toPage(
          offset: offset,
          limit: limit,
        ),
        limit: limit,
        offset: offset,
        count: entities.length,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation('PATCH', 'uuid') to active
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    return await setValue(
      uuid,
      aggregateField,
      data,
    );
  }

  /// Set value in [AggregateRoot] with given [uuid]
  Future<Response> setValue(
    String uuid,
    String aggregateField,
    dynamic data,
  ) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final events = await repository.execute(
        onUpdate(uuid, valueType, {
          'uuid': uuid,
          aggregateField: validate(
            valueType,
            data,
            isPatch: true,
          ),
        }),
        context: request.toContext(logger),
      );
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        base: e.base,
        mine: e.mine,
        yours: e.yours,
      );
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on RepositoryMaxPressureExceeded catch (e) {
      return tooManyRequests(body: e.message);
    } on TimeoutException catch (e) {
      return gatewayTimeout(
        body: e.message,
      );
    } on StreamRequestTimeout catch (e) {
      return gatewayTimeout(
        body: 'Repository $aggregateType was unable to process request ${e.request.tag}',
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: 'Eventstore unavailable: $e');
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onUpdate(String uuid, String type, Map<String, dynamic> data) => throw UnimplementedError('Update not implemented');

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
        summary = 'Get $aggregateField';
        break;
      case 'PATCH':
        summary = 'Update $aggregateField';
        break;
    }
    return summary;
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    var desc = '${documentOperationSummary(context, operation)}. ';
    switch (operation.method) {
      case 'PATCH':
        desc += 'Only fields in request are updated. Existing values WILL BE overwritten, others remain unchanged.';
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'PATCH':
        return APIRequestBody.schema(
          context.schema[valueType],
          description: 'Update $aggregateType. Only field $aggregateField is updated.',
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
        responses.addAll({
          '200': APIResponse.schema(
            'Successful response',
            documentValueResponse(context, type: valueType),
          ),
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
            '${method.id}${capitalize(valueType)}',
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
        valueType: documentValueObject(context),
      };

  APISchemaObject documentValueObject(APIDocumentContext context) => context.schema[valueType];
}
