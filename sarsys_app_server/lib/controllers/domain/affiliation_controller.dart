import 'package:collection_x/collection_x.dart';
import 'package:sarsys_domain/sarsys_domain.dart' hide Operation;
import 'package:sarsys_app_server/sarsys_app_server.dart';

/// A ResourceController that handles
/// [/api/affiliations](http://localhost/api/client.html#/Affiliations) requests
class AffiliationController extends AggregateController<AffiliationCommand, Affiliation> {
  AffiliationController(
    this.persons,
    AffiliationRepository affiliations,
    JsonValidation validation,
  ) : super(
          affiliations,
          validation: validation,
          tag: 'Affiliations',
        );

  final PersonRepository persons;

  @override
  @Operation.get()
  Future<Response> getAll({
    @Bind.query('uuids') String uuids,
    @Bind.query('filter') String filter,
    @Bind.query('expand') String expand,
    @Bind.query('limit') int limit = 20,
    @Bind.query('offset') int offset = 0,
    @Bind.query('deleted') bool deleted = false,
  }) async {
    try {
      final shouldMerge = _shouldMerge(expand);
      final shouldFilter = filter?.isNotEmpty == true;

      // Get aggregates
      final aggregates = repository.aggregates
          .where((a) => isEmptyOrNull(uuids) || uuids.contains(a.uuid))
          .where((a) => deleted || !a.isDeleted);

      // Apply filter
      final matches = aggregates.where((a) => !shouldFilter || _match(merge(a), filter));

      // Get actual page
      final page = matches.toPage(
        offset: offset,
        limit: limit,
      );

      return Response.ok(
        toDataPaged(
          matches.length,
          offset,
          limit,
          page.map(shouldMerge ? merge : toAggregateData),
        ),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  static const keys = [
    'org',
    'div',
    'dep',
    'uuid',
    'data',
    'type',
    'fname',
    'lname',
    'email',
    'phone',
    'status',
    'person',
  ];

  bool _match(Map<String, dynamic> a, String filter) {
    final patterns = filter.toLowerCase().split(' ');
    final searchable = _toSearchable(a, keys).toLowerCase();
    return patterns.any(searchable.contains);
  }

  String _toSearchable(dynamic data, [List<String> keys = const []]) {
    if (data is List) {
      return data.map((value) => _toSearchable(value, keys)).join(' ');
    } else if (data is Map) {
      return data.keys
          .where((key) => keys.isEmpty || keys.contains(key))
          .map((key) => _toSearchable(data[key], keys))
          .join(' ');
    }
    return "$data";
  }

  bool _shouldMerge(String expand) {
    if (expand != null) {
      if (expand.toLowerCase() == 'person') {
        return true;
      }
      if (expand.isNotEmpty) {
        throw "Invalid query parameter 'expand' values: $expand, expected any of: person";
      }
    }
    return false;
  }

  /// Merge [Affiliation] with [Person]
  Map<String, dynamic> merge(Affiliation aggregate) {
    final entry = toAggregateData(aggregate);
    final affiliation = entry.elementAt<Map<String, dynamic>>('data');
    final puuid = affiliation.elementAt<String>('person/uuid');
    entry.update('data', (value) => _mergePerson(puuid, affiliation));
    return entry;
  }

  Map<String, dynamic> _mergePerson(String puuid, Map<String, dynamic> affiliation) {
    if (puuid != null) {
      final person = persons.get(puuid, createNew: false);
      if (person != null) {
        return Map.from(affiliation)..addAll({'person': person.data});
      }
    }
    return affiliation;
  }

  @override
  @Operation.get('uuid')
  Future<Response> getByUuid(
    @Bind.path('uuid') String uuid, {
    @Bind.query('expand') String expand,
  }) async {
    try {
      if (!await exists(uuid)) {
        return Response.notFound(body: "$aggregateType $uuid not found");
      }
      final aggregate = repository.get(uuid);
      return Response.ok(
        _shouldMerge(expand) ? merge(aggregate) : toAggregateData(aggregate),
      );
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  @override
  @Operation.post()
  Future<Response> create(@Bind.body() Map<String, dynamic> data) async {
    // Validate
    try {
      final affiliation = validate<Map<String, dynamic>>(schemaName, data);
      final person = affiliation.mapAt<String, dynamic>('person');

      // Is user authorized?
      if (isUser(person) || isEditor()) {
        final puuid = person.elementAt<String>('uuid');

        // Does person exists?
        if (await exists(puuid, repo: persons)) {
          final events = await persons.execute(
            UpdatePersonInformation(person),
            context: request.toContext(logger),
          );

          final response = await _createIfUnique(
            affiliation,
            puuid,
          );

          // If events are empty, person was not updated
          if (events.isEmpty || response.statusCode >= 400) {
            return response;
          }

          return _ok(
            affiliation.elementAt<String>('uuid'),
            puuid,
          );
        }

        // Look for existing user?
        final existing = _findUser(
          person.elementAt('userId'),
        );

        // Onboard person allowed?
        if (existing == null) {
          await persons.execute(
            CreatePerson(person),
            context: request.toContext(logger),
          );

          return _createIfUnique(
            affiliation,
            puuid,
          );
        }

        final response = await _createIfUnique(
          affiliation,
          // Replace person with existing
          existing.elementAt<String>('uuid'),
        );
        if (response.statusCode >= 400) {
          return response;
        }

        return _ok(
          affiliation.elementAt<String>('uuid'),
          existing.uuid,
        );
      }
      return Response.unauthorized();
    } on UUIDIsNull {
      return Response.badRequest(body: "Field [uuid] in $aggregateType is required");
    } on SchemaException catch (e) {
      return Response.badRequest(body: e.message);
    } on SocketException catch (e) {
      return serviceUnavailable(body: "Eventstore unavailable: $e");
    } on AggregateExists catch (e) {
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
    } on InvalidOperation catch (e) {
      return Response.badRequest(body: e.message);
    } on Exception catch (e, stackTrace) {
      return toServerError(e, stackTrace);
    }
  }

  bool isEditor() => AllowedScopes.isSuperUser(request.authorization);

  Response _ok(String auuid, String puuid) {
    final affiliation = repository.get(auuid);
    return okAggregate(
      affiliation,
      data: Map.from(affiliation.data)
        ..addAll({
          'person': persons.get(puuid).data,
        }),
    );
  }

  Person _findUser(userId) {
    return userId != null
        ? persons.aggregates.firstWhere(
            (person) => person.data.elementAt('userId') == userId,
            orElse: () => null,
          )
        : null;
  }

  Future<Response> _createIfUnique(Map<String, dynamic> affiliation, String puuid) {
    // TODO: Look for duplicates

    return super.create(affiliation
      ..addAll({
        'person': {'uuid': puuid}
      }));
  }

  @override
  @Operation('PATCH', 'uuid')
  Future<Response> update(
    @Bind.path('uuid') String uuid,
    @Bind.body() Map<String, dynamic> data,
  ) {
    return super.update(uuid, data);
  }

  @override
  @Operation('DELETE', 'uuid')
  Future<Response> delete(
    @Bind.path('uuid') String uuid, {
    @Bind.body() Map<String, dynamic> data,
  }) {
    return super.delete(uuid, data: data);
  }

  @override
  AffiliationCommand onCreate(Map<String, dynamic> data) => CreateAffiliation(data);

  @override
  Iterable<AffiliationCommand> onUpdate(Map<String, dynamic> data) => [
        UpdateAffiliation(data),
      ];

  @override
  AffiliationCommand onDelete(Map<String, dynamic> data) => DeleteAffiliation(data);

  //////////////////////////////////
  // Documentation
  //////////////////////////////////

  @override
  List<APIParameter> documentOperationParameters(APIDocumentContext context, Operation operation) {
    final parameters = super.documentOperationParameters(context, operation);
    switch (operation.method) {
      case "GET":
        parameters
          ..add(
            APIParameter.query('filter')..description = "Match values against given filter",
          )
          ..add(
            APIParameter.query('uuids')
              ..description = "Only get aggregates in list of given comma-separated uuids. "
                  "If filter is given, it is only applied on aggregates matching any uuids",
          )
          ..add(
            APIParameter.query('expand')
              ..description = "Expand response with information from references. Legal values are: 'person'",
          );
        break;
    }
    return parameters;
  }

  @override
  APISchemaObject documentAggregateRoot(APIDocumentContext context) => documentAffiliation(
        context,
      );

  @override
  Map<String, APISchemaObject> documentValues(APIDocumentContext context) => {
        "AffiliationType": documentAffiliationType(),
        "AffiliationStandbyStatus": documentAffiliationType(),
      };

  static APISchemaObject documentAffiliation(
    APIDocumentContext context, {
    APISchemaObject person,
  }) {
    return APISchemaObject.object({
      "uuid": context.schema['UUID']..description = "Unique Affiliation id",
      "person": person ?? APISchemaObject()
        ..anyOf = [
          context.schema['Person'],
          documentAggregateRef(
            context,
            defaultType: 'Person',
            description: "Person reference for PII lookup",
          ),
        ],
      "org": documentAggregateRef(
        context,
        readOnly: false,
        defaultType: 'Organisation',
        description: "Organisation which personnel is affiliated with",
      ),
      "div": documentAggregateRef(
        context,
        readOnly: false,
        defaultType: 'Division',
        description: "Division which personnel is affiliated with",
      ),
      "dep": documentAggregateRef(
        context,
        readOnly: false,
        description: "Department which personnel is affiliated with",
        defaultType: 'Department',
      ),
      "type": documentAffiliationType(),
      "status": documentAffiliationStandbyStatus(),
      "active": APISchemaObject.boolean()..description = "Affiliation status flag"
    })
      ..title = "Affiliation"
      ..description = "Affiliation information"
      ..required = [
        'uuid',
      ]
      ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed;
  }

  static APISchemaObject documentAffiliationType() => APISchemaObject.string()
    ..description = "Affiliation type"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "member"
    ..enumerated = [
      'member',
      'employee',
      'external',
      'volunteer',
    ];

  static APISchemaObject documentAffiliationStandbyStatus() => APISchemaObject.string()
    ..description = "Affiliate standby status"
    ..additionalPropertyPolicy = APISchemaAdditionalPropertyPolicy.disallowed
    ..defaultValue = "available"
    ..enumerated = [
      'available',
      'short_notice',
      'unavailable',
    ];
}
