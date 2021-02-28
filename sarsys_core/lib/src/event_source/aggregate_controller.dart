import 'package:sarsys_core/sarsys_core.dart';

/// A basic CRUD ResourceController for [AggregateRoot] requests
abstract class AggregateController<S extends Command, T extends AggregateRoot> extends ResourceController
    with RequestValidatorMixin {
  AggregateController(
    this.repository, {
    this.tag,
    this.validation,
    this.readOnly = const [],
    this.validators = const [],
  });

  final String tag;
  final Repository<S, T> repository;

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final List<Validator> validators;

  /// Get aggregate [Type]
  Type get aggregateType => typeOf<T>();

  @override
  Logger get logger => Logger('$runtimeType');

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
  // Aggregate Operations
  //////////////////////////////////

  /// Add @Operation.get() to activate
  Future<Response> getAll({
    @Bind.query('offset') int offset = 0,
    @Bind.query('limit') int limit = 20,
    @Bind.query('deleted') bool deleted = false,
  }) async {
    try {
      final events = repository
          .getAll(
            offset: offset,
            limit: limit,
            deleted: deleted,
          )
          .toList();
      return okAggregatePaged(
        repository.count(deleted: deleted),
        offset,
        limit,
        events,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation.get('uuid') to activate
  Future<Response> getByUuid(@Bind.path('uuid') String uuid) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      return okAggregate(repository.get(uuid));
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  /// Add @Operation.post() to activate
  Future<Response> create(
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      await repository.execute(
        onCreate(validate('$aggregateType', data)),
        context: request.toContext(logger),
      );
      return Response.created(
        '${toLocation(request)}/${data[repository.uuidFieldName]}',
      );
    } on UUIDIsNull {
      return Response.badRequest(
        body: 'Field [${repository.uuidFieldName}] in $aggregateType is required',
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
      return gatewayTimeout(
        body: 'Eventstore unavailable: $e',
      );
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
    } on ConflictNotReconcilable catch (e) {
      return conflict(
        ConflictType.merge,
        e.message,
        mine: e.mine,
        base: e.base,
        yours: e.yours,
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onCreate(Map<String, dynamic> data) => throw UnimplementedError('Create not implemented');

  /// Add @Operation('PATCH', 'uuid') to activate
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    Transaction trx;
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      data[repository.uuidFieldName] = uuid;
      final events = <Event>[];
      trx = repository.tryTransaction(
        uuid,
        context: request.toContext(logger),
      );
      final commands = onUpdate(
        validate('$aggregateType', data, isPatch: true),
      );
      for (var command in commands) {
        events.addAll(
          await repository.execute(
            command,
            context: request.toContext(logger),
          ),
        );
      }
      if (trx != null) {
        events.addAll(
          await trx.push(),
        );
      }
      return events.isEmpty ? Response.noContent() : okAggregate(repository.get(uuid));
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(
        body: 'Field [${repository.uuidFieldName}] in $aggregateType is required',
      );
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
      return serviceUnavailable(
        body: 'Eventstore unavailable: $e',
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    } finally {
      if (trx?.isOpen == true) {
        trx?.rollback(this);
      }
    }
  }

  String toAggregateUuid(Map<String, dynamic> data) {
    return data.elementAt<String>(repository.uuidFieldName);
  }

  Iterable<S> onUpdate(Map<String, dynamic> data) => throw UnimplementedError('Update not implemented');

  /// Add @Operation('DELETE', 'uuid') to activate
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: '$aggregateType $uuid not found');
      }
      final aggregate = data ?? {};
      aggregate[repository.uuidFieldName] = uuid;
      final events = await repository.execute(
        onDelete(aggregate),
        context: request.toContext(logger),
      );
      return events.isEmpty ? Response.noContent() : Response.noContent();
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
    } on UUIDIsNull {
      return Response.badRequest(
        body: 'Field [${repository.uuidFieldName}] in $aggregateType is required',
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
      return serviceUnavailable(
        body: 'Eventstore unavailable: $e',
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  S onDelete(Map<String, dynamic> data) => throw UnimplementedError('Update not implemented');

  /// Report error to Sentry and
  /// return 500 with message as body
  Response toServerError(Object error, StackTrace stackTrace) => serverError(
        request,
        error,
        stackTrace,
        logger: logger,
      );

  /// Wait for given rule result from stream of results
  Future<Response> withResponseWaitForRuleResult<E extends Event>(
    Response response, {
    bool fail = true,
    Future<bool> Function(Response response) test,
    int count = 1,
    List<int> statusCodes = const [
      HttpStatus.ok,
      HttpStatus.created,
      HttpStatus.noContent,
    ],
    Duration timeout = const Duration(
      milliseconds: PolicyUtils.defaultTimeout,
    ),
  }) async {
    final isOK = statusCodes.contains(response.statusCode);
    if (isOK && (test == null || await test(response))) {
      try {
        await PolicyUtils.waitForRuleResult<E>(
          repository,
          count: count,
          fail: fail,
          timeout: timeout,
        );
      } catch (e, stackTrace) {
        return toServerError(
          {'error': e},
          stackTrace,
        );
      }
    }
    return response;
  }

  /// Wait for given rule result from stream of results
  Future<Response> withResponseWaitForRuleResults(
    Response response, {
    @required Map<Type, int> expected,
    bool fail = true,
    bool Function(Response response) test,
    List<int> statusCodes = const [
      HttpStatus.ok,
      HttpStatus.created,
      HttpStatus.noContent,
    ],
    Duration timeout = const Duration(
      milliseconds: PolicyUtils.defaultTimeout,
    ),
  }) async {
    if (statusCodes.contains(response.statusCode) && (test == null || test(response))) {
      try {
        await PolicyUtils.waitForRuleResults(
          repository,
          fail: fail,
          logger: logger,
          timeout: timeout,
          expected: expected,
        );
      } catch (e, stackTrace) {
        return toServerError(
          {'error': e},
          stackTrace,
        );
      }
    }
    return response;
  }

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
        summary = operation.pathVariables.isEmpty ? 'Get all ${_toName()}s' : 'Get ${_toName()}';
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

  String _toName() => aggregateType.toDelimiterCase(' ');

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    var desc = '${documentOperationSummary(context, operation)}. ';
    switch (operation.method) {
      case 'POST':
        desc += 'The field [uuid] MUST BE unique for each $aggregateType. Use a '
            '[universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).';
        break;
      case 'PATCH':
        desc += 'Only fields in request are applied to $aggregateType. Other values remain unchanged.';
        break;
    }
    return desc;
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          context.schema['$aggregateType'],
          description: 'New $aggregateType Request',
          required: true,
        );
        break;
      case 'PATCH':
        return APIRequestBody.schema(
          context.schema['$aggregateType'],
          description: 'Update $aggregateType Request. Only fields in request are updated.',
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
        if (operation.pathVariables.isEmpty) {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response.',
              documentAggregatePageResponse(context, type: '$aggregateType'),
            )
          });
        } else {
          responses.addAll({
            '200': APIResponse.schema(
              'Successful response',
              documentAggregateResponse(context, type: '$aggregateType'),
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
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'GET':
        if (operation.pathVariables.isEmpty) {
          return [
            APIParameter.query('offset')..description = 'Start with ${_toName()} number equal to offset. Default is 0.',
            APIParameter.query('limit')..description = 'Maximum number of ${_toName()} to fetch. Default is 20.',
          ];
        }
        break;
    }
    return super.documentOperationParameters(context, operation);
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    documentSchemaObjects(context).forEach((name, object) {
      if (object.title?.isNotEmpty == false) {
        object.title = '$name';
      }
      if (object.description?.isNotEmpty == false) {
        object.description = '$name schema';
      }
      if (object.title == '$aggregateType' && object.required?.contains(repository.uuidFieldName) == false) {
        if (!object.properties.containsKey(repository.uuidFieldName)) {
          throw UnimplementedError("Property '${repository.uuidFieldName}' is required for aggregates");
        }
        object.required = ['uuid', ...object.required];
      }
      context.schema.register(name, object);
    });
  }

  Map<String, APISchemaObject> documentSchemaObjects(APIDocumentContext context) => {
        '$aggregateType': documentAggregateRoot(context),
      }
        ..addAll(documentEntities(context))
        ..addAll(documentValues(context));

  APISchemaObject documentAggregateRoot(APIDocumentContext context);

  Map<String, APISchemaObject> documentEntities(APIDocumentContext context) => {};
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {};
}
