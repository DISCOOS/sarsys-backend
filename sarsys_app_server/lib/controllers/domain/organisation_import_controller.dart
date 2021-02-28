import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// Implement controller for field `divisions` in [Organisation]
class OrganisationImportController
    extends AggregateListController<DivisionCommand, Division, OrganisationCommand, Organisation> {
  OrganisationImportController(
    OrganisationRepository organisations,
    DivisionRepository divisions,
    DepartmentRepository departments,
    JsonValidation validation,
  )   : divisionController = DivisionController(divisions, validation),
        departmentController = DepartmentController(departments, validation),
        departmentListController = DivisionDepartmentController(divisions, departments, validation),
        super(
          'divisions',
          organisations,
          divisions,
          validation,
          tag: 'Organisations',
        );

  final DivisionController divisionController;
  final DepartmentController departmentController;
  final DivisionDepartmentController departmentListController;

  @Operation('PATCH', 'uuid')
  Future<Response> import(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) async {
    Transaction trx;
    try {
      if (!await exists(primary, uuid)) {
        return Response.notFound(body: "$primaryType $uuid not found");
      }
      final list = _validate(uuid, data);
      final responses = <Response>[];
      trx = primary.beginTransaction(
        uuid,
        context: request.toContext(logger),
      );
      for (var div in list) {
        responses.addAll(
          await _importDivision(uuid, div),
        );
      }
      await trx.push();
      final failures = responses.where(isError);
      return failures.isEmpty
          ? okAggregate(primary.get(uuid))
          : toServerError(
              {
                'errors': failures
                    .map(
                      (response) => '${response.statusCode}: ${response.body}',
                    )
                    .toList()
              },
              StackTrace.current,
            );
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
        body: "Repository command queue was unable to process ${e.request.tag}",
      );
    } on AggregateCordoned catch (e) {
      return locked(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    } finally {
      if (trx?.isOpen == true) {
        trx.rollback(this);
      }
    }
  }

  List<Map<String, dynamic>> _validate(String uuid, Map<String, dynamic> data) {
    final tree = validate<Map<String, dynamic>>("${aggregateType}Tree", data);
    final org = primary.get(uuid, createNew: false);
    final divs = List<Map<String, dynamic>>.from(tree.elementAt('divisions') ?? []);

    // Check for name conflicts with divisions in given organisation
    final conflicts = _verifyUniqueNames<Division>(
            List<String>.from(
              org.data.elementAt('divisions') ?? [],
            ).where(divisionController.repository.contains).map(divisionController.repository.get),
            divisionController.repository,
            divs)
        .toList();
    conflicts.addAll(
      // Check name conflicts with departments in given department
      divs.fold<List<String>>(
          <String>[],
          (conflicts, div) => conflicts
            ..addAll(_verifyUniqueNames<Department>(
              List<String>.from(
                divisionController.repository
                        .get(div.elementAt<String>('uuid'), createNew: false)
                        ?.data
                        ?.elementAt('departments') ??
                    [],
              ).where(departmentController.repository.contains).map(departmentController.repository.get),
              departmentController.repository,
              List<Map<String, dynamic>>.from(div.elementAt('departments') ?? []),
            ))),
    );

    // Check for wrong parents
    final wrongParents = _verifyBelongsTo<Division>(uuid, 'organisation', divisionController.repository, divs).toList();
    wrongParents.addAll(divs.fold(
      <String>[],
      (errors, div) => List.from(errors)
        ..addAll(_verifyBelongsTo<Department>(
            div.elementAt('uuid') as String,
            'division',
            departmentController.repository,
            List.from(
              div.elementAt('departments') ?? [],
            ))),
    ));

    if (conflicts.isNotEmpty || wrongParents.isNotEmpty) {
      throw ConflictNotReconcilable.empty([
        if (conflicts.isNotEmpty) 'Aggregates with same name found: ${conflicts.toList()}',
        if (wrongParents.isNotEmpty) 'Aggregates belongs to wrong parents: ${wrongParents.toList()}',
      ].join(', '));
    }
    return divs;
  }

  Iterable<String> _verifyUniqueNames<T extends AggregateRoot>(
    Iterable<T> existing,
    Repository<Command, T> repository,
    List<Map<String, dynamic>> aggregates,
  ) {
    final conflicts = aggregates
        .where((aggregate) => !repository.contains(aggregate.elementAt('uuid')))
        .where((aggregate) => _findNameConflict<T>(existing, aggregate).isNotEmpty)
        .map(
          (aggregate) => '${typeOf<T>()} ${aggregate.elementAt('name')} have same name as: '
              '${_findNameConflict<T>(existing, aggregate).map((found) => found.uuid).toList()}',
        )
        .toList();
    // Check that names in import is unique
    final duplicates = <String, int>{};
    aggregates.forEach(
      (aggregate) => duplicates.update(aggregate.elementAt('name'), (count) => ++count, ifAbsent: () => 1),
    );
    duplicates.removeWhere((_, count) => count < 2);
    conflicts.addAll(
      duplicates.keys.map((name) => 'Found ${duplicates[name]} ${typeOf<T>()}(s) with $name'),
    );

    return conflicts;
  }

  Iterable<String> _verifyBelongsTo<T extends AggregateRoot>(
    String uuid,
    String type,
    Repository<Command, T> repository,
    List<Map<String, dynamic>> aggregates,
  ) =>
      aggregates
          .where((aggregate) => repository.contains(aggregate.elementAt('uuid')))
          .map((aggregate) => repository.get(aggregate.elementAt('uuid')))
          .where((aggregate) => aggregate.data.elementAt('$type/uuid') != uuid)
          .map(
            (aggregate) => '${typeOf<T>()} ${aggregate.data.elementAt('uuid')} '
                'belongs to $type: ${aggregate.data.elementAt('$type/uuid')}',
          );

  Iterable<T> _findNameConflict<T extends AggregateRoot>(
    Iterable<T> aggregates,
    Map<String, dynamic> div,
  ) =>
      _find<T>(aggregates, 'name', div);

  Iterable<T> _find<T extends AggregateRoot>(Iterable<T> items, String field, Map<String, dynamic> match) {
    return items
        .where((aggregate) => aggregate.uuid != match.elementAt('uuid'))
        .where((aggregate) => aggregate.data.elementAt(field) == match.elementAt(field));
  }

  Future<Iterable<Response>> _importDivision(String uuid, Map<String, dynamic> div) async {
    final responses = <Response>[];
    final deps = div.elementAt('departments') ?? [];
    final duuid = div.elementAt('uuid') as String ?? Uuid().v4();
    Transaction trx;
    try {
      trx = foreign.beginTransaction(
        duuid,
        context: request.toContext(logger),
      );
      if (!foreign.contains(duuid)) {
        responses.add(await super.create(
          uuid,
          div
            ..addAll({
              'uuid': duuid ?? Uuid().v4(),
              'active': div.elementAt('active') ?? true,
            })
            ..removeWhere((key, _) => key == 'departments'),
        ));
      } else {
        responses.add(
          await _forward(divisionController).update(
            duuid,
            div..remove('departments'),
          ),
        );
      }
      responses.addAll(
        await _importDeps(duuid, deps),
      );
      await trx.push();
      return responses;
    } finally {
      if (trx?.isOpen == true) {
        trx.rollback(this);
      }
    }
  }

  Future<Iterable<Response>> _importDeps(String uuid, dynamic deps) async {
    final responses = <Response>[];
    if (deps is List) {
      for (var dep in List<Map<String, dynamic>>.from(deps)) {
        responses.add(
          await _importDep(dep, uuid),
        );
      }
    }
    return responses;
  }

  Future<Response> _importDep(Map<String, dynamic> dep, String uuid) {
    final duuid = dep.elementAt('uuid') as String ?? Uuid().v4();
    if (!departmentController.repository.contains(duuid)) {
      return _forward(departmentListController).create(
          uuid,
          dep
            ..addAll({
              'uuid': duuid,
              'active': dep.elementAt('active') ?? true,
            }));
    }
    return _forward(departmentController).update(duuid, dep);
  }

  T _forward<T extends ResourceController>(T controller) {
    controller.request = request;
    return controller;
  }

  @override
  CreateDivision onCreate(String uuid, Map<String, dynamic> data) => CreateDivision(data);

  @override
  AddDivisionToOrganisation onCreated(Organisation aggregate, String fuuid) => AddDivisionToOrganisation(
        aggregate,
        fuuid,
      );

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  String documentOperationSummary(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "PATCH":
        return "Update ${toName()} tree";
      default:
        throw UnimplementedError('Method ${operation.method} not supported');
    }
  }

  @override
  String documentOperationDescription(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "PATCH":
        return "${documentOperationSummary(context, operation)}. If no aggregate uuid is supplied it is assumed "
            "that given aggregate does not exist and an uuid will be generated before creating it."
            "An '409 Conflict' is returned if an aggregate in the import exist with same name as the "
            "imported aggregate within the same organisation tree. If an aggregate uuid is given, it is assumed "
            "to exist and will be updated if found. An '404 Not found' is returned if not found. If given aggregate "
            "belongs to another organisation an '400 Bad request' is returned."
            "Use a [universally unique identifier](https://en.wikipedia.org/wiki/Universally_unique_identifier).";
      default:
        throw UnimplementedError('Method ${operation.method} not supported');
    }
  }

  @override
  Map<String, APIResponse> documentOperationResponses(APIDocumentContext context, Operation operation) {
    final responses = super.documentOperationResponses(context, operation);
    switch (operation.method) {
      case "PATCH":
        responses.addAll({
          "204": context.responses.getObject("201"),
          "400": context.responses.getObject("400"),
          "409": context.responses.getObject("409"),
        });
        break;
    }
    return responses;
  }

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    switch (operation.method) {
      case "PATCH":
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
      case "PATCH":
        return APIRequestBody.schema(
          context.schema["${aggregateType}Tree"],
          description: "Import $aggregateType tree",
          required: true,
        );
        break;
      default:
        throw UnimplementedError('Method ${operation.method} not supported');
    }
  }

  @override
  void documentComponents(APIDocumentContext context) {
    super.documentComponents(context);
    context.schema.register(
      '${foreignType}Tree',
      APISchemaObject.object({
        'divisions': APISchemaObject.array(ofSchema: context.schema['${primaryType}Tree']),
      })
        ..description = "List of ${primaryType}Tree",
    );
    context.schema.register(
        '${primaryType}Tree',
        APISchemaObject.object({
          "name": APISchemaObject.string()..description = "Division name",
          "suffix": APISchemaObject.string()..description = "FleetMap number suffix",
          "active": APISchemaObject.boolean()..description = "Division status",
          'departments': APISchemaObject.array(
            ofSchema: APISchemaObject.object({
              "uuid": context.schema['UUID']..description = "Unique department id",
              "name": APISchemaObject.string()..description = "Department name",
              "suffix": APISchemaObject.string()..description = "FleetMap number suffix",
              "active": APISchemaObject.boolean()..description = "Department status",
            })
              ..description = "Department Schema (aggregate root)"
              ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed,
          )..description = "List of ${departmentController.aggregateType}",
        }));
  }
}
