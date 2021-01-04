import 'dart:io';

import 'package:meta/meta.dart';

import 'package:sarsys_http_core/sarsys_http_core.dart';

import 'mixins.dart';

/// A basic ResourceController for aggregate list requests:
///
/// * [R] - [Command] executed by [foreign] repository
/// * [S] - [AggregateRoot] type managed by [foreign] repository
/// * [T] - [Command] type executed by [primary] repository
/// * [U] - [AggregateRoot] type managed by [primary] repository
///
abstract class AggregateListController<R extends Command, S extends AggregateRoot, T extends Command,
    U extends AggregateRoot> extends AggregateLookupController<R, S> with RequestValidatorMixin {
  AggregateListController(
    String field,
    this.primary,
    Repository<R, S> foreign,
    this.validation, {
    String tag,
    this.readOnly = const [],
  }) : super(field, primary, foreign, tag: tag);

  @override
  final List<String> readOnly;

  @override
  final JsonValidation validation;

  @override
  final Repository<T, U> primary;

  //////////////////////////////////
  // Aggregate Operations
  //////////////////////////////////

  /// Add @Operation.post('uuid') to activate
  Future<Response> create(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: '$primaryType $uuid not found');
      }
      final fuuid = data[foreign.uuidFieldName] as String;
      await doCreate(
        fuuid,
        validate('${typeOf<S>()}', data)..addAll(toParentRef(uuid)),
      );
      await doCreated(primary.get(uuid), fuuid);
      return Response.created('${toLocation(request)}/$fuuid');
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
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
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
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

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doCreate(String fuuid, Map<String, dynamic> data) async {
    return await foreign.execute(
      onCreate(fuuid, data),
    );
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doCreated(U aggregate, String fuuid) async {
    return await primary.execute(
      onCreated(aggregate, fuuid),
    );
  }

  /// Add @Operation('PATCH', 'uuid') to activate
  Future<Response> add(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: '$primaryType $uuid not found');
      }
      final fuuids = toFieldList(data);
      final notFound = fuuids.where(
        (fuuid) => !foreign.contains(fuuid),
      );
      if (notFound.isNotEmpty) {
        return Response.notFound(
          body: '${foreignType}s not found: $notFound',
        );
      }
      final trx = primary.getTransaction(uuid);
      for (var fuuid in fuuids) {
        // Get updated parent aggregate
        await doAdd(primary.get(uuid), fuuid);
        await doAdded(primary.get(uuid), fuuid);
      }
      await trx.push();
      return Response.noContent();
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
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
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
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
      if (primary.inTransaction(uuid)) {
        primary.rollback(uuid);
      }
    }
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doAdd(U aggregate, String fuuid) async {
    return await primary.execute(onAdd(aggregate, fuuid));
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doAdded(U aggregate, String fuuid) async {
    return await foreign.execute(onAdded(aggregate, fuuid));
  }

  /// Add @Operation.put('uuid') to activate
  Future<Response> replace(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: '$primaryType $uuid not found');
      }
      final fuuids = toFieldList(data);
      final notFound = fuuids.where((fuuid) => !foreign.contains(fuuid));
      if (notFound.isNotEmpty) {
        return Response.notFound(body: '${foreignType}s not found: $notFound');
      }
      final trx = primary.getTransaction(uuid);
      for (var fuuid in fuuids) {
        // Get updated parent aggregate
        await doReplace(primary.get(uuid), fuuid);
        await doReplaced(primary.get(uuid), fuuid);
      }
      await trx.push();
      return Response.noContent();
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
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
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
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
      if (primary.inTransaction(uuid)) {
        primary.rollback(uuid);
      }
    }
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doReplace(U aggregate, String fuuid) async {
    return await primary.execute(onReplace(aggregate, fuuid));
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doReplaced(U aggregate, String fuuid) async {
    return await foreign.execute(onReplaced(aggregate, fuuid));
  }

  /// Add @Operation.delete('uuid') to activate
  Future<Response> remove(
    String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: '$primaryType $uuid not found');
      }
      final fuuids = toFieldList(data);
      final notFound = fuuids.where((fuuid) => !foreign.contains(fuuid));
      if (notFound.isNotEmpty) {
        return Response.notFound(body: '${foreignType}s not found: $notFound');
      }
      final trx = primary.getTransaction(uuid);
      for (var fuuid in fuuids) {
        // Get updated parent aggregate
        await doRemove(primary.get(uuid), fuuid);
        await doRemoved(primary.get(uuid), fuuid);
      }
      await trx.push();
      return Response.noContent();
    } on AggregateExists catch (e) {
      return conflict(
        ConflictType.exists,
        e.message,
      );
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
    } on AggregateNotFound catch (e) {
      return Response.notFound(body: e.message);
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
      if (primary.inTransaction(uuid)) {
        primary.rollback(uuid);
      }
    }
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doRemove(U aggregate, String fuuid) async {
    return await primary.execute(onRemove(aggregate, fuuid));
  }

  @visibleForOverriding
  Future<Iterable<DomainEvent>> doRemoved(U aggregate, String fuuid) async {
    return await foreign.execute(onRemoved(aggregate, fuuid));
  }

  Iterable<String> toFieldList(Map<String, dynamic> data) {
    final list = data.elementAt(field);
    if (list is Iterable && list.first is String) {
      return List<String>.from(list);
    }
    throw InvalidOperation('Field $field is not a list of strings');
  }

  Map<String, dynamic> toParentRef(String uuid) => {
        '$primaryType'.toLowerCase(): {
          '${primary.uuidFieldName}': uuid,
        },
      };

  Map<String, dynamic> toForeignRef(U aggregate, String fuuid) => {'uuid': fuuid}..addAll(toParentRef(
      aggregate?.uuid,
    ));

  Map<String, dynamic> toForeignNullRef(String fuuid) => {
        'uuid': fuuid,
        'unit': toParentRef(
          null,
        )
      };

  R onCreate(String uuid, Map<String, dynamic> data) {
    throw UnimplementedError('onCreate is not implemented');
  }

  T onCreated(U aggregate, String fuuid) {
    throw UnimplementedError('onCreated is not implemented');
  }

  T onAdd(U aggregate, String fuuid) {
    throw UnimplementedError('onAdd is not implemented');
  }

  R onAdded(U aggregate, String fuuid) {
    throw UnimplementedError('onAdded is not implemented');
  }

  T onReplace(U aggregate, String fuuid) {
    throw UnimplementedError('onReplace is not implemented');
  }

  R onReplaced(U aggregate, String fuuid) {
    throw UnimplementedError('onReplaced is not implemented');
  }

  T onRemove(U aggregate, String fuuid) {
    throw UnimplementedError('onRemove is not implemented');
  }

  R onRemoved(U aggregate, String fuuid) {
    throw UnimplementedError('onRemoved is not implemented');
  }

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return 'Create ${toName()} and add uuid to $field in $primaryType';
      case 'PUT':
        return 'Replace ${toName()} fuuids in $field in $primaryType';
      case 'PATCH':
        return 'Add ${toName()} fuuids to $field in $primaryType';
      case 'DELETE':
        return 'Remove ${toName()} fuuids from $field in $primaryType';
    }
    return super.documentOperationSummary(context, operation);
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        return '${documentOperationSummary(context, operation)}. Ids MUST BE unique for each ${toName()}. '
            'Use a [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).';
    }
    return super.documentOperationSummary(context, operation);
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
    switch (operation.method) {
      case 'POST':
        responses.addAll({
          '201': context.responses.getObject('201'),
          '400': context.responses.getObject('400'),
          '409': context.responses.getObject('409'),
        });
        break;
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        responses.addAll({
          '200': context.responses.getObject('201'),
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
      case 'POST':
        return [
          APIParameter.path('uuid')
            ..description = '$primaryType uuid'
            ..isRequired = true,
        ];
    }
    return super.documentOperationParameters(context, operation);
  }

  @override
  APIRequestBody documentOperationRequestBody(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case 'POST':
        return APIRequestBody.schema(
          context.schema['$aggregateType'],
          description: 'New $aggregateType',
          required: true,
        );
        break;
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        return APIRequestBody.schema(
          context.schema['AggregateList'],
          description: 'List of Aggregate Root fuuids',
          required: true,
        );
        break;
    }
    return super.documentOperationRequestBody(context, operation);
  }
}
